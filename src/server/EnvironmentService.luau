--!strict
-- EnvironmentService.luau  (ServerScriptService.EnvironmentService)
-- Lo que MÁS cambia el aspecto del juego: configura la iluminación, la
-- atmósfera y los efectos, y genera el MUNDO por código (pasto, calle, árboles,
-- ciudad de fondo). Se corre UNA vez desde ServerMain.

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Theme = require(ReplicatedStorage:WaitForChild("Theme"))

local EnvironmentService = {}

-- Altura de la superficie del pasto (todo lo del mundo se apoya acá).
local GROUND_Y = 2

local function makePart(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	for k, v in pairs(props) do
		(p :: any)[k] = v
	end
	return p
end

-- ── Iluminación + post-procesado (look cálido, vibrante, tipo tarde soleada) ─
function EnvironmentService.setupLighting()
	pcall(function()
		Lighting.Technology = Enum.Technology.Future -- si baja el FPS en celular: ShadowMap
	end)
	Lighting.Brightness = 2.3
	Lighting.ClockTime = 14.5
	Lighting.GeographicLatitude = 22
	Lighting.ExposureCompensation = 0.1
	Lighting.ShadowSoftness = 0.35
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1
	Lighting.GlobalShadows = true
	Lighting.Ambient = Color3.fromRGB(70, 70, 85)
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 155, 172)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 235, 200)

	local atm = Instance.new("Atmosphere")
	atm.Density = 0.34
	atm.Offset = 0.2
	atm.Glare = 0.2
	atm.Haze = 0.5 -- neblina leve: difumina lo lejano sin tapar todo
	atm.Color = Color3.fromRGB(199, 215, 255)
	atm.Decay = Color3.fromRGB(106, 112, 125)
	atm.Parent = Lighting

	local cc = Instance.new("ColorCorrectionEffect")
	cc.Saturation = 0.12
	cc.Contrast = 0.1
	cc.Brightness = 0
	cc.TintColor = Color3.fromRGB(255, 248, 235)
	cc.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.45 -- bajo: bloom alto quema todo
	bloom.Size = 24
	bloom.Threshold = 1.0
	bloom.Parent = Lighting

	local sun = Instance.new("SunRaysEffect")
	sun.Intensity = 0.1
	sun.Spread = 0.7
	sun.Parent = Lighting

	local clouds = Instance.new("Clouds")
	clouds.Cover = 0.6
	clouds.Density = 0.45
	clouds.Color = Color3.fromRGB(255, 255, 255)
	clouds.Parent = Workspace.Terrain
end

-- Árbol low-poly más natural: tronco + copa de varias esferas agrupadas con
-- material orgánico (LeafyGrass) y verdes variados (no globos de plástico).
local function makeTree(parent: Instance, cf: CFrame)
	local model = Instance.new("Model")
	local h = 8 + math.random() * 5

	local trunk = makePart({
		Size = Vector3.new(1.7, h, 1.7),
		Color = Theme.Palette.Wood,
		Material = Enum.Material.Wood,
		CanCollide = false,
		CanQuery = false,
	})
	trunk.CFrame = cf * CFrame.new(0, h / 2, 0)
	trunk.Parent = model

	-- Copa: 1 esfera central grande + 5 chicas alrededor, irregular.
	local clumps = 6
	for i = 1, clumps do
		local central = (i == 1)
		local r = central and (6 + math.random() * 1.5) or (3.5 + math.random() * 2)
		local angle = (i / clumps) * math.pi * 2 + math.random()
		local rad = central and 0 or (2.5 + math.random() * 2)
		local leaf = makePart({
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(r, r * 0.9, r),
			Color = Theme.Palette.Leaf:Lerp(Color3.fromRGB(58, 110, 52), math.random() * 0.6),
			Material = Enum.Material.LeafyGrass, -- textura orgánica, no plástico liso
			CanCollide = false,
			CanQuery = false,
		})
		leaf.CFrame = cf
			* CFrame.new(math.cos(angle) * rad, h + 1 + math.random() * 2.5, math.sin(angle) * rad)
		leaf.Parent = model
	end

	model.Parent = parent
