--!strict
-- ServerMain.server.luau  (ServerScriptService.ServerMain)
-- Punto de entrada del servidor. Arma todo cuando entra un jugador (datos,
-- plot, offline, daily) y limpia cuando se va. También arranca los servicios
-- globales (evento Hora Pico, rebirth, daily) y refresca las stats.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local DataManager = require(ServerScriptService:WaitForChild("DataManager"))
local PlayerState = require(ServerScriptService:WaitForChild("PlayerState"))
local PlotService = require(ServerScriptService:WaitForChild("PlotService"))
local TycoonService = require(ServerScriptService:WaitForChild("TycoonService"))
local Stats = require(ServerScriptService:WaitForChild("Stats"))
local OfflineService = require(ServerScriptService:WaitForChild("OfflineService"))
local EventService = require(ServerScriptService:WaitForChild("EventService"))
local RebirthService = require(ServerScriptService:WaitForChild("RebirthService"))
local DailyService = require(ServerScriptService:WaitForChild("DailyService"))

-- Lugares fijos donde se construyen los plots (separados para que no se toquen).
local PLOT_SLOTS = {}
for i = 0, 7 do
	table.insert(PLOT_SLOTS, { cf = CFrame.new(i * 140, 5, 0), taken = false })
end

local function getFreeSlot()
	for _, slot in ipairs(PLOT_SLOTS) do
		if not slot.taken then
			slot.taken = true
			return slot
		end
	end
	return nil
end

local function teleport(player: Player)
	local state = PlayerState.get(player)
	if not state or not state.plot then
		return
	end
	local char = player.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		char:PivotTo(state.plot.spawn.CFrame * CFrame.new(0, 4, 0))
	end
end

local function onPlayerAdded(player: Player)
	local slot = getFreeSlot()
	if not slot then
		player:Kick("El servidor está lleno, probá más tarde.")
		return
	end

	-- leaderstats + plata.
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local plata = Instance.new("IntValue")
	plata.Name = Config.Currency.Name
	plata.Parent = leaderstats
	leaderstats.Parent = player

	-- Datos guardados.
	local data = DataManager.load(player)
	plata.Value = data.Cash

	-- Ganancias mientras estuvo offline (se guardan en un atributo para mostrar).
	local earned = OfflineService.apply(data, plata)
	player:SetAttribute("OfflineEarned", earned)

	-- Estado central del jugador.
	local state = { slot = slot, plata = plata, data = data, plot = nil }
	PlayerState.set(player, state)

	-- Construir el plot y arrancar todo.
	PlotService.setup(player, state)
	DailyService.push(player)

	-- Llevar al personaje a su plot al spawnear.
	player.CharacterAdded:Connect(function()
		task.wait(0.2)
		teleport(player)
	end)
	if player.Character then
		teleport(player)
	end
end

local function onPlayerRemoving(player: Player)
	local state = PlayerState.get(player)
	if state then
		if state.plot then
			TycoonService.stop(state.plot)
			state.plot.model:Destroy()
		end
		if state.slot then
			state.slot.taken = false
		end
	end
	DataManager.release(player)
	PlayerState.clear(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

-- Servicios globales.
EventService.start()
RebirthService.start()
DailyService.start()

-- Refrescar stats (plata/min, meta, si puede renovar) cada segundo.
task.spawn(function()
	while true do
		task.wait(1)
		for player in pairs(PlayerState.all()) do
			Stats.update(player)
		end
	end
end)

-- Al cerrarse el servidor, guardar a todos.
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		DataManager.release(player)
	end
end)
