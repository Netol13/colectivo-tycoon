--!strict
-- TycoonService.luau  (ServerScriptService.TycoonService)
-- El corazón del loop: genera pasajes en cada línea activa y los cobra en la
-- terminal. TODO corre en el servidor (server-authoritative): el valor, el
-- multiplicador de rebirth y el del evento los decide el servidor.
-- Cuando cobra, avisa al cliente para que muestre el numerito y el sonido.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Net = require(ReplicatedStorage:WaitForChild("Net"))
local EventService = require(script.Parent:WaitForChild("EventService"))

local TycoonService = {}

local function multiplier(data: any): number
	return 1 + (data.Renovaciones or 0) * Config.Rebirth.BonusPorRenovacion
end

-- Genera un "pasaje" (pelotita) en lo alto de la rampa de una línea.
local function generarPasaje(plot: any, refs: any, lineaCfg: any)
	local pasaje = Instance.new("Part")
	pasaje.Shape = Enum.PartType.Ball
	pasaje.Size = Vector3.new(1.6, 1.6, 1.6)
	-- Durante "Hora Pico" los pasajes son dorados (señal visual del evento).
	pasaje.Color = EventService.isActive() and Config.Evento.TinteColor or lineaCfg.Color
	pasaje.Material = Enum.Material.Neon
	pasaje.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.1, 0.3)
	pasaje:SetAttribute("Value", lineaCfg.ValorPasaje)
	pasaje.CFrame = refs.dropper.CFrame * CFrame.new(0, 3, 4)
	pasaje.Parent = plot.pasajes
	Debris:AddItem(pasaje, 25)
end

function TycoonService.activateLinea(plot: any, lineaCfg: any)
	local refs = plot.lineas[lineaCfg.Id]
	if not refs or refs.activa then
		return
	end
	refs.activa = true
	task.spawn(function()
		while refs.activa and plot.model.Parent ~= nil do
			generarPasaje(plot, refs, lineaCfg)
			task.wait(lineaCfg.Intervalo)
		end
	end)
end

function TycoonService.start(player: Player, plot: any, plata: IntValue, data: any)
	plot.collector.Touched:Connect(function(hit: BasePart)
		local value = hit:GetAttribute("Value")
		if not value then
			return
		end
		if hit:GetAttribute("Collected") then
			return
		end
		hit:SetAttribute("Collected", true)
		local pos = hit.Position -- guardar ANTES de destruir
		hit:Destroy()

		-- El servidor decide cuánto vale: base × rebirth × evento.
		local final = math.floor(value * multiplier(data) * EventService.getMultiplier())
		plata.Value += final
		data.Cash = plata.Value

		-- Avisar al cliente dueño para el numerito flotante + sonido.
		Net.event("CollectFX"):FireClient(player, pos, final, EventService.isActive())
	end)

	for _, lineaCfg in ipairs(Config.Lineas) do
		if data.Owned[lineaCfg.Id] then
			TycoonService.activateLinea(plot, lineaCfg)
		end
	end
end

function TycoonService.stop(plot: any)
	for _, refs in pairs(plot.lineas) do
		refs.activa = false
	end
end

return TycoonService