end

-- Edificio de fondo con franjas de ventanas (pisos), lejos y difuminado.
local function makeBuilding(parent: Instance, x: number, z: number)
	local h = 60 + math.random() * 130
	local w = 18 + math.random() * 16
	local col = Theme.Palette.Concrete:Lerp(Theme.Palette.Sky, math.random() * 0.45)

	local body = makePart({
		Size = Vector3.new(w, h, w),
		Color = col,
		Material = Enum.Material.Concrete,
		CanCollide = false,
		CanQuery = false,
	})
	body.CFrame = CFrame.new(x, GROUND_Y + h / 2, z)
	body.Parent = parent

	-- Franjas de ventanas iluminadas cada ~10 studs (sensación de pisos).
	local pisos = math.floor(h / 10)
	for f = 1, pisos do
		local win = makePart({
			Size = Vector3.new(w + 0.3, 2.4, w + 0.3),
			Color = Color3.fromRGB(150, 195, 230),
			Material = Enum.Material.Glass,
			Transparency = 0.1,
			CanCollide = false,
			CanQuery = false,
		})
		win.CFrame = CFrame.new(x, GROUND_Y + f * 10, z)
		win.Parent = parent
	end
end

-- ── Mundo: pasto, calle, árboles, ciudad de fondo (todo por código) ────────
function EnvironmentService.buildWorld()
	local world = Instance.new("Model")
	world.Name = "World"

	-- Pasto: un Part plano grande con material Grass. Confiable y SIN briznas que
	-- trepan (antes usaba Terrain, que fallaba y dejaba todo sobre el baseplate).
	local pasto = makePart({
		Size = Vector3.new(1950, 2, 1150),
		Color = Theme.Palette.Grass,
		Material = Enum.Material.Grass,
	})
	pasto.CFrame = CFrame.new(490, GROUND_Y - 1, 0)
	pasto.Parent = world

	-- Calle de acceso delante de las bases.
	local street = makePart({
		Size = Vector3.new(1500, 0.5, 20),
		Color = Theme.Palette.Asphalt,
		Material = Theme.Mat.Road,
	})
	street.CFrame = CFrame.new(490, GROUND_Y + 0.3, 58)
	street.Parent = world
	for i = -12, 12 do
		local lane = makePart({
			Size = Vector3.new(24, 0.55, 1),
			Color = Theme.Palette.Gold,
			Material = Theme.Mat.Glow,
		})
		lane.CFrame = CFrame.new(490 + i * 62, GROUND_Y + 0.34, 58)
		lane.Parent = world
	end

	-- Árboles en las franjas de pasto libres (delante y detrás de la fila).
	for _ = 1, 110 do
		local x = -120 + math.random() * 1240
		local z
		if math.random() < 0.5 then
			z = -130 + math.random() * 55
		else
			z = 80 + math.random() * 55
		end
		makeTree(world, CFrame.new(x, GROUND_Y, z) * CFrame.Angles(0, math.random() * 6.28, 0))
	end

	-- Ciudad de fondo: lejos (la neblina la difumina y da escala).
	for _ = 1, 26 do
		local x = -250 + math.random() * 1500
		local side = (math.random() < 0.5) and -1 or 1
		local z = side * (340 + math.random() * 180)
		makeBuilding(world, x, z)
	end

	world.Parent = Workspace
end

function EnvironmentService.setup()
	-- Cada parte va en pcall: si la iluminación o el mundo fallan, el resto del
	-- servidor (las bases de los jugadores) tiene que arrancar igual.
	local okL = pcall(EnvironmentService.setupLighting)
	if not okL then
		warn("[EnvironmentService] no se pudo configurar la iluminación")
	end
	local okW = pcall(EnvironmentService.buildWorld)
	if not okW then
		warn("[EnvironmentService] no se pudo construir el mundo")
	end
end

return EnvironmentService
