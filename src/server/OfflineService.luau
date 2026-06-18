--!strict
-- OfflineService.luau  (ServerScriptService.OfflineService)
-- Calcula cuánta plata "ganaron" los colectivos mientras el jugador NO estaba,
-- y se la suma al entrar ("Mientras no estabas ganaste $X"). Tira a volver cada
-- día. Tiene un tope (CapHoras) para que no sea infinito.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))

local OfflineService = {}

-- Devuelve cuánta plata se otorgó (0 si no corresponde).
function OfflineService.apply(data: any, plata: IntValue): number
	local last = data.LastOnline or 0
	if last <= 0 then
		return 0 -- primera vez que juega: no hay offline
	end

	local elapsed = os.time() - last
	if elapsed <= 60 then
		return 0 -- estuvo menos de 1 minuto afuera
	end

	local capped = math.min(elapsed, Config.Offline.CapHoras * 3600)
	local mult = 1 + (data.Renovaciones or 0) * Config.Rebirth.BonusPorRenovacion

	local perSec = 0
	for _, linea in ipairs(Config.Lineas) do
		if data.Owned[linea.Id] then
			perSec += (linea.ValorPasaje / linea.Intervalo) * mult
		end
	end

	local earned = math.floor(perSec * capped * Config.Offline.Factor)
	if earned > 0 then
		plata.Value += earned
		data.Cash = plata.Value
	end
	return earned
end

return OfflineService
