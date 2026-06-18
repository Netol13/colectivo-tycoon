--!strict
-- Stats.luau  (ServerScriptService.Stats)
-- Calcula y publica el estado visible del jugador como ATRIBUTOS en el Player
-- (PerMin, Multiplicador, la meta actual, si puede renovar). El cliente lee
-- esos atributos y arma el HUD. Centralizar esto evita que cada servicio
-- calcule la meta a su manera.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))

local Stats = {}

-- Multiplicador permanente por renovaciones (rebirth).
function Stats.multiplier(data: any): number
	return 1 + (data.Renovaciones or 0) * Config.Rebirth.BonusPorRenovacion
end

-- Recalcula todo y lo publica como atributos del Player.
function Stats.update(player: Player)
	local state = PlayerState.get(player)
	if not state then
		return
	end
	local data = state.data
	local mult = Stats.multiplier(data)

	-- Plata por minuto (ingreso teórico estando online, sin contar eventos).
	local perMin = 0
	for _, linea in ipairs(Config.Lineas) do
		if data.Owned[linea.Id] then
			perMin += (linea.ValorPasaje / linea.Intervalo) * 60 * mult
		end
	end
	player:SetAttribute("PerMin", math.floor(perMin))
	player:SetAttribute("Multiplier", mult)
	player:SetAttribute("Renovaciones", data.Renovaciones or 0)
	-- Reflejar las renovaciones en el leaderboard nativo de Roblox.
	local ls = player:FindFirstChild("leaderstats")
	local renov = ls and ls:FindFirstChild("Renov.")
	if renov then
		(renov :: IntValue).Value = data.Renovaciones or 0
	end

	-- Meta: la próxima línea a comprar, o renovar la flota si ya están todas.
	local nextLinea = nil
	for _, linea in ipairs(Config.Lineas) do
		if not data.Owned[linea.Id] then
			nextLinea = linea
			break
		end
	end

	if nextLinea then
		player:SetAttribute("GoalKind", "buy")
		player:SetAttribute("GoalName", nextLinea.Nombre)
		player:SetAttribute("GoalCost", nextLinea.Precio)
		player:SetAttribute("RebirthReady", false)
	else
		-- Todas compradas: si ya puede renovar mostramos el call-to-action ("all");
		-- si todavía junta, mostramos cuánto le falta ("rebirth").
		local ready = state.plata.Value >= Config.Rebirth.PlataMinima
		player:SetAttribute("GoalKind", ready and "all" or "rebirth")
		player:SetAttribute("GoalCost", Config.Rebirth.PlataMinima)
		player:SetAttribute("RebirthReady", ready)
	end
end

return Stats
