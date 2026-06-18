--!strict
-- Net.luau  (ReplicatedStorage.Net)
-- Crea y centraliza los RemoteEvents (la "red" entre servidor y cliente).
-- El servidor los crea al arrancar; el cliente los espera. Asi nadie hardcodea
-- nombres sueltos de remotes por todos lados.
--
-- Uso server:  Net.event("CollectFX"):FireClient(player, ...)
-- Uso cliente: Net.event("CollectFX").OnClientEvent:Connect(...)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Net = {}

-- Todos los canales del juego. Si agregás uno nuevo, ponelo acá.
local EVENTS = {
	"CollectFX", -- server -> client: cobraste plata (para numerito flotante + sonido)
	"PurchaseFX", -- server -> client: compraste algo (confeti + sonido)
	"Notify", -- server -> client: mensaje en pantalla (texto + tipo)
	"RebirthFX", -- server -> client: celebracion de renovacion
	"RequestRebirth", -- client -> server: quiero renovar la flota
	"DailyState", -- server -> client: estado de la recompensa diaria
	"RequestDaily", -- client -> server: reclamar recompensa diaria
	"OfflineEarnings", -- server -> client: ganancias mientras no estabas
	"EventState", -- server -> client: evento activo (hora pico, etc.)
	"LaserToggle", -- server -> client: se prendieron/apagaron los láseres (FX/sonido)
}

local folder: Folder

if RunService:IsServer() then
	folder = Instance.new("Folder")
	folder.Name = "Remotes"
	for _, name in ipairs(EVENTS) do
		local re = Instance.new("RemoteEvent")
		re.Name = name
		re.Parent = folder
	end
	folder.Parent = ReplicatedStorage
else
	folder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
end

function Net.event(name: string): RemoteEvent
	return folder:WaitForChild(name) :: RemoteEvent
end

return Net
