--!strict
-- EnvironmentService.luau  (ServerScriptService.EnvironmentService)
-- Lo que MÁS cambia el aspecto del juego: configura la iluminación, la
-- atmósfera y los efectos (antes corría con la luz fea por defecto de Roblox),
-- y genera el MUNDO por código (pasto, calle, árboles, ciudad de fondo) para
-- que las bases no floten en un vacío gris. Se corre UNA vez desde ServerMain.

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Theme = require(ReplicatedStorage:WaitForChild("Theme"))

local EnvironmentService = {}

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
	Lighting.Technology = Enum.Technology.Future -- si baja el FPS en celular: ShadowMap
	Lighting.Brightness = 2.4
	Lighting.ClockTime = 14.5 -- tarde: sombras suaves y largas
	Lighting.GeographicLatitude = 22
	Lighting.ExposureCompensation = 0.15
	Lighting.ShadowSoftness = 0.35
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1
	Lighting.GlobalShadows = true
	Lighting.Ambient = Color3.fromRGB(70, 70, 85)
	Lighting.OutdoorAmbient = Color3.fromRGB(145, 152, 170)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 235, 200)

	local atm = Instance.new("Atmosphere")
	atm.Density = 0.30
	atm.Offset = 0.25
	atm.Glare = 0.30
	atm.Haze = 0.85
	atm.Color = Color3.fromRGB(199, 215, 255)
	atm.Decay = Color3.fromRGB(106, 112, 125)
	atm.Parent = Lighting

	local cc = Instance.new("ColorCorrectionEffect")
	cc.Saturation = 0.15 -- colores más vivos (no chillón)
	cc.Contrast = 0.12
	cc.Brightness = 0
	cc.TintColor = Color3.fromRGB(255, 248, 235)
	cc.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.6 -- bajo a propósito: bloom alto quema los neón
	bloom.Size = 24
	bloom.Threshold = 0.9
	bloom.Parent = Lighting

	local sun = Instance.new("SunRaysEffect")
	sun.Intensity = 0.12
	sun.Spread = 0.8
	sun.Parent = Lighting

	local clouds = Instance.new("Clouds")
	clouds.Cover = 0.55
	clouds.Density = 0.5
	clouds.Color = Color3.fromRGB(255, 255, 255)
	clouds.Parent = Workspace.Terrain
end

-- Árbol low-poly: tronco + 3 copas esféricas, con variación al azar.
local function makeTree(parent: Instance, cf: CFrame)
	local model = Instance.new("Model")
	local h = 7 + math.random() * 4

	local trunk = makePart({
		Size = Vector3.new(1.4, h, 1.4),
		Color = Theme.Palette.Wood,
		Material = Theme.Mat.Wood,
		CanCollide = false,
	})
	trunk.CFrame = cf * CFrame.new(0, h / 2, 0)
	trunk.Parent = model

	for i = 1, 3 do
		local r = 5 + math.random() * 2
		local leaf = makePart({
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(r, r, r),
			Color = Theme.Palette.Leaf:Lerp(Color3.fromRGB(0, 0, 0), (i - 1) * 0.08),
			Material = Theme.Mat.Plastic,
			CanCollide = false,
			CanQuery = false,
		})
		leaf.CFrame = cf
			* CFrame.new((math.random() - 0.5) * 3, h + (i - 1) * 1.8, (math.random() - 0.5) * 3)
		leaf.Parent = model
	end

	model.Parent = parent
end

-- ── Mundo: pasto, calle, árboles, ciudad de fondo (todo por código) ────────
function EnvironmentService.buildWorld()
	local world = Instance.new("Model")
	world.Name = "World"

	-- Pasto con Terrain (capta la luz mejor que un Part plano).
	local terrain = Workspace.Terrain
	terrain:FillBlock(CFrame.new(490, -6, 0), Vector3.new(1600, 20, 520), Theme.Mat.Ground)
	pcall(function()
		terrain:SetMaterialColor(Theme.Mat.Ground, Theme.Palette.Grass)
	end)

	-- Calle de acceso delante de las bases.
	local street = makePart({
		Size = Vector3.new(1400, 0.5, 18),
		Color = Theme.Palette.Asphalt,
		Material = Theme.Mat.Road,
	})
	street.CFrame = CFrame.new(490, 4.3, 56)
	street.Parent = world
	for i = -11, 11 do
		local lane = makePart({
			Size = Vector3.new(22, 0.55, 1),
			Color = Theme.Palette.Gold,
			Material = Theme.Mat.Glow,
		})
		lane.CFrame = CFrame.new(490 + i * 60, 4.34, 56)
		lane.Parent = world
	end

	-- Árboles en las franjas de pasto libres (delante y detrás de la fila).
	for _ = 1, 130 do
		local x = -110 + math.random() * 1220
		local z
		if math.random() < 0.5 then
			z = -120 + math.random() * 55 -- franja trasera
		else
			z = 70 + math.random() * 55 -- franja delantera
		end
		makeTree(world, CFrame.new(x, 4, z) * CFrame.Angles(0, math.random() * 6.28, 0))
	end

	-- Ciudad de fondo: siluetas lejanas (la neblina las difumina, dan escala).
	for _ = 1, 45 do
		local x = -160 + math.random() * 1320
		local side = (math.random() < 0.5) and -1 or 1
		local z = side * (170 + math.random() * 70)
		local h = 45 + math.random() * 85
		local b = makePart({
			Size = Vector3.new(14 + math.random() * 12, h, 14 + math.random() * 12),
			Color = Theme.Palette.Asphalt:Lerp(Theme.Palette.Concrete, 0.3),
			Material = Theme.Mat.Wall,
			CanCollide = false,
			CanQuery = false,
		})
		b.CFrame = CFrame.new(x, 4 + h / 2, z)
		b.Parent = world
	end

	world.Parent = Workspace
end

function EnvironmentService.setup()
	EnvironmentService.setupLighting()
	EnvironmentService.buildWorld()
end

return EnvironmentService
