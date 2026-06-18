--!strict
-- BuildService.luau  (ServerScriptService.BuildService)
-- Sistema de construcción tipo tycoon clásico: cada estructura tiene un pad de
-- compra; al comprarla, se "levanta" en su lugar y se guarda en Owned (igual
-- que las líneas), así se reconstruye al volver a entrar. Los pads aparecen de
-- a poco según sus requisitos (progresión). Server-authoritative.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Net = require(ReplicatedStorage:WaitForChild("Net"))
local PlotBuilder = require(ServerScriptService:WaitForChild("PlotBuilder"))
local LaserService = require(ServerScriptService:WaitForChild("LaserService"))
local HelperService = require(ServerScriptService:WaitForChild("HelperService"))
local Stats = require(ServerScriptService:WaitForChild("Stats"))
local StepPad = require(ServerScriptService:WaitForChild("StepPad"))

local BuildService = {}

-- Muestra u oculta los pads según si ya tenés su requisito.
local function refreshPads(plot: any, data: any)
	for _, buildCfg in ipairs(Config.Builds) do
		local pad = plot.buildPads[buildCfg.Id]
		if pad then
			local disponible = (not buildCfg.Requiere) or (data.Owned[buildCfg.Requiere] == true)
			pad.Transparency = disponible and 0 or 1
			local cd = pad:FindFirstChildOfClass("ClickDetector")
			if cd then
				cd.MaxActivationDistance = disponible and 40 or 0
			end
			local bb = pad:FindFirstChildOfClass("BillboardGui")
			if bb then
				bb.Enabled = disponible
			end
		end
	end
end

function BuildService.buy(player: Player, plot: any, plata: IntValue, data: any, buildCfg: any)
	if data.Owned[buildCfg.Id] then
		return
	end
	if buildCfg.Requiere and not data.Owned[buildCfg.Requiere] then
		return
	end
	if plata.Value < buildCfg.Precio then
		Net.event("Notify"):FireClient(player, "not_enough", "error")
		return
	end

	plata.Value -= buildCfg.Precio
	data.Cash = plata.Value
	data.Owned[buildCfg.Id] = true

	local pad = plot.buildPads[buildCfg.Id]
	local pos = pad and pad.Position or plot.collector.Position
	if pad then
		pad:Destroy()
		plot.buildPads[buildCfg.Id] = nil
	end

	PlotBuilder.materialize(plot, buildCfg)
	if buildCfg.Kind == "door" then
		LaserService.setup(player, plot)
	elseif buildCfg.Kind == "helper" then
		HelperService.setup(player, plot, data)
	end

	Net.event("PurchaseFX"):FireClient(player, pos, buildCfg.Color or Color3.fromRGB(80, 160, 240))
	Net.event("Notify"):FireClient(player, "bought", "good", buildCfg.Nombre)
	refreshPads(plot, data)
	Stats.update(player)
end

function BuildService.bind(player: Player, plot: any, plata: IntValue, data: any)
	for _, buildCfg in ipairs(Config.Builds) do
		if data.Owned[buildCfg.Id] then
			-- Ya comprada: materializar (al entrar o tras rebirth). Orden del array
			-- = dependencias primero, así el requisito existe antes que lo que depende.
			PlotBuilder.materialize(plot, buildCfg)
			local pad = plot.buildPads[buildCfg.Id]
			if pad then
				pad:Destroy()
				plot.buildPads[buildCfg.Id] = nil
			end
		else
			local pad = plot.buildPads[buildCfg.Id]
			if pad then
				StepPad.onStep(pad, player, function()
					BuildService.buy(player, plot, plata, data, buildCfg)
				end)
			end
		end
	end
	refreshPads(plot, data)
end

return BuildService
