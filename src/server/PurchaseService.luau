--!strict
-- PurchaseService.luau  (ServerScriptService.PurchaseService)
-- Maneja las compras de lineas nuevas. El cliente solo "pide" comprar
-- (clickea el boton); el SERVIDOR valida que le alcance la plata y que no la
-- tenga ya comprada antes de descontar y activarla.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local TycoonService = require(script.Parent:WaitForChild("TycoonService"))

local PurchaseService = {}

function PurchaseService.bind(player: Player, plot: any, plata: IntValue, data: any)
	for _, lineaCfg in ipairs(Config.Lineas) do
		local refs = plot.lineas[lineaCfg.Id]
		if not refs or lineaCfg.Precio <= 0 then
			continue
		end

		-- Si ya la tenia comprada de antes (cargada del guardado), no hay boton.
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

		local cd = refs.boton:FindFirstChildOfClass("ClickDetector")
		if not cd then
			continue
		end

		cd.MouseClick:Connect(function(clicker: Player)
			if clicker ~= player then
				return -- solo el dueno del plot puede comprar aca
			end
			if data.Owned[lineaCfg.Id] then
				return
			end
			if plata.Value < lineaCfg.Precio then
				return -- no le alcanza
			end

			plata.Value -= lineaCfg.Precio
			data.Owned[lineaCfg.Id] = true

			if refs.boton then
				refs.boton:Destroy()
				refs.boton = nil
			end

			TycoonService.activateLinea(plot, lineaCfg)
		end)
	end
end

return PurchaseService
