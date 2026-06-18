--!strict
-- PurchaseService.luau  (ServerScriptService.PurchaseService)
-- Maneja la compra de líneas. El cliente solo "pide" (click en el botón); el
-- SERVIDOR valida que le alcance y que no la tenga ya, descuenta y la activa.
-- Al comprar, dispara el confeti + sonido y actualiza la meta del jugador.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Net = require(ReplicatedStorage:WaitForChild("Net"))
local TycoonService = require(script.Parent:WaitForChild("TycoonService"))
local Stats = require(script.Parent:WaitForChild("Stats"))
local StepPad = require(script.Parent:WaitForChild("StepPad"))

local PurchaseService = {}

function PurchaseService.bind(player: Player, plot: any, plata: IntValue, data: any)
	for _, lineaCfg in ipairs(Config.Lineas) do
		local refs = plot.lineas[lineaCfg.Id]
		if not refs or lineaCfg.Precio <= 0 then
			continue
		end

		-- Ya comprada de antes: no hay botón.
		if data.Owned[lineaCfg.Id] then
			if refs.boton then
				refs.boton:Destroy()
				refs.boton = nil
			end
			continue
		end

		if not refs.boton then
			continue
		end

		StepPad.onStep(refs.boton, player, function()
			if data.Owned[lineaCfg.Id] then
				return
			end
			if plata.Value < lineaCfg.Precio then
				Net.event("Notify"):FireClient(player, "not_enough", "error")
				return
			end

			plata.Value -= lineaCfg.Precio
			data.Cash = plata.Value
			data.Owned[lineaCfg.Id] = true

			local pos = refs.boton and refs.boton.Position or plot.collector.Position
			if refs.boton then
				refs.boton:Destroy()
				refs.boton = nil
			end

			TycoonService.activateLinea(player, plot, lineaCfg, data)
			Net.event("PurchaseFX"):FireClient(player, pos, lineaCfg.Color)
			Net.event("Notify"):FireClient(player, "bought", "good", lineaCfg.Nombre)
			Stats.update(player)
		end)
	end
end

return PurchaseService
