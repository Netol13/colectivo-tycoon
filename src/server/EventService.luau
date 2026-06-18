--!strict
-- EventService.luau  (ServerScriptService.EventService)
-- El evento rotativo "Hora Pico": cada cierto rato, multiplica los ingresos de
-- TODOS por una ventana corta. Crea FOMO ("entrá ahora que vale x3"). Los
-- pasajes se tiñen de dorado durante el evento (lo maneja TycoonService).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Net = require(ReplicatedStorage:WaitForChild("Net"))

local EventService = {}

local active = false

function EventService.isActive(): boolean
	return active
end

function EventService.getMultiplier(): number
	return active and Config.Evento.Multiplicador or 1
end

function EventService.start()
	task.spawn(function()
		while true do
			task.wait(Config.Evento.CadaSeg)
			active = true
			Net.event("EventState"):FireAllClients(true, Config.Evento.Multiplicador)
			task.wait(Config.Evento.DuracionSeg)
			active = false
			Net.event("EventState"):FireAllClients(false, 1)
		end
	end)
end

return EventService
