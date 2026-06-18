--!strict
-- TycoonService.luau  (ServerScriptService.TycoonService)
-- Genera los minicolectivos de cada línea y los hace viajar por la ruta hasta
-- la terminal con TweenService (anclados, sin física: nunca se vuelcan ni
-- laguean). Al llegar, la plata NO se cobra sola: se ACUMULA en la terminal y
-- el jugador la cobra a mano (CollectService). Todo server-authoritative.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Format = require(ReplicatedStorage:WaitForChild("Format"))
local EventService = require(script.Parent:WaitForChild("EventService"))
local BusModel = require(script.Parent:WaitForChild("BusModel"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local UpgraderService = require(script.Parent:WaitForChild("UpgraderService"))

local TycoonService = {}

local function multiplier(data: any): number
	return 1 + (data.Renovaciones or 0) * Config.Rebirth.BonusPorRenovacion
end

-- Llega un colectivo a la terminal: acumula su valor en "pending" (cobro manual).
local function onArrive(player: Player, plot: any, valor: number, data: any)
	local state = PlayerState.get(player)
	if not state then
		return
	end
	local final = math.floor(valor * multiplier(data) * EventService.getMultiplier())
	state.pending += final
	plot.pendingLabel.Text = Format.money(state.pending)
end

local function spawnBus(player: Player, plot: any, refs: any, lineaCfg: any, data: any)
	if refs.live >= Config.Bus.MaxEnTransito then
		return -- ya hay demasiados en la ruta; esperamos (cuida el celular)
	end
	refs.live += 1

	local color = EventService.isActive() and Config.Evento.TinteColor or lineaCfg.Color
	local valorBus =
		math.floor(lineaCfg.ValorPasaje * UpgraderService.multiplier(data, lineaCfg.Id))
	local bus = BusModel.build(color, valorBus, data.Renovaciones)
	bus:PivotTo(refs.busStart)
	bus.Parent = plot.pasajes

	-- Movemos el bus tweeneando un CFrameValue (TweenService no anima Models).
	local cfv = Instance.new("CFrameValue")
	cfv.Value = refs.busStart
	cfv.Changed:Connect(function(v)
		if bus.Parent then -- por si el plot se reconstruyó (rebirth) y ya se destruyó
			bus:PivotTo(v)
		end
	end)

	local travel = refs.routeLen / Config.Bus.Velocidad
	local tween = TweenService:Create(
		cfv,
		TweenInfo.new(travel, Enum.EasingStyle.Linear),
		{ Value = refs.busEnd }
	)
	tween.Completed:Connect(function()
		refs.live -= 1
		cfv:Destroy()
		if plot.model.Parent ~= nil then
			onArrive(player, plot, valorBus, data)
		end
		bus:Destroy()
	end)
	tween:Play()
end

function TycoonService.activateLinea(player: Player, plot: any, lineaCfg: any, data: any)
	local refs = plot.lineas[lineaCfg.Id]
	if not refs or refs.activa then
		return
	end
	refs.activa = true
	task.spawn(function()
		while refs.activa and plot.model.Parent ~= nil do
			spawnBus(player, plot, refs, lineaCfg, data)
			task.wait(lineaCfg.Intervalo)
		end
	end)
end

function TycoonService.start(player: Player, plot: any, data: any)
	for _, lineaCfg in ipairs(Config.Lineas) do
		if data.Owned[lineaCfg.Id] then
			TycoonService.activateLinea(player, plot, lineaCfg, data)
		end
	end
end

function TycoonService.stop(plot: any)
	for _, refs in pairs(plot.lineas) do
		refs.activa = false
	end
end

return TycoonService
