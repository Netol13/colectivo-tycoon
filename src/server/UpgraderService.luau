--!strict
-- UpgraderService.luau  (ServerScriptService.UpgraderService)
-- Mejoras de pista por línea: pisás el pad "Mejorar" de una línea y su arco
-- sube de nivel, multiplicando el valor de TODOS sus colectivos. El nivel se
-- guarda en data.Upgrades[lineId]. Server-authoritative.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Net = require(ReplicatedStorage:WaitForChild("Net"))
local Stats = require(ServerScriptService:WaitForChild("Stats"))
local StepPad = require(ServerScriptService:WaitForChild("StepPad"))
local MissionService = require(ServerScriptService:WaitForChild("MissionService"))

local UpgraderService = {}

-- Multiplicador de valor de una línea según su nivel de mejora.
function UpgraderService.multiplier(data: any, lineId: string): number
	local nivel = (data.Upgrades and data.Upgrades[lineId]) or 0
	if nivel <= 0 then
		return 1
	end
	local cfg = Config.Upgraders.Niveles[nivel]
	return cfg and cfg.Mult or 1
end

local function refreshArco(refs: any, nivel: number)
	if refs.arco and nivel > 0 then
		refs.arco.Material = Enum.Material.Neon -- el arco brilla al estar mejorado
	end
end

function UpgraderService.bind(player: Player, plot: any, plata: IntValue, data: any)
	data.Upgrades = data.Upgrades or {}
	for _, lineaCfg in ipairs(Config.Lineas) do
		local refs = plot.lineas[lineaCfg.Id]
		if not refs or not refs.upgradePad then
			continue
		end
		refreshArco(refs, data.Upgrades[lineaCfg.Id] or 0)

		StepPad.onStep(refs.upgradePad, player, function()
			local nivel = data.Upgrades[lineaCfg.Id] or 0
			local siguiente = Config.Upgraders.Niveles[nivel + 1]
			if not siguiente then
				return -- ya está en el nivel máximo
			end
			if plata.Value < siguiente.Precio then
				Net.event("Notify"):FireClient(player, "not_enough", "error")
				return
			end
			plata.Value -= siguiente.Precio
			data.Cash = plata.Value
			data.Upgrades[lineaCfg.Id] = nivel + 1
			refreshArco(refs, nivel + 1)
			Net.event("PurchaseFX"):FireClient(player, refs.upgradePad.Position, lineaCfg.Color)
			Net.event("Notify"):FireClient(player, "upgraded", "good", lineaCfg.Nombre)
			Stats.update(player)
			MissionService.report(player, "upgrade", 1)
		end)
	end
end

return UpgraderService
