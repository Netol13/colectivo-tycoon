--!strict
-- Hud.luau  (cliente)
-- Construye y maneja toda la interfaz en pantalla, pensada para CELULAR
-- (botones grandes, texto que escala, lejos del joystick). No decide nada del
-- juego: solo muestra lo que el servidor manda y avisa cuando tocás un botón.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage:WaitForChild("Format"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local Juice = require(script.Parent:WaitForChild("Juice"))

local Hud = {}

local player = Players.LocalPlayer
local gui: ScreenGui
local cashLabel: TextLabel
local perMinLabel: TextLabel
local goalLabel: TextLabel
local rebirthBtn: TextButton
local displayedCash = 0
local rebirthCallback: (() -> ())? = nil

-- Helper para esquinas redondeadas + borde (look premium, costo casi cero).
local function decorate(obj: GuiObject, radius: number, stroke: boolean)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = obj
	if stroke then
		local s = Instance.new("UIStroke")
		s.Color = Color3.fromRGB(0, 0, 0)
		s.Transparency = 0.55
		s.Thickness = 2
		s.Parent = obj
	end
end

function Hud.init()
	gui = Instance.new("ScreenGui")
	gui.Name = "HUD"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.Parent = player:WaitForChild("PlayerGui")

	-- ── Plata (arriba, centro) ─────────────────────────────────────────
	cashLabel = Instance.new("TextLabel")
	cashLabel.Name = "Cash"
	cashLabel.AnchorPoint = Vector2.new(0.5, 0)
	cashLabel.Position = UDim2.new(0.5, 0, 0, 8)
	cashLabel.Size = UDim2.new(0, 240, 0, 64)
	cashLabel.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
	cashLabel.BackgroundTransparency = 0.15
	cashLabel.TextColor3 = Color3.fromRGB(255, 205, 50)
	cashLabel.Font = Enum.Font.FredokaOne
	cashLabel.TextScaled = true
	cashLabel.Text = "$0"
	cashLabel.Parent = gui
	decorate(cashLabel, 16, true)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 16)
	pad.PaddingRight = UDim.new(0, 16)
	pad.PaddingTop = UDim.new(0, 8)
	pad.PaddingBottom = UDim.new(0, 8)
	pad.Parent = cashLabel

	-- ── Plata por minuto (debajo de la plata) ──────────────────────────
	perMinLabel = Instance.new("TextLabel")
	perMinLabel.Name = "PerMin"
	perMinLabel.AnchorPoint = Vector2.new(0.5, 0)
	perMinLabel.Position = UDim2.new(0.5, 0, 0, 76)
	perMinLabel.Size = UDim2.new(0, 160, 0, 24)
	perMinLabel.BackgroundTransparency = 1
	perMinLabel.TextColor3 = Color3.fromRGB(150, 230, 160)
	perMinLabel.Font = Enum.Font.GothamBold
	perMinLabel.TextScaled = true
	perMinLabel.Text = ""
	perMinLabel.Parent = gui

	-- ── Meta actual (pastilla abajo-centro) ────────────────────────────
	goalLabel = Instance.new("TextLabel")
	goalLabel.Name = "Goal"
	goalLabel.AnchorPoint = Vector2.new(0.5, 1)
	goalLabel.Position = UDim2.new(0.5, 0, 1, -12)
	goalLabel.Size = UDim2.new(0, 300, 0, 40)
	goalLabel.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
	goalLabel.BackgroundTransparency = 0.2
	goalLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	goalLabel.Font = Enum.Font.GothamBold
	goalLabel.TextScaled = true
	goalLabel.Text = ""
	goalLabel.Parent = gui
	decorate(goalLabel, 14, true)
	local gpad = Instance.new("UIPadding")
	gpad.PaddingLeft = UDim.new(0, 14)
	gpad.PaddingRight = UDim.new(0, 14)
	gpad.PaddingTop = UDim.new(0, 6)
	gpad.PaddingBottom = UDim.new(0, 6)
	gpad.Parent = goalLabel

	-- ── Botón Renovar Flota (abajo-derecha, zona del pulgar) ────────────
	rebirthBtn = Instance.new("TextButton")
	rebirthBtn.Name = "Rebirth"
	rebirthBtn.AnchorPoint = Vector2.new(1, 1)
	rebirthBtn.Position = UDim2.new(1, -16, 1, -70)
	rebirthBtn.Size = UDim2.new(0, 150, 0, 56)
	rebirthBtn.BackgroundColor3 = Color3.fromRGB(170, 80, 220)
	rebirthBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	rebirthBtn.Font = Enum.Font.FredokaOne
	rebirthBtn.TextScaled = true
	rebirthBtn.Text = Locale.get("rebirth_button")
	rebirthBtn.Visible = false
	rebirthBtn.AutoButtonColor = true
	rebirthBtn.Parent = gui
	decorate(rebirthBtn, 14, true)
	rebirthBtn.Activated:Connect(function()
		Juice.punch(rebirthBtn)
		if rebirthCallback then
			rebirthCallback()
		end
	end)
end

-- Actualiza la plata con animación de conteo.
function Hud.setCash(n: number)
	Juice.countUp(function(v)
		displayedCash = v
		cashLabel.Text = Format.money(v)
	end, displayedCash, n, 0.3)
end

function Hud.setPerMin(n: number)
	perMinLabel.Text = Locale.get("money_per_min", Format.money(n))
end

function Hud.setGoal(text: string)
	goalLabel.Text = text
end

-- Muestra/oculta el botón de rebirth y le pone el texto.
function Hud.setRebirth(available: boolean, label: string?)
	rebirthBtn.Visible = available
	if label then
		rebirthBtn.Text = label
	end
end

function Hud.onRebirth(callback: () -> ())
	rebirthCallback = callback
end

-- Aviso temporal (toast) que baja desde arriba y se va solo.
function Hud.notify(text: string, kind: string?)
	local color = Color3.fromRGB(40, 130, 220)
	if kind == "error" then
		color = Color3.fromRGB(210, 60, 60)
	elseif kind == "good" then
		color = Color3.fromRGB(60, 175, 90)
	end

	local toast = Instance.new("TextLabel")
	toast.AnchorPoint = Vector2.new(0.5, 0)
	toast.Position = UDim2.new(0.5, 0, 0, -50)
	toast.Size = UDim2.new(0, 340, 0, 44)
	toast.BackgroundColor3 = color
	toast.TextColor3 = Color3.fromRGB(255, 255, 255)
	toast.Font = Enum.Font.GothamBold
	toast.TextScaled = true
	toast.Text = text
	toast.Parent = gui
	decorate(toast, 12, true)
	local tpad = Instance.new("UIPadding")
	tpad.PaddingLeft = UDim.new(0, 12)
	tpad.PaddingRight = UDim.new(0, 12)
	tpad.PaddingTop = UDim.new(0, 6)
	tpad.PaddingBottom = UDim.new(0, 6)
	tpad.Parent = toast

	TweenService
		:Create(toast, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, 0, 0, 116),
		})
		:Play()
	task.delay(2.6, function()
		TweenService:Create(toast, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {
			Position = UDim2.new(0.5, 0, 0, -50),
		}):Play()
		Debris:AddItem(toast, 0.5)
	end)
end

-- Popup de "mientras no estabas ganaste $X".
function Hud.showOffline(amount: number)
	if amount <= 0 then
		return
	end
	Hud.notify(Locale.get("welcome_back", Format.money(amount)), "good")
end

return Hud
