--!strict
-- ServerMain.server.luau  (ServerScriptService.ServerMain)
-- Punto de entrada del servidor. Es el unico Script "de verdad" (los demas son
-- ModuleScripts que este requiere). Arma todo cuando entra un jugador y limpia
-- cuando se va.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local PlotBuilder = require(ServerScriptService:WaitForChild("PlotBuilder"))
local TycoonService = require(ServerScriptService:WaitForChild("TycoonService"))
local PurchaseService = require(ServerScriptService:WaitForChild("PurchaseService"))
local DataManager = require(ServerScriptService:WaitForChild("DataManager"))

-- Lugares fijos donde se construyen los plots, separados 100 studs.
local PLOT_SLOTS = {}
for i = 0, 7 do
	table.insert(PLOT_SLOTS, { cf = CFrame.new(i * 100, 5, 0), taken = false })
end

local plotsByPlayer: { [Player]: any } = {}

local function getFreeSlot()
	for _, slot in ipairs(PLOT_SLOTS) do
		if not slot.taken then
			slot.taken = true
			return slot
		end
	end
	return nil
end

local function teleportToPlot(player: Player, plot: any)
	local char = player.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		char:PivotTo(plot.spawn.CFrame * CFrame.new(0, 4, 0))
	end
end

local function onPlayerAdded(player: Player)
	local slot = getFreeSlot()
	if not slot then
		player:Kick("El servidor esta lleno, proba mas tarde.")
		return
	end

	-- leaderstats (lo que se ve arriba a la derecha).
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local plata = Instance.new("IntValue")
	plata.Name = Config.Currency.Name
	plata.Parent = leaderstats
	leaderstats.Parent = player

	-- Datos del jugador.
	local data = DataManager.load(player)
	plata.Value = data.Cash

	-- Construir su plot.
	local plot = PlotBuilder.build(player, slot.cf)
	plot.slot = slot
	plotsByPlayer[player] = plot

	-- Que aparezca (y reaparezca) en su propio plot.
	player.RespawnLocation = plot.spawn

	-- Arrancar el loop y las compras.
	TycoonService.start(player, plot, plata, data)
	PurchaseService.bind(player, plot, plata, data)

	-- Llevar al personaje a su plot.
	player.CharacterAdded:Connect(function()
		task.wait(0.2)
		teleportToPlot(player, plot)
	end)
	if player.Character then
		teleportToPlot(player, plot)
	end
end

local function onPlayerRemoving(player: Player)
	local plot = plotsByPlayer[player]
	if plot then
		TycoonService.stop(plot)
		if plot.slot then
			plot.slot.taken = false
		end
		plot.model:Destroy()
		plotsByPlayer[player] = nil
	end
	DataManager.release(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Por si algun jugador ya estaba dentro cuando arranco el script.
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

-- Al cerrarse el servidor, guardar a todos.
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		DataManager.release(player)
	end
end)
