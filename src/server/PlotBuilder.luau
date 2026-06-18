--!strict
-- PlotBuilder.luau  (ServerScriptService.PlotBuilder)
-- Construye el plot de un jugador ENTERAMENTE por código. Arma un carril por
-- cada línea del Config (se adapta solo a la cantidad que haya), con su
-- dropper, su rampa, su botón de compra, y una terminal común que cobra.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Theme = require(ReplicatedStorage:WaitForChild("Theme"))

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

-- Botón de compra genérico (lo usan las líneas y las construcciones).
local function makeBuyPad(
	model: Model,
	cframe: CFrame,
	titulo: string,
	precio: number,
	tinte: Color3
): Part
	-- Pad PLANO que se pisa (sin colisión: lo atravesás al caminar y dispara).
	local boton = part({
		Size = Vector3.new(6, 1, 6),
		Color = Color3.fromRGB(28, 28, 34),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Transparency = 0.15,
	})
	boton.CFrame = cframe
	boton.Parent = model

	local hl = Instance.new("Highlight")
	hl.FillColor = tinte
	hl.FillTransparency = 0.6
	hl.OutlineColor = tinte:Lerp(Color3.new(1, 1, 1), 0.4)
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Parent = boton

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromScale(7, 2.5)
	bb.StudsOffset = Vector3.new(0, 3, 0)
	bb.AlwaysOnTop = true
	bb.Parent = boton

	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.TextColor3 = Color3.fromRGB(255, 255, 255)
	tl.TextStrokeTransparency = 0.3
	tl.TextScaled = true
	tl.Font = Enum.Font.FredokaOne
	tl.Text = string.format("%s\n$%d", titulo, precio)
	tl.Parent = bb

	return boton
end

-- Poste de luz con PointLight.
local function buildLight(plot: any, buildCfg: any): Model
	local model = Instance.new("Model")
	local at = plot.origin * buildCfg.Offset
	local poste = part({
		Size = Vector3.new(0.6, 12, 0.6),
		Color = Color3.fromRGB(40, 40, 45),
		Material = Enum.Material.Metal,
	})
	poste.CFrame = at * CFrame.new(0, 6, 0)
	poste.Parent = model
	local foco = part({
		Size = Vector3.new(2, 1, 2),
		Color = Color3.fromRGB(255, 240, 180),
		Material = Enum.Material.Neon,
	})
	foco.CFrame = at * CFrame.new(0, 12, 0)
	foco.Parent = model
	local light = Instance.new("PointLight")
	light.Brightness = 2.5
	light.Range = 26
	light.Color = Color3.fromRGB(255, 240, 190)
	light.Parent = foco
	model.Parent = plot.model
	return model
end

-- Puerta de entrada con láseres (arrancan apagados) y un switch con prompt.
local function buildDoor(plot: any, buildCfg: any): Model
	local model = Instance.new("Model")
	model.Name = "Door"
	local base = plot.origin * buildCfg.Offset

	local pilarL = part({
		Size = Vector3.new(2, 12, 2),
		Color = Color3.fromRGB(60, 60, 68),
		Material = Enum.Material.Metal,
	})
	pilarL.CFrame = base * CFrame.new(-6, 6, 0)
	pilarL.Parent = model
	local pilarR = part({
		Size = Vector3.new(2, 12, 2),
		Color = Color3.fromRGB(60, 60, 68),
		Material = Enum.Material.Metal,
	})
	pilarR.CFrame = base * CFrame.new(6, 6, 0)
	pilarR.Parent = model
	local dintel = part({
		Size = Vector3.new(14, 2, 2),
		Color = Color3.fromRGB(60, 60, 68),
		Material = Enum.Material.Metal,
	})
	dintel.CFrame = base * CFrame.new(0, 12, 0)
	dintel.Parent = model

	-- 4 láseres horizontales, apagados al inicio (Transparency 1, sin Touch).
	for i = 1, 4 do
		local laser = part({
			Size = Vector3.new(11, 0.25, 0.25),
			Color = Color3.fromRGB(255, 40, 40),
			Material = Enum.Material.Neon,
		})
		laser.Name = "Laser"
		laser.CFrame = base * CFrame.new(0, 2 + i * 2, 0)
		laser.Transparency = 1
		laser.CanTouch = false
		laser.Parent = model
	end

	-- Switch para prender/apagar.
	local switch = part({
		Size = Vector3.new(2, 3, 1),
		Color = Color3.fromRGB(200, 60, 60),
		Material = Enum.Material.Neon,
	})
	switch.Name = "LaserSwitch"
	switch.CFrame = base * CFrame.new(9, 2, 0)
	switch.Parent = model

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Láser"
	prompt.ObjectText = "Puerta"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = switch

	model.Parent = plot.model
	return model
end

