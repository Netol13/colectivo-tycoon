--!strict
-- HudClient.client.luau  (StarterPlayer.StarterPlayerScripts.HudClient)
-- UI del cliente: muestra la plata en grande abajo de la pantalla.
-- Es SOLO visual: no decide nada, solo lee el leaderstats que escribe el
-- servidor. Si un exploiter cambia este numero, cambia su pantalla pero no su
-- plata real (que vive en el servidor).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "HUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local label = Instance.new("TextLabel")
label.Size = UDim2.new(0, 280, 0, 76)
label.Position = UDim2.new(0.5, -140, 1, -100)
label.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
label.BackgroundTransparency = 0.25
label.TextColor3 = Color3.fromRGB(255, 200, 40)
label.Font = Enum.Font.GothamBold
label.TextScaled = true
label.Text = "$0"
label.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = label

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 10)
padding.PaddingBottom = UDim.new(0, 10)
padding.PaddingLeft = UDim.new(0, 14)
padding.PaddingRight = UDim.new(0, 14)
padding.Parent = label

local function hook()
	local leaderstats = player:WaitForChild("leaderstats")
	local plata = leaderstats:WaitForChild(Config.Currency.Name)

	local function update()
		label.Text = string.format("$%d  %s", plata.Value, Config.Currency.Name)
	end

	update()
	plata.Changed:Connect(update)
end

hook()
