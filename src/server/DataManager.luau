--!strict
-- DataManager.luau  (ServerScriptService.DataManager)
-- Maneja los datos del jugador (plata + lineas compradas) y los GUARDA con
-- ProfileStore (el estandar 2026: session-locking + autosave, asi no se
-- duplican ni se pierden datos).
--
-- Como funciona en cada contexto:
--  * En Roblox Studio: usa el modo "Mock" de ProfileStore. Guarda en memoria
--    de Studio, asi pueden probar el guardado (comprar -> Stop -> Play y sigue)
--    SIN tener que activar "Studio Access to API Services" ni publicar nada.
--  * En el juego publicado: usa ProfileStore real -> persiste en la nube.
--  * Si por lo que sea no se puede abrir el perfil: cae a datos temporales en
--    memoria para que el juego no se rompa (avisa por warn).
--
-- Interfaz estable (la usa ServerMain): load / get / save / release.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProfileStore = require(script.Parent:WaitForChild("ProfileStore"))
local Config = require(ReplicatedStorage:WaitForChild("Config"))

local DataManager = {}

-- Estructura por defecto de los datos de un jugador nuevo.
local PROFILE_TEMPLATE = {
	Cash = 0,
	Owned = { Linea1 = true }, -- la Linea 1 viene gratis
}

-- Pone esto en false (y activa "Studio Access to API Services" en
-- Game Settings -> Security) si queres probar el GUARDADO REAL dentro de Studio.
-- Con true el juego anda sin configurar nada, pero en Studio el guardado se
-- reinicia en cada Play. En el juego PUBLICADO siempre guarda de verdad: este
-- flag solo afecta a Studio.
local USE_MOCK_IN_STUDIO = true

local profileStore = ProfileStore.New("PlayerData", PROFILE_TEMPLATE)
if RunService:IsStudio() and USE_MOCK_IN_STUDIO then
	profileStore = profileStore.Mock
end

local profiles: { [Player]: any } = {} -- perfiles activos de ProfileStore
local fallback: { [Player]: any } = {} -- datos temporales si ProfileStore falla

local function defaultData()
	return { Cash = 0, Owned = { Linea1 = true } }
end

-- Carga (o crea) los datos del jugador. SIEMPRE devuelve una tabla de datos.
function DataManager.load(player: Player)
	local profile
	local ok, result = pcall(function()
		return profileStore:StartSessionAsync("Player_" .. player.UserId, {
			Cancel = function()
				return player.Parent ~= Players
			end,
		})
	end)
	if ok then
		profile = result
	end

	if profile then
		profile:AddUserId(player.UserId) -- para cumplimiento GDPR
		profile:Reconcile() -- completa claves nuevas del template

		profile.OnSessionEnd:Connect(function()
			profiles[player] = nil
			player:Kick("Se cerro tu sesion de datos. Volve a entrar.")
		end)

		if player.Parent == Players then
			profiles[player] = profile
			return profile.Data
		else
			-- El jugador se fue mientras cargaba: cerrar y no dejar lock colgado.
			profile:EndSession()
			return defaultData()
		end
	end

	-- No se pudo abrir el perfil: datos temporales (no persisten).
	warn("[DataManager] Datos temporales para " .. player.Name .. " (ProfileStore no disponible).")
	fallback[player] = defaultData()
	return fallback[player]
end

-- Devuelve los datos ya cargados del jugador.
function DataManager.get(player: Player)
	local profile = profiles[player]
	if profile then
		return profile.Data
	end
	return fallback[player]
end

-- Sincroniza la plata desde el leaderstats hacia los datos a guardar.
function DataManager.save(player: Player)
	local data = DataManager.get(player)
	if not data then
		return
	end
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local plata = ls:FindFirstChild(Config.Currency.Name)
		if plata then
			data.Cash = plata.Value
		end
	end
	-- ProfileStore guarda solo por autosave y al EndSession; no hace falta forzar.
end

-- Guarda y cierra la sesion del jugador (al salir).
function DataManager.release(player: Player)
	DataManager.save(player)
	local profile = profiles[player]
	if profile then
		profile:EndSession()
		profiles[player] = nil
	end
	fallback[player] = nil
end

return DataManager
