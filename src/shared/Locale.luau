--!strict
-- Locale.luau  (ReplicatedStorage.Locale)
-- Textos del juego en español e inglés. El cliente detecta el idioma del
-- jugador y llama Locale.setLanguage("es"/"en"). Para agregar un texto nuevo:
-- ponelo en las DOS tablas con la misma clave.
--
-- Uso: Locale.get("buy_line", "Línea 2")  ->  "Comprar Línea 2"

local Locale = {}

type Strings = { [string]: string }

local STRINGS: { [string]: Strings } = {
	es = {
		money_per_min = "%s/min",
		goal_buy = "Meta: comprá %s",
		goal_all = "¡Todo comprado! Renová tu flota 🚌",
		goal_rebirth = "Meta: Renovar Flota (%s)",
		buy_line = "Comprar %s",
		owned = "COMPRADA",
		rebirth_button = "RENOVAR FLOTA",
		rebirth_locked = "Comprá todas las líneas primero",
		rebirth_need_cash = "Te faltan %s para renovar",
		rebirth_done = "¡EMPRESA NIVEL %d!",
		rebirth_confirm = "¿Renovar? Reiniciás tu progreso por +%d%% para siempre",
		bought = "¡Compraste %s!",
		upgraded = "¡Mejoraste %s! 🔧",
		mission_done = "¡Misión completada! 🎉",
		missions = "Misiones",
		claim = "Reclamar",
		not_enough = "No te alcanza",
		welcome_back = "Mientras no estabas, tus colectivos ganaron %s 🚌",
		daily_title = "Recompensa Diaria",
		daily_day = "Día %d",
		daily_claim = "RECLAMAR",
		daily_claimed = "¡Reclamado!",
		daily_come_back = "Volvé mañana",
		multiplier = "Multiplicador",
		renovations = "Renovaciones",
		event_rush = "¡HORA PICO! Ingresos x%d",
		settings = "Ajustes",
		music = "Música",
		sfx = "Sonidos",
		laser_on = "🔴 Láseres activados",
		laser_off = "Láseres apagados",
	},
	en = {
		money_per_min = "%s/min",
		goal_buy = "Goal: buy %s",
		goal_all = "All bought! Renew your fleet 🚌",
		goal_rebirth = "Goal: Renew Fleet (%s)",
		buy_line = "Buy %s",
		owned = "OWNED",
		rebirth_button = "RENEW FLEET",
		rebirth_locked = "Buy every line first",
		rebirth_need_cash = "You need %s to renew",
		rebirth_done = "COMPANY LEVEL %d!",
		rebirth_confirm = "Renew? You reset progress for +%d%% forever",
		bought = "You bought %s!",
		upgraded = "Upgraded %s! 🔧",
		mission_done = "Mission complete! 🎉",
		missions = "Missions",
		claim = "Claim",
		not_enough = "Not enough cash",
		welcome_back = "While you were away, your buses earned %s 🚌",
		daily_title = "Daily Reward",
		daily_day = "Day %d",
		daily_claim = "CLAIM",
		daily_claimed = "Claimed!",
		daily_come_back = "Come back tomorrow",
		multiplier = "Multiplier",
		renovations = "Renewals",
		event_rush = "RUSH HOUR! Income x%d",
		settings = "Settings",
		music = "Music",
		sfx = "SFX",
		laser_on = "🔴 Lasers ON",
		laser_off = "Lasers OFF",
	},
}

local current = "es"

function Locale.setLanguage(lang: string)
	if STRINGS[lang] then
		current = lang
	end
end

-- Detecta es/en a partir del LocaleId del jugador ("es-ar" -> "es").
function Locale.fromLocaleId(localeId: string?): string
	if localeId and string.sub(localeId, 1, 2) == "es" then
		return "es"
	end
	return "en"
end

function Locale.get(key: string, ...): string
	local tbl = STRINGS[current] or STRINGS.es
	local s = tbl[key] or STRINGS.es[key] or key
	if select("#", ...) > 0 then
		return string.format(s, ...)
	end
	return s
end

return Locale
