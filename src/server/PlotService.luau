--!strict
-- PlotService.luau  (ServerScriptService.PlotService)
-- Centraliza armar y RE-armar el plot de un jugador. El rebirth ("Renovar
-- Flota") usa rebuild() para destruir el plot y volver a empezar con el
-- multiplicador nuevo, sin duplicar la lógica de construcción.

local ServerScriptService = game:GetService("ServerScriptService")
local PlotBuilder = require(ServerScriptService:WaitForChild("PlotBuilder"))
local TycoonService = require(ServerScriptService:WaitForChild("TycoonService"))
local PurchaseService = require(ServerScriptService:WaitForChild("PurchaseService"))
local PlayerState = require(ServerScriptService:WaitForChild("PlayerState"))
local Stats = require(ServerScriptService:WaitForChild("Stats"))

local PlotService = {}

local function teleport(player: Player, plot: any)
	local char = player.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		char:PivotTo(plot.spawn.CFrame * CFrame.new(0, 4, 0))
	end
end

-- Construye el plot y arranca el tycoon + las compras. state = { slot, plata, data }.
function PlotService.setup(player: Player, state: any): any
	local plot = PlotBuilder.build(player, state.slot.cf)
	state.plot = plot
	player.RespawnLocation = plot.spawn
	TycoonService.start(player, plot, state.plata, state.data)
	PurchaseService.bind(player, plot, state.plata, state.data)
	teleport(player, plot)
	Stats.update(player)
	return plot
end

-- Destruye y vuelve a construir el plot desde cero (rebirth).
function PlotService.rebuild(player: Player)
	local state = PlayerState.get(player)
	if not state or not state.plot then
		return
	end
	TycoonService.stop(state.plot)
	state.plot.model:Destroy()
	PlotService.setup(player, state)
end

return PlotService
