--!strict
-- HelperService.luau  (ServerScriptService.HelperService)
-- El "Cobrador automático": si lo compraste, cobra la terminal solo cada tantos
-- segundos, así no tenés que estar reclamando a mano (y no se siente muerto si
-- te quedás AFK). Es server-authoritative; el NPC es solo decorativo.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Net = require(ReplicatedStorage:WaitForChild("Net"))
local PlayerState = require(ServerScriptService:WaitForChild("PlayerState"))

local HelperService = {}

-- Arranca el loop de auto-cobro si el jugador tiene el ayudante. Idempotente.
function HelperService.setup(player: Player, plot: any, data: any)
	if not data.Owned["Ayudante"] then
		return
	end
	if plot.helperRunning then
		return
	end
	plot.helperRunning = true

	task.spawn(function()
		while plot.model.Parent ~= nil and data.Owned["Ayudante"] do
			task.wait(Config.Ayudante.IntervaloSeg)
			local state = PlayerState.get(player)
			if state and state.pending and state.pending > 0 then
				local amt = state.pending
				state.pending = 0
				plot.pendingLabel.Text = "$0"
				state.plata.Value += amt
				data.Cash = state.plata.Value
				Net.event("CollectFX"):FireClient(player, plot.collector.Position, amt, false)
			end
		end
		plot.helperRunning = false
	end)
end

return HelperService
