--!strict
-- UnlockService.luau  (ServerScriptService.UnlockService)
-- Desbloqueos por progreso: a más renovaciones (rebirth), el personaje camina
-- más rápido y salta más alto. La velocidad es server-authoritative y se RE-
-- APLICA en cada respawn (si no, Roblox la reinicia a 16).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local PlayerState = require(ServerScriptService:WaitForChild("PlayerState"))

local UnlockService = {}

local function walkSpeedFor(renov: number): number
	local u = Config.Unlocks
	return math.min(u.VelocidadBase + renov * u.VelocidadPorRenov, u.VelocidadTope)
end

-- Aplica velocidad/salto al personaje según las renovaciones del jugador.
function UnlockService.applyTo(player: Player, char: Model)
	local hum = char:WaitForChild("Humanoid", 5) :: Humanoid?
	if not hum then
		return
	end
	local state = PlayerState.get(player)
	local renov = (state and state.data.Renovaciones) or 0
	hum.WalkSpeed = walkSpeedFor(renov)
	if renov >= 1 then
		hum.UseJumpPower = true
		hum.JumpPower = 60
	end
end

-- Re-aplica al personaje vivo (cuando cambia el progreso, ej. tras rebirth).
function UnlockService.refresh(player: Player)
	local char = player.Character
	if char then
		UnlockService.applyTo(player, char)
	end
end

return UnlockService
