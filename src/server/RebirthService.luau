--!strict
-- RebirthService.luau  (ServerScriptService.RebirthService)
-- "Renovar Flota" (rebirth): cuando el jugador tiene todas las líneas y junta
-- la plata mínima, puede reiniciar su empresa a cambio de un multiplicador
-- permanente. Es el loop infinito que evita que el juego "se termine".
-- TODO se valida en el servidor.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Net = require(ReplicatedStorage:WaitForChild("Net"))
local Format = require(ReplicatedStorage:WaitForChild("Format"))
local PlayerState = require(ServerScriptService:WaitForChild("PlayerState"))
local PlotService = require(ServerScriptService:WaitForChild("PlotService"))
local Stats = require(ServerScriptService:WaitForChild("Stats"))

local RebirthService = {}

local function tieneTodasLasLineas(data: any): boolean
	for _, linea in ipairs(Config.Lineas) do
		if not data.Owned[linea.Id] then
			return false
		end
	end
	return true
end

function RebirthService.start()
	Net.event("RequestRebirth").OnServerEvent:Connect(function(player: Player)
		local state = PlayerState.get(player)
		if not state then
			return
		end
		local data = state.data

		if Config.Rebirth.RequiereTodasLasLineas and not tieneTodasLasLineas(data) then
			Net.event("Notify"):FireClient(player, "rebirth_locked", "error")
			return
		end
		if state.plata.Value < Config.Rebirth.PlataMinima then
			local faltan = Config.Rebirth.PlataMinima - state.plata.Value
			Net.event("Notify")
				:FireClient(player, "rebirth_need_cash", "error", Format.money(faltan))
			return
		end

		-- Ejecutar la renovación.
		data.Renovaciones = (data.Renovaciones or 0) + 1
		data.Owned = { Linea1 = true }
		state.plata.Value = 0
		data.Cash = 0

		PlotService.rebuild(player)
		Stats.update(player)
		Net.event("RebirthFX"):FireClient(player, data.Renovaciones + 1) -- nivel = renovaciones + 1
	end)
end

return RebirthService
