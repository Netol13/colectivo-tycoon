--!strict
-- PlayerState.luau  (ServerScriptService.PlayerState)
-- Registro central del estado de cada jugador en el servidor: su plot, su
-- IntValue de plata, sus datos guardados y el slot que ocupa. Los demás
-- servicios (rebirth, daily, stats) lo consultan en vez de pasarse referencias
-- por todos lados.

local PlayerState = {}

local states: { [Player]: any } = {}

function PlayerState.set(player: Player, state: any)
	states[player] = state
end

function PlayerState.get(player: Player): any
	return states[player]
end

function PlayerState.clear(player: Player)
	states[player] = nil
end

function PlayerState.all(): { [Player]: any }
	return states
end

return PlayerState
