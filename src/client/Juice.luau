--!strict
-- Juice.luau  (cliente)
-- Todos los efectos visuales "jugosos" en un solo lugar, para que los dos
-- mantengan el mismo estilo. "Juice" = el feedback que hace que ganar plata se
-- sienta gratificante (numeritos que saltan, brillos, golpes de escala).
-- Es 100% visual del lado del cliente: no decide nada del juego.

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Juice = {}

local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

-- Numerito flotante "+$X" que sube y se desvanece, en una posición del mundo.
function Juice.popNumber(worldPos: Vector3, text: string, color: Color3?)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Size = Vector3.new(1, 1, 1)
	part.CFrame = CFrame.new(worldPos)
	part.Parent = Workspace

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromScale(4, 1.6)
	bb.AlwaysOnTop = true
	bb.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = color or Color3.fromRGB(95, 255, 105)
	label.TextStrokeTransparency = 0.3
	label.TextScaled = true
	label.Text = text
	label.Parent = bb

	local target = CFrame.new(worldPos + Vector3.new(math.random(-2, 2), 5.5, 0))
	TweenService:Create(
		part,
		TweenInfo.new(0.95, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ CFrame = target }
	):Play()
	TweenService:Create(label, TweenInfo.new(0.95, Enum.EasingStyle.Quad), {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()
	Debris:AddItem(part, 1.1)
end

-- Golpe de escala (rebota) sobre un botón. Da feedback al tocar en celular.
function Juice.punch(gui: GuiObject)
	local scale = gui:FindFirstChildOfClass("UIScale")
	if not scale then
		scale = Instance.new("UIScale")
		scale.Parent = gui
	end
	scale.Scale = 0.82
	TweenService:Create(
		scale,
		TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = 1 }
	):Play()
end

-- Sacudida + flash rojo cuando algo falla (no te alcanza la plata).
function Juice.shake(gui: GuiObject)
	local origin = gui.Position
	task.spawn(function()
		for _ = 1, 6 do
			gui.Position = origin + UDim2.fromOffset(math.random(-7, 7), 0)
			task.wait(0.03)
		end
		gui.Position = origin
	end)
end

-- Estallido de partículas (confeti/chispas) en una posición del mundo.
function Juice.burst(worldPos: Vector3, color: Color3?)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Size = Vector3.new(1, 1, 1)
	part.CFrame = CFrame.new(worldPos)
	part.Parent = Workspace

	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Lifetime = NumberRange.new(0.6, 1.2)
	emitter.Speed = NumberRange.new(8, 18)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rate = 0
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.Color = ColorSequence.new(color or Color3.fromRGB(255, 210, 60))
	emitter.Parent = part

	emitter:Emit(isMobile and 24 or 45) -- menos partículas en celular
	Debris:AddItem(part, 2)
end

-- Celebración grande (rebirth): flash blanco en toda la pantalla.
function Juice.celebrate()
	local pg = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if not pg then
		return
	end
	local gui = Instance.new("ScreenGui")
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 999
	gui.Parent = pg

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.BackgroundTransparency = 0.1
	frame.Parent = gui

	TweenService
		:Create(frame, TweenInfo.new(0.9, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 })
		:Play()
	Debris:AddItem(gui, 1)
end

-- Anima un número subiendo de "from" a "to" (en vez de saltar de golpe).
function Juice.countUp(setter: (number) -> (), from: number, to: number, duration: number?)
	local dur = duration or 0.3
	local start = os.clock()
	task.spawn(function()
		while true do
			local t = math.min((os.clock() - start) / dur, 1)
			setter(math.floor(from + (to - from) * t))
			if t >= 1 then
				break
			end
			task.wait()
		end
	end)
end

return Juice
