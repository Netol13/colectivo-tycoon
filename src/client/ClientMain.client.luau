--!strict
-- ClientMain.client.luau  (StarterPlayerScripts)
-- Punto de entrada del cliente. Detecta el idioma, prende la música, arma el
-- HUD y conecta los avisos del servidor con los efectos (Juice) y sonidos
-- (Audio). Es el "director de orquesta" del lado del jugador.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Locale = require(ReplicatedStorage:WaitForChild("Locale"))
local Format = require(ReplicatedStorage:WaitForChild("Format"))
local Net = require(ReplicatedStorage:WaitForChild("Net"))

local Juice = require(script.Parent:WaitForChild("Juice"))
local Audio = require(script.Parent:WaitForChild("Audio"))
local Hud = require(script.Parent:WaitForChild("Hud"))

local player = Players.LocalPlayer

-- ── Idioma ─────────────────────────────────────────────────────────────
Locale.setLanguage(Locale.fromLocaleId(player.LocaleId))

-- ── HUD + música ───────────────────────────────────────────────────────
Hud.init()
Audio.startMusic()

Hud.onRebirth(function()
	Net.event("RequestRebirth"):FireServer()
end)

-- ── Botón de recompensa diaria (izquierda, aparece si hay para reclamar) ─
local dailyBtn = Instance.new("TextButton")
dailyBtn.Name = "Daily"
dailyBtn.AnchorPoint = Vector2.new(0, 0.5)
dailyBtn.Position = UDim2.new(0, 12, 0.5, 0)
dailyBtn.Size = UDim2.new(0, 120, 0, 52)
dailyBtn.BackgroundColor3 = Color3.fromRGB(225, 170, 40)
dailyBtn.TextColor3 = Color3.fromRGB(40, 30, 0)
dailyBtn.Font = Enum.Font.FredokaOne
dailyBtn.TextScaled = true
dailyBtn.Text = "🎁"
dailyBtn.Visible = false
dailyBtn.Parent = player:WaitForChild("PlayerGui"):WaitForChild("HUD")
local dc = Instance.new("UICorner")
dc.CornerRadius = UDim.new(0, 14)
dc.Parent = dailyBtn

dailyBtn.Activated:Connect(function()
	Juice.punch(dailyBtn)
	Net.event("RequestDaily"):FireServer()
end)

-- ── Estado: lee atributos que setea el servidor y refresca el HUD ───────
local function refresh()
	Hud.setPerMin(player:GetAttribute("PerMin") or 0)

	local goalKind = player:GetAttribute("GoalKind")
	if goalKind == "buy" then
		Hud.setGoal(Locale.get("goal_buy", player:GetAttribute("GoalName") or "?"))
	elseif goalKind == "rebirth" then
		Hud.setGoal(Locale.get("goal_rebirth", Format.money(player:GetAttribute("GoalCost") or 0)))
	elseif goalKind == "all" then
		Hud.setGoal(Locale.get("goal_all"))
	end

	local ready = player:GetAttribute("RebirthReady") == true
	Hud.setRebirth(ready, Locale.get("rebirth_button"))
end

for _, attr in { "PerMin", "GoalKind", "GoalName", "GoalCost", "RebirthReady" } do
	player:GetAttributeChangedSignal(attr):Connect(refresh)
end

-- ── Plata (leaderstats) con animación de conteo ─────────────────────────
local function hookCash()
	local leaderstats = player:WaitForChild("leaderstats")
	local plata = leaderstats:WaitForChild(Config.Currency.Name)
	Hud.setCash(plata.Value)
	plata.Changed:Connect(function()
		Hud.setCash(plata.Value)
	end)
end
task.spawn(hookCash)
task.defer(refresh)

-- ── Avisos del servidor -> efectos + sonidos ────────────────────────────
Net.event("CollectFX").OnClientEvent
	:Connect(function(worldPos: Vector3, amount: number, gold: boolean?)
		local color = gold and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(95, 255, 105)
		Juice.popNumber(worldPos, "+" .. Format.money(amount), color)
		Audio.collect()
	end)

Net.event("PurchaseFX").OnClientEvent:Connect(function(worldPos: Vector3, color: Color3?)
	Juice.burst(worldPos, color)
	Audio.buy()
end)

Net.event("Notify").OnClientEvent:Connect(function(key: string, kind: string?, ...)
	Hud.notify(Locale.get(key, ...), kind)
	if kind == "error" then
		Audio.error()
	end
end)

Net.event("RebirthFX").OnClientEvent:Connect(function(level: number)
	Juice.celebrate()
	Audio.milestone()
	Hud.notify(Locale.get("rebirth_done", level), "good")
end)

Net.event("EventState").OnClientEvent:Connect(function(active: boolean, mult: number)
	if active then
		Hud.notify(Locale.get("event_rush", mult), "good")
	end
end)

Net.event("LaserToggle").OnClientEvent:Connect(function(on: boolean)
	Hud.notify(Locale.get(on and "laser_on" or "laser_off"), on and "good" or "info")
end)

-- ── Recompensa diaria (atributos que setea el servidor) ─────────────────
local dailyPulse: Tween? = nil
local function updateDaily()
	local canClaim = player:GetAttribute("DailyCanClaim") == true
	dailyBtn.Visible = canClaim
	if canClaim then
		dailyBtn.Text = "🎁 " .. Locale.get("daily_day", player:GetAttribute("DailyDay") or 1)
		if not dailyPulse then
			local pulse = TweenService:Create(
				dailyBtn,
				TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true),
				{ Size = UDim2.new(0, 132, 0, 56) }
			)
			dailyPulse = pulse
			pulse:Play()
		end
	end
end
player:GetAttributeChangedSignal("DailyCanClaim"):Connect(updateDaily)
player:GetAttributeChangedSignal("DailyDay"):Connect(updateDaily)
task.defer(updateDaily)

-- ── Ganancias offline (el servidor las deja en un atributo, se muestra 1 vez) ─
task.delay(1.5, function()
	local earned = player:GetAttribute("OfflineEarned") or 0
	if earned > 0 then
		Hud.showOffline(earned)
	end
end)

-- ── Botón de música (mute / unmute) ─────────────────────────────────────
local musicOn = true
local musicBtn = Instance.new("TextButton")
musicBtn.Name = "Music"
musicBtn.Position = UDim2.new(0, 12, 0, 12)
musicBtn.Size = UDim2.new(0, 46, 0, 46)
musicBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
musicBtn.BackgroundTransparency = 0.2
musicBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
musicBtn.Font = Enum.Font.FredokaOne
musicBtn.TextScaled = true
musicBtn.Text = "🔊"
musicBtn.Parent = player:WaitForChild("PlayerGui"):WaitForChild("HUD")
local mcorner = Instance.new("UICorner")
mcorner.CornerRadius = UDim.new(0, 12)
mcorner.Parent = musicBtn
musicBtn.Activated:Connect(function()
	musicOn = not musicOn
	Audio.setMusicVolume(musicOn and 0.25 or 0)
	musicBtn.Text = musicOn and "🔊" or "🔇"
end)
