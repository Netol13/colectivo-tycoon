--!strict
-- DailyService.luau  (ServerScriptService.DailyService)
-- Recompensa diaria con racha de 7 días. Volver cada día da cada vez más; si
-- faltás un día, la racha vuelve a 1. Engancha por el "no quiero perderla".
-- Compara días en UTC (os.time() / 86400) para no depender de la zona horaria.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Net = require(ReplicatedStorage:WaitForChild("Net"))
local PlayerState = require(ServerScriptService:WaitForChild("PlayerState"))

local DailyService = {}

local MAX_DIA = #Config.Daily.Recompensas

local function diaUTC(): number
	return math.floor(os.time() / 86400)
end

-- Qué día de racha le tocaría reclamar hoy.
local function proximoDia(data: any, hoy: number): number
	if data.DailyLastDay == hoy then
		return data.DailyStreak -- ya reclamó hoy
	elseif data.DailyLastDay == hoy - 1 then
		return math.min((data.DailyStreak or 0) + 1, MAX_DIA) -- racha sigue
	else
		return 1 -- perdió la racha (o primera vez)
	end
end

-- Publica el estado diario como atributos (el cliente los lee cuando quiera;
-- así no se pierde el aviso si todavía no terminó de cargar).
function DailyService.push(player: Player)
	local state = PlayerState.get(player)
	if not state then
		return
	end
	local hoy = diaUTC()
	player:SetAttribute("DailyCanClaim", state.data.DailyLastDay ~= hoy)
	player:SetAttribute("DailyDay", proximoDia(state.data, hoy))
end

function DailyService.start()
	Net.event("RequestDaily").OnServerEvent:Connect(function(player: Player)
		local state = PlayerState.get(player)
		if not state then
			return
		end
		local data = state.data
		local hoy = diaUTC()
		if data.DailyLastDay == hoy then
			return -- ya reclamó hoy
		end

		data.DailyStreak = proximoDia(data, hoy)
		data.DailyLastDay = hoy

		local reward = Config.Daily.Recompensas[data.DailyStreak]
		if reward and reward.plata then
			state.plata.Value += reward.plata
			data.Cash = state.plata.Value
		end

		Net.event("Notify"):FireClient(player, "daily_claimed", "good")
		DailyService.push(player)
	end)
end

return DailyService
