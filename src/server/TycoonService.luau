--!strict
-- TycoonService.luau  (ServerScriptService.TycoonService)
-- El corazon del loop: genera pasajes en cada linea activa y los cobra cuando
-- llegan a la terminal. TODO corre en el servidor (server-authoritative): el
-- valor de cada pasaje y la suma a la plata las decide el servidor, nunca el
-- cliente. Asi nadie puede hacerse plata infinita con un exploit.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Config = require(ReplicatedStorage:WaitForChild("Config"))

local TycoonService = {}

-- Genera un "pasaje" (pelotita) en lo alto de la rampa de una linea.
local function generarPasaje(plot: any, refs: any, lineaCfg: any)
	local pasaje = Instance.new("Part")
	pasaje.Shape = Enum.PartType.Ball
	pasaje.Size = Vector3.new(1.6, 1.6, 1.6)
	pasaje.Color = lineaCfg.Color
	pasaje.Material = Enum.Material.Neon
	-- Baja friccion = rueda solo por la rampa hasta la terminal.
	pasaje.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.1, 0.3)
	pasaje:SetAttribute("Value", lineaCfg.ValorPasaje)
	pasaje.CFrame = refs.dropper.CFrame * CFrame.new(0, 3, 4)
	pasaje.Parent = plot.pasajes
	-- Si por alguna razon no llega a la terminal, se limpia solo a los 25s.
	Debris:AddItem(pasaje, 25)
end

-- Activa una linea: arranca su loop de generacion de pasajes.
function TycoonService.activateLinea(plot: any, lineaCfg: any)
	local refs = plot.lineas[lineaCfg.Id]
	if not refs or refs.activa then
		return
	end
	refs.activa = true
	task.spawn(function()
		while refs.activa and plot.model.Parent ~= nil do
			generarPasaje(plot, refs, lineaCfg)
			task.wait(lineaCfg.Intervalo)
		end
	end)
end

-- Conecta la terminal y activa las lineas que el jugador ya tiene compradas.
function TycoonService.start(player: Player, plot: any, plata: IntValue, data: any)
	plot.collector.Touched:Connect(function(hit: BasePart)
		local value = hit:GetAttribute("Value")
		if not value then
			return -- no es un pasaje (puede ser el personaje u otra cosa)
		end
		if hit:GetAttribute("Collected") then
			return -- ya lo cobramos (Touched puede disparar varias veces)
		end
		hit:SetAttribute("Collected", true)
		hit:Destroy()
		plata.Value += value
	end)

	for _, lineaCfg in ipairs(Config.Lineas) do
		if data.Owned[lineaCfg.Id] then
			TycoonService.activateLinea(plot, lineaCfg)
		end
	end
end

-- Frena todas las lineas de un plot (cuando el jugador se va).
function TycoonService.stop(plot: any)
	for _, refs in pairs(plot.lineas) do
		refs.activa = false
	end
end

return TycoonService
