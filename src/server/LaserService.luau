--!strict
-- LaserService.luau  (ServerScriptService.LaserService)
-- Prende/apaga los láseres de la puerta con el switch (ProximityPrompt). El
-- estado vive en el atributo "Locked" del plot (una sola fuente de verdad, que
-- más adelante también va a decidir si te pueden robar). Server-authoritative.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage:WaitForChild("Net"))

local LaserService = {}

-- Conecta el switch de la puerta (si ya está construida). Es idempotente:
-- se puede llamar al entrar y otra vez cuando se compra la puerta.
function LaserService.setup(player: Player, plot: any)
	local door = plot.builds and plot.builds["PuertaLaser"]
	if not door then
		return -- todavía no compró la puerta
	end
	if plot.door then
		return -- ya estaba conectado
	end
	plot.door = { on = false }
	plot.model:SetAttribute("Locked", false)

	local switch = door:FindFirstChild("LaserSwitch")
	local prompt = switch and switch:FindFirstChildWhichIsA("ProximityPrompt")
	if not prompt then
		return
	end

	prompt.Triggered:Connect(function(plr: Player)
		if plr ~= player then
			return -- solo el dueño prende/apaga sus láseres
		end
		plot.door.on = not plot.door.on
		plot.model:SetAttribute("Locked", plot.door.on)
		for _, l in ipairs(door:GetChildren()) do
			if l.Name == "Laser" then
				l.Transparency = plot.door.on and 0 or 1
				l.CanTouch = plot.door.on
			end
		end
		Net.event("LaserToggle"):FireClient(player, plot.door.on)
	end)
end

return LaserService
