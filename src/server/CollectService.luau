--!strict
-- CollectService.luau  (ServerScriptService.CollectService)
-- Cobro MANUAL: la plata se acumula en la terminal (state.pending) y el dueño
-- la cobra acercándose y apretando el prompt "Cobrar". El ProximityPrompt
-- dispara en el servidor con el Player confiable, así no hace falta un remote
-- nuevo ni se puede falsear. (Esta plata acumulada es la base del futuro robo.)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage:WaitForChild("Net"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local Stats = require(script.Parent:WaitForChild("Stats"))
local StepPad = require(script.Parent:WaitForChild("StepPad"))

local CollectService = {}

function CollectService.bind(player: Player, plot: any, plata: IntValue, data: any)
	local pad = plot.claimPad
	if not pad then
		return
	end
	-- Pisás el pad de cobro y se cobra toda la plata acumulada.
	StepPad.onStep(pad, player, function()
		local state = PlayerState.get(player)
		if not state then
			return
		end
		local amt = state.pending
		if amt <= 0 then
			return
		end
		state.pending = 0
		plot.pendingLabel.Text = "$0"
		plata.Value += amt
		data.Cash = plata.Value
		Net.event("CollectFX"):FireClient(player, plot.collector.Position, amt, false)
		Stats.update(player)
	end)
end

return CollectService
