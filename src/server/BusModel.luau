--!strict
-- BusModel.luau  (ServerScriptService.BusModel)
-- Arma un minicolectivo por código (cuerpo + techo + ventanas + 4 ruedas).
-- Todo ANCLADO y sin colisión: se mueve con Model:PivotTo() (no por física),
-- así nunca se vuelca y no genera lag en celular. Reemplaza la pelota.

local BusModel = {}

local function makePart(name: string, size: Vector3, color: Color3, parent: Instance): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- Devuelve un Model de minicolectivo con el color de la línea y el valor encima.
-- "tier" (renovaciones) le cambia el aspecto: a más renovaciones, brilla.
function BusModel.build(color: Color3, valor: number, tier: number?): Model
	local model = Instance.new("Model")
	model.Name = "Bus"

	-- Cuerpo (PrimaryPart). Largo en Z = dirección de avance.
	-- Los colectivos más valiosos son un poco más largos (feedback de forma).
	local largo = 6 + math.clamp(valor / 60, 0, 3)
	local body = makePart("Body", Vector3.new(3, 2, largo), color, model)
	body.Material = (tier and tier >= 3) and Enum.Material.Neon or Enum.Material.SmoothPlastic
	body.CFrame = CFrame.new()
	model.PrimaryPart = body

	-- Techo, un poco más oscuro que el cuerpo.
	local roof =
		makePart("Roof", Vector3.new(2.6, 0.7, 4), color:Lerp(Color3.new(0, 0, 0), 0.35), model)
	roof.CFrame = body.CFrame * CFrame.new(0, 1.35, 0)

	-- Franja de ventanas.
	local windows =
		makePart("Windows", Vector3.new(3.05, 0.8, 4.2), Color3.fromRGB(170, 220, 255), model)
	windows.Material = Enum.Material.Glass
	windows.Transparency = 0.15
	windows.CFrame = body.CFrame * CFrame.new(0, 0.45, 0)

	-- 4 ruedas (cilindros, eje en X = lateral del bus).
	local wheelOffsets = {
		Vector3.new(1.55, -1, 1.9),
		Vector3.new(-1.55, -1, 1.9),
		Vector3.new(1.55, -1, -1.9),
		Vector3.new(-1.55, -1, -1.9),
	}
	for i, off in ipairs(wheelOffsets) do
		local wheel =
			makePart("Wheel" .. i, Vector3.new(0.5, 1.4, 1.4), Color3.fromRGB(28, 28, 30), model)
		wheel.Shape = Enum.PartType.Cylinder
		wheel.CFrame = body.CFrame * CFrame.new(off)
	end

	-- Faros neón adelante (detalle, sin cartel de valor encima del bus).
	local faro = makePart("Faro", Vector3.new(3.05, 0.5, 0.4), Color3.fromRGB(255, 245, 200), model)
	faro.Material = Enum.Material.Neon
	faro.CFrame = body.CFrame * CFrame.new(0, -0.4, -largo / 2)

	return model
end

return BusModel