-- NPC simple del cobrador automático (decorativo; el cobro lo hace HelperService).
local function buildHelper(plot: any, buildCfg: any): Model
	local model = Instance.new("Model")
	local at = plot.origin * buildCfg.Offset
	local body = part({
		Size = Vector3.new(2, 4, 1.5),
		Color = Color3.fromRGB(70, 130, 200),
		Material = Enum.Material.SmoothPlastic,
	})
	body.CFrame = at
	body.Parent = model
	local head = part({
		Size = Vector3.new(1.6, 1.6, 1.6),
		Color = Color3.fromRGB(245, 205, 165),
		Material = Enum.Material.SmoothPlastic,
	})
	head.CFrame = at * CFrame.new(0, 2.9, 0)
	head.Parent = model

	local bb = Instance.new("BillboardGui")
	bb.Adornee = head
	bb.Size = UDim2.fromScale(4.5, 1.3)
	bb.StudsOffset = Vector3.new(0, 1.6, 0)
	bb.AlwaysOnTop = true
	bb.Parent = head
	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.Font = Enum.Font.FredokaOne
	tl.TextColor3 = Color3.fromRGB(255, 255, 255)
	tl.TextStrokeTransparency = 0.3
	tl.TextScaled = true
	tl.Text = "💵 Cobrador"
	tl.Parent = bb

	model.Parent = plot.model
	return model
end

-- Construye (materializa) una estructura comprada y la guarda en plot.builds.
function PlotBuilder.materialize(plot: any, buildCfg: any): Instance?
	local inst: Instance?
	if buildCfg.Kind == "wall" or buildCfg.Kind == "deco" then
		local p =
			part({ Size = buildCfg.Size, Color = buildCfg.Color, Material = buildCfg.Material })
		p.CFrame = plot.origin * buildCfg.Offset
		p.Parent = plot.model
		inst = p
	elseif buildCfg.Kind == "light" then
		inst = buildLight(plot, buildCfg)
	elseif buildCfg.Kind == "door" then
		inst = buildDoor(plot, buildCfg)
	elseif buildCfg.Kind == "helper" then
		inst = buildHelper(plot, buildCfg)
	end
	if inst then
		inst.Name = (buildCfg.Kind == "door") and "Door" or buildCfg.Id
		plot.builds[buildCfg.Id] = inst
	end
	return inst
end

