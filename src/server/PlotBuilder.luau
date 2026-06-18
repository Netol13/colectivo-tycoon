--!strict
-- PlotBuilder.luau  (ServerScriptService.PlotBuilder)
-- Construye el plot de un jugador ENTERAMENTE por codigo (no se dibuja a mano
-- en Studio). Asi todo el juego vive en git y, cuando tu amigo hace `git pull`,
-- ve exactamente el mismo plot que vos.
--
-- Devuelve una tabla con referencias a las piezas para que el resto de los
-- servicios (TycoonService, PurchaseService) las usen.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))

local PlotBuilder = {}

-- Helper: crea un Part anclado con las props que le pasemos.
local function part(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		(p :: any)[k] = v
	end
	return p
end

-- Carriles (X relativo al centro del plot) para hasta 3 lineas.
local LANE_X = { -14, 0, 14 }

function PlotBuilder.build(player: Player, origin: CFrame)
	local model = Instance.new("Model")
	model.Name = "Plot_" .. player.Name

	-- Piso del plot (es tambien el "suelo" donde camina el jugador).
	local base = part({
		Size = Vector3.new(46, 1, 72),
		Color = Color3.fromRGB(58, 58, 64),
		Material = Enum.Material.SmoothPlastic,
	})
	base.CFrame = origin * CFrame.new(0, -0.5, 0)
	base.Parent = model

	-- Punto de aparicion del jugador, en SU plot.
	local spawn = Instance.new("SpawnLocation")
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame = origin * CFrame.new(0, 0.5, -16)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Color = Color3.fromRGB(235, 235, 235)
	spawn.Parent = model

	-- Terminal / caja: pad ancho al frente que junta los pasajes.
	local collector = part({
		Size = Vector3.new(46, 5, 4),
		Color = Color3.fromRGB(255, 200, 40),
		Material = Enum.Material.Neon,
		Transparency = 0.2,
	})
	collector.CFrame = origin * CFrame.new(0, 2.5, 30)
	collector.Parent = model

	-- Carpeta donde caen los pasajes generados (asi quedan ordenados).
	local pasajes = Instance.new("Folder")
	pasajes.Name = "Pasajes"
	pasajes.Parent = model

	local lineas: { [string]: any } = {}

	for i, lineaCfg in ipairs(Config.Lineas) do
		local x = LANE_X[i] or (-14 + (i - 1) * 14)

		-- Dropper: la "estacion" desde donde salen los pasajes.
		local dropper = part({
			Size = Vector3.new(6, 6, 6),
			Color = lineaCfg.Color,
			Material = Enum.Material.Metal,
		})
		dropper.CFrame = origin * CFrame.new(x, 9, -30)
		dropper.Parent = model

		-- Rampa (la "ruta"): baja desde el dropper hasta la terminal.
		-- Los pasajes son pelotitas que ruedan por gravedad.
		local hi = (origin * CFrame.new(x, 8, -27)).Position
		local lo = (origin * CFrame.new(x, 2, 26)).Position
		local mid = hi:Lerp(lo, 0.5)
		local len = (lo - hi).Magnitude
		local rampCF = CFrame.lookAt(mid, lo)

		local floor = part({
			Size = Vector3.new(8, 1, len),
			Color = Color3.fromRGB(88, 88, 94),
		})
		floor.CFrame = rampCF
		floor.Parent = model

		-- Paredes laterales para que las pelotitas no se caigan del carril.
		local wallL =
			part({ Size = Vector3.new(0.6, 3, len), Color = Color3.fromRGB(120, 120, 126) })
		wallL.CFrame = rampCF * CFrame.new(-4, 1.5, 0)
		wallL.Parent = model

		local wallR =
			part({ Size = Vector3.new(0.6, 3, len), Color = Color3.fromRGB(120, 120, 126) })
		wallR.CFrame = rampCF * CFrame.new(4, 1.5, 0)
		wallR.Parent = model

		local refs: { [string]: any } = { dropper = dropper, activa = false }

		-- Boton de compra (solo para lineas que cuestan plata).
		if lineaCfg.Precio > 0 then
			local boton = part({
				Size = Vector3.new(6, 3, 6),
				Color = Color3.fromRGB(28, 28, 34),
				Material = Enum.Material.Neon,
			})
			boton.CFrame = origin * CFrame.new(x, 1.5, -38)
			boton.Parent = model

			local cd = Instance.new("ClickDetector")
			cd.MaxActivationDistance = 36
			cd.Parent = boton

			local bb = Instance.new("BillboardGui")
			bb.Size = UDim2.fromScale(7, 2.5)
			bb.StudsOffset = Vector3.new(0, 3.5, 0)
			bb.AlwaysOnTop = true
			bb.Parent = boton

			local tl = Instance.new("TextLabel")
			tl.Size = UDim2.fromScale(1, 1)
			tl.BackgroundTransparency = 1
			tl.TextColor3 = Color3.fromRGB(255, 255, 255)
			tl.TextStrokeTransparency = 0.3
			tl.TextScaled = true
			tl.Font = Enum.Font.GothamBold
			tl.Text = string.format("Comprar %s\n$%d", lineaCfg.Nombre, lineaCfg.Precio)
			tl.Parent = bb

			refs.boton = boton
		end

		lineas[lineaCfg.Id] = refs
	end

	model.Parent = workspace

	return {
		model = model,
		spawn = spawn,
		collector = collector,
		pasajes = pasajes,
		lineas = lineas,
		origin = origin,
	}
end

return PlotBuilder
