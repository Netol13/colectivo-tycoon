--!strict
-- PlotBuilder.luau  (ServerScriptService.PlotBuilder)
-- Construye el plot de un jugador ENTERAMENTE por código. Arma un carril por
-- cada línea del Config (se adapta solo a la cantidad que haya), con su
-- dropper, su rampa, su botón de compra, y una terminal común que cobra.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))

local PlotBuilder = {}

local SPACING = 11 -- separación entre carriles (studs)

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

function PlotBuilder.build(player: Player, origin: CFrame)
	local n = #Config.Lineas
	local startX = -((n - 1) / 2) * SPACING
	local plotWidth = math.max(46, n * SPACING + 14)

	local model = Instance.new("Model")
	model.Name = "Plot_" .. player.Name

	-- Piso del plot.
	local base = part({
		Size = Vector3.new(plotWidth, 1, 78),
		Color = Color3.fromRGB(58, 58, 64),
		Material = Enum.Material.SmoothPlastic,
	})
	base.CFrame = origin * CFrame.new(0, -0.5, 0)
	base.Parent = model

	-- Punto de aparición del jugador, en SU plot.
	local spawn = Instance.new("SpawnLocation")
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame = origin * CFrame.new(0, 0.5, -20)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Color = Color3.fromRGB(235, 235, 235)
	spawn.Parent = model

	-- Terminal / caja: pad ancho al frente que junta los pasajes.
	local collector = part({
		Size = Vector3.new(plotWidth, 5, 4),
		Color = Color3.fromRGB(255, 200, 40),
		Material = Enum.Material.Neon,
		Transparency = 0.2,
	})
	collector.CFrame = origin * CFrame.new(0, 2.5, 30)
	collector.Parent = model

	local pasajes = Instance.new("Folder")
	pasajes.Name = "Pasajes"
	pasajes.Parent = model

	local lineas: { [string]: any } = {}

	for i, lineaCfg in ipairs(Config.Lineas) do
		local x = startX + (i - 1) * SPACING

		local dropper = part({
			Size = Vector3.new(6, 6, 6),
			Color = lineaCfg.Color,
			Material = Enum.Material.Metal,
		})
		dropper.CFrame = origin * CFrame.new(x, 9, -30)
		dropper.Parent = model

		-- Rampa (la "ruta") por la que ruedan los pasajes hasta la terminal.
		local hi = (origin * CFrame.new(x, 8, -27)).Position
		local lo = (origin * CFrame.new(x, 2, 26)).Position
		local mid = hi:Lerp(lo, 0.5)
		local len = (lo - hi).Magnitude
		local rampCF = CFrame.lookAt(mid, lo)

		local floor = part({ Size = Vector3.new(8, 1, len), Color = Color3.fromRGB(88, 88, 94) })
		floor.CFrame = rampCF
		floor.Parent = model

		local wallL =
			part({ Size = Vector3.new(0.6, 3, len), Color = Color3.fromRGB(120, 120, 126) })
		wallL.CFrame = rampCF * CFrame.new(-4, 1.5, 0)
		wallL.Parent = model

		local wallR =
			part({ Size = Vector3.new(0.6, 3, len), Color = Color3.fromRGB(120, 120, 126) })
		wallR.CFrame = rampCF * CFrame.new(4, 1.5, 0)
		wallR.Parent = model

		local refs: { [string]: any } = { dropper = dropper, activa = false }

		if lineaCfg.Precio > 0 then
			local boton = part({
				Size = Vector3.new(6, 3, 6),
				Color = Color3.fromRGB(28, 28, 34),
				Material = Enum.Material.Neon,
			})
			boton.CFrame = origin * CFrame.new(x, 1.5, -38)
			boton.Parent = model

			local cd = Instance.new("ClickDetector")
			cd.MaxActivationDistance = 40
			cd.Parent = boton

			-- Brillo verde para que se note que es comprable (FTUE).
			local highlight = Instance.new("Highlight")
			highlight.FillColor = Color3.fromRGB(60, 220, 90)
			highlight.FillTransparency = 0.6
			highlight.OutlineColor = Color3.fromRGB(120, 255, 150)
			highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			highlight.Parent = boton

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
			tl.Font = Enum.Font.FredokaOne
			tl.Text = string.format("%s\n$%d", lineaCfg.Nombre, lineaCfg.Precio)
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