function PlotBuilder.build(player: Player, origin: CFrame)
	local n = #Config.Lineas
	local startX = -((n - 1) / 2) * SPACING
	local plotWidth = math.max(46, n * SPACING + 14)

	local model = Instance.new("Model")
	model.Name = "Plot_" .. player.Name

	-- Cimiento: bloque grueso que sobresale del pasto (no queda al ras).
	local cimiento = part({
		Size = Vector3.new(plotWidth + 4, 16, 82),
		Color = Theme.Palette.Dark,
		Material = Theme.Mat.Wall,
	})
	cimiento.CFrame = origin * CFrame.new(0, -8.3, 0)
	cimiento.Parent = model

	-- Piso del plot (la superficie donde caminás).
	local base = part({
		Size = Vector3.new(plotWidth, 0.6, 78),
		Color = Theme.Palette.Concrete,
		Material = Theme.Mat.Wall,
	})
	base.CFrame = origin * CFrame.new(0, -0.3, 0)
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

	-- Terminal: caja sólida donde se junta la plata.
	local collector = part({
		Size = Vector3.new(plotWidth, 4, 5),
		Color = Theme.Palette.Dark,
		Material = Enum.Material.Metal,
	})
	collector.Name = "Terminal"
	collector.CFrame = origin * CFrame.new(0, 2, 30)
	collector.Parent = model

	-- Monitor: pantalla parada que muestra la plata acumulada.
	local monitor = part({
		Size = Vector3.new(13, 6.5, 0.6),
		Color = Color3.fromRGB(14, 17, 22),
		Material = Enum.Material.SmoothPlastic,
	})
	monitor.CFrame = origin * CFrame.new(0, 8.5, 31) * CFrame.Angles(math.rad(-10), 0, 0)
	monitor.Parent = model
	local marco = part({
		Size = Vector3.new(13.6, 7.1, 0.4),
		Color = Theme.Palette.Cash,
		Material = Enum.Material.Neon,
	})
	marco.CFrame = monitor.CFrame * CFrame.new(0, 0, 0.2)
	marco.Parent = model

	local pendBB = Instance.new("BillboardGui")
	pendBB.Adornee = monitor
	pendBB.Size = UDim2.fromScale(9, 3.5)
	pendBB.MaxDistance = 150
	pendBB.Parent = monitor

	local pendingLabel = Instance.new("TextLabel")
	pendingLabel.Name = "Pending"
	pendingLabel.Size = UDim2.fromScale(1, 1)
	pendingLabel.BackgroundTransparency = 1
	pendingLabel.Font = Enum.Font.FredokaOne
	pendingLabel.TextColor3 = Theme.Palette.Cash
	pendingLabel.TextStrokeTransparency = 0.4
	pendingLabel.TextScaled = true
	pendingLabel.Text = "$0"
	pendingLabel.Parent = pendBB

	-- Pad de cobro: PISALO para cobrar la plata acumulada.
	local claimPad = part({
		Size = Vector3.new(12, 1, 6),
		Color = Theme.Palette.Cash,
		Material = Enum.Material.Neon,
		CanCollide = false,
		Transparency = 0.1,
	})
	claimPad.Name = "ClaimPad"
	claimPad.CFrame = origin * CFrame.new(0, 0.6, 23)
	claimPad.Parent = model

	local claimBB = Instance.new("BillboardGui")
	claimBB.Adornee = claimPad
	claimBB.Size = UDim2.fromScale(6, 1.6)
	claimBB.StudsOffset = Vector3.new(0, 2.2, 0)
	claimBB.AlwaysOnTop = true
	claimBB.Parent = claimPad
	local claimTL = Instance.new("TextLabel")
	claimTL.Size = UDim2.fromScale(1, 1)
	claimTL.BackgroundTransparency = 1
	claimTL.Font = Enum.Font.FredokaOne
	claimTL.TextColor3 = Color3.fromRGB(255, 255, 255)
	claimTL.TextStrokeTransparency = 0.3
	claimTL.TextScaled = true
	claimTL.Text = "COBRAR 💵"
	claimTL.Parent = claimBB

	local pasajes = Instance.new("Folder")
	pasajes.Name = "Pasajes"
	pasajes.Parent = model

	local lineas: { [string]: any } = {}

	for i, lineaCfg in ipairs(Config.Lineas) do
		local x = startX + (i - 1) * SPACING

		-- "Estación": un portal del color de la línea de donde sale el colectivo.
		local posteIzq = part({
			Size = Vector3.new(1.4, 8, 1.4),
			Color = lineaCfg.Color,
			Material = Enum.Material.Metal,
		})
		posteIzq.CFrame = origin * CFrame.new(x - 4, 4, -30)
		posteIzq.Parent = model
		local posteDer = part({
			Size = Vector3.new(1.4, 8, 1.4),
			Color = lineaCfg.Color,
			Material = Enum.Material.Metal,
		})
		posteDer.CFrame = origin * CFrame.new(x + 4, 4, -30)
		posteDer.Parent = model
		local dintel = part({
			Size = Vector3.new(10, 2, 3),
			Color = lineaCfg.Color:Lerp(Color3.fromRGB(255, 255, 255), 0.15),
			Material = Enum.Material.Neon,
		})
		dintel.CFrame = origin * CFrame.new(x, 9, -30)
		dintel.Parent = model
		local dropper = dintel -- referencia visual de la estación

		-- Pista PLANA (calle) por la que viaja el colectivo hasta la terminal.
		-- Misma altura en los dos extremos = sin pendiente.
		local busY = 0.6
		local hi = (origin * CFrame.new(x, busY, -27)).Position
		local lo = (origin * CFrame.new(x, busY, 26)).Position
		local mid = hi:Lerp(lo, 0.5)
		local len = (lo - hi).Magnitude
		local rampCF = CFrame.lookAt(mid, lo)

		local floor = part({
			Size = Vector3.new(8, 1, len),
			Color = Theme.Palette.Asphalt,
			Material = Theme.Mat.Road,
		})
		floor.CFrame = rampCF
		floor.Parent = model

		local wallL = part({ Size = Vector3.new(0.6, 3, len), Color = Theme.Palette.Curb })
		wallL.CFrame = rampCF * CFrame.new(-4, 1.5, 0)
		wallL.Parent = model

		local wallR = part({ Size = Vector3.new(0.6, 3, len), Color = Theme.Palette.Curb })
		wallR.CFrame = rampCF * CFrame.new(4, 1.5, 0)
		wallR.Parent = model

		-- Puntos de la ruta del minicolectivo (1.5 studs sobre la rampa).
		local up = Vector3.new(0, 1.5, 0)
		local refs: { [string]: any } = {
			dropper = dropper,
			activa = false,
			live = 0,
			busStart = CFrame.lookAt(hi + up, lo + up),
			busEnd = CFrame.lookAt(lo + up, lo + (lo - hi) + up),
			routeLen = len,
		}

		if lineaCfg.Precio > 0 then
			refs.boton = makeBuyPad(
				model,
				origin * CFrame.new(x, 0.6, -38),
				lineaCfg.Nombre,
				lineaCfg.Precio,
				Color3.fromRGB(60, 220, 90)
			)
		end

		lineas[lineaCfg.Id] = refs
	end

	-- Pads de compra de construcciones (columna al costado izquierdo del plot).
	local buildPads: { [string]: any } = {}
	for i, buildCfg in ipairs(Config.Builds) do
		local padCF = origin * CFrame.new(-34, 0.6, -26 + (i - 1) * 7)
		buildPads[buildCfg.Id] =
			makeBuyPad(model, padCF, buildCfg.Nombre, buildCfg.Precio, Color3.fromRGB(80, 160, 240))
	end

	model.Parent = workspace

	return {
		model = model,
		spawn = spawn,
		collector = collector,
		pendingLabel = pendingLabel,
		claimPad = claimPad,
		pasajes = pasajes,
		lineas = lineas,
		builds = {}, -- estructuras materializadas (se llenan al comprar/reconstruir)
		buildPads = buildPads,
		origin = origin,
	}
end

return PlotBuilder
