--!strict
-- MissionService.luau  (ServerScriptService.MissionService)
-- Misiones diarias con recompensa en plata. El progreso se reporta por eventos
-- (cobrar, comprar línea, mejorar) y se reinicia cada día (UTC). Reclamás la
-- recompensa desde el panel. Server-authoritative.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Net = require(ReplicatedStorage:WaitForChild("Net"))
local PlayerState = require(ServerScriptService:WaitForChild("PlayerState"))
local Stats = require(ServerScriptService:WaitForChild("Stats"))

local MissionService = {}

local function diaUTC(): number
	return math.floor(os.time() / 86400)
end

-- Reinicia las misiones si cambió el día.
local function ensureDay(data: any)
	if not data.Misiones then
		data.Misiones = { Progreso = {}, Reclamadas = {}, DiaDaily = 0 }
	end
	local hoy = diaUTC()
	if data.Misiones.DiaDaily ~= hoy then
		data.Misiones.DiaDaily = hoy
		data.Misiones.Progreso = {}
		data.Misiones.Reclamadas = {}
	end
end

-- Manda el estado de las misiones al cliente (para el panel).
function MissionService.push(player: Player)
	local state = PlayerState.get(player)
	if not state then
		return
	end
	ensureDay(state.data)
	local list = {}
	for _, m in ipairs(Config.Misiones) do
		local prog = state.data.Misiones.Progreso[m.Id] or 0
		table.insert(list, {
			id = m.Id,
			nombre = m.Nombre,
			objetivo = m.Objetivo,
			progreso = math.min(prog, m.Objetivo),
			recompensa = m.Recompensa,
			reclamable = prog >= m.Objetivo and not state.data.Misiones.Reclamadas[m.Id],
			reclamada = state.data.Misiones.Reclamadas[m.Id] == true,
		})
	end
	Net.event("MissionState"):FireClient(player, list)
end

-- Suma progreso a las misiones del evento dado.
function MissionService.report(player: Player, evento: string, delta: number)
	local state = PlayerState.get(player)
	if not state then
		return
	end
	ensureDay(state.data)
	local changed = false
	for _, m in ipairs(Config.Misiones) do
		if m.Evento == evento then
			state.data.Misiones.Progreso[m.Id] = (state.data.Misiones.Progreso[m.Id] or 0) + delta
			changed = true
		end
	end
	if changed then
		MissionService.push(player)
	end
end

function MissionService.start()
	Net.event("ClaimMission").OnServerEvent:Connect(function(player: Player, id: string)
		local state = PlayerState.get(player)
		if not state then
			return
		end
		ensureDay(state.data)
		for _, m in ipairs(Config.Misiones) do
			if m.Id == id then
				local prog = state.data.Misiones.Progreso[m.Id] or 0
				if prog >= m.Objetivo and not state.data.Misiones.Reclamadas[m.Id] then
					state.data.Misiones.Reclamadas[m.Id] = true
					state.plata.Value += m.Recompensa
					state.data.Cash = state.plata.Value
					Net.event("Notify"):FireClient(player, "mission_done", "good")
					Stats.update(player)
					MissionService.push(player)
				end
				return
			end
		end
	end)
end

return MissionService
