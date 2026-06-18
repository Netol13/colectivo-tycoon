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

-- ── Panel de misiones ───────────────────────────────────────────────────
local hudGui = player:WaitForChild("PlayerGui"):WaitForChild("HUD")

local misionesBtn = Instance.new("TextButton")
misionesBtn.Name = "MisionesBtn"
misionesBtn.Position = UDim2.new(0, 12, 0, 66)
misionesBtn.Size = UDim2.new(0, 140, 0, 44)
misionesBtn.BackgroundColor3 = Color3.fromRGB(60, 90, 160)
misionesBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
misionesBtn.Font = Enum.Font.FredokaOne
misionesBtn.TextScaled = true
misionesBtn.Text = "📋 " .. Locale.get("missions")
misionesBtn.Parent = hudGui
local mbc = Instance.new("UICorner")
mbc.CornerRadius = UDim.new(0, 12)
mbc.Parent = misionesBtn

local panel = Instance.new("Frame")
panel.Name = "MisionesPanel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.new(0.5, 0, 0.5, 0)
panel.Size = UDim2.new(0, 380, 0, 320)
panel.BackgroundColor3 = Color3.fromRGB(24, 26, 34)
panel.BackgroundTransparency = 0.05
panel.Visible = false
panel.Parent = hudGui
local pc = Instance.new("UICorner")
pc.CornerRadius = UDim.new(0, 16)
pc.Parent = panel

local titulo = Instance.new("TextLabel")
titulo.Size = UDim2.new(1, -50, 0, 44)
titulo.Position = UDim2.new(0, 12, 0, 4)
titulo.BackgroundTransparency = 1
titulo.Font = Enum.Font.FredokaOne
titulo.TextColor3 = Color3.fromRGB(255, 255, 255)
titulo.TextScaled = true
titulo.TextXAlignment = Enum.TextXAlignment.Left
titulo.Text = "📋 " .. Locale.get("missions")
titulo.Parent = panel

local cerrar = Instance.new("TextButton")
cerrar.AnchorPoint = Vector2.new(1, 0)
cerrar.Position = UDim2.new(1, -8, 0, 8)
cerrar.Size = UDim2.new(0, 36, 0, 36)
cerrar.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
cerrar.TextColor3 = Color3.fromRGB(255, 255, 255)
cerrar.Font = Enum.Font.FredokaOne
cerrar.TextScaled = true
cerrar.Text = "X"
cerrar.Parent = panel
local cc2 = Instance.new("UICorner")
cc2.CornerRadius = UDim.new(0, 10)
cc2.Parent = cerrar
cerrar.Activated:Connect(function()
	panel.Visible = false
end)

local lista = Instance.new("Frame")
lista.Name = "Lista"
lista.Position = UDim2.new(0, 12, 0, 54)
lista.Size = UDim2.new(1, -24, 1, -66)
lista.BackgroundTransparency = 1
lista.Parent = panel
local uil = Instance.new("UIListLayout")
uil.Padding = UDim.new(0, 8)
uil.Parent = lista

misionesBtn.Activated:Connect(function()
	panel.Visible = not panel.Visible
end)

local function renderMisiones(list)
	for _, c in ipairs(lista:GetChildren()) do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	for _, m in ipairs(list) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 62)
		row.BackgroundColor3 = Color3.fromRGB(38, 40, 50)
		row.Parent = lista
		local rc = Instance.new("UICorner")
		rc.CornerRadius = UDim.new(0, 10)
		rc.Parent = row

		local nm = Instance.new("TextLabel")
		nm.Size = UDim2.new(1, -12, 0, 26)
		nm.Position = UDim2.new(0, 8, 0, 4)
		nm.BackgroundTransparency = 1
		nm.Font = Enum.Font.GothamBold
		nm.TextColor3 = Color3.fromRGB(255, 255, 255)
		nm.TextScaled = true
		nm.TextXAlignment = Enum.TextXAlignment.Left
		nm.Text = m.nombre .. "  (+$" .. m.recompensa .. ")"
		nm.Parent = row

		local barBg = Instance.new("Frame")
		barBg.Size = UDim2.new(1, -96, 0, 16)
		barBg.Position = UDim2.new(0, 8, 0, 36)
		barBg.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
		barBg.Parent = row
		local bbc = Instance.new("UICorner")
		bbc.CornerRadius = UDim.new(0, 8)
		bbc.Parent = barBg
		local fill = Instance.new("Frame")
		fill.Size = UDim2.new(math.clamp(m.progreso / m.objetivo, 0, 1), 0, 1, 0)
		fill.BackgroundColor3 = Color3.fromRGB(95, 220, 120)
		fill.Parent = barBg
		local fc = Instance.new("UICorner")
		fc.CornerRadius = UDim.new(0, 8)
		fc.Parent = fill

		local rec = Instance.new("TextButton")
		rec.AnchorPoint = Vector2.new(1, 1)
		rec.Position = UDim2.new(1, -6, 1, -6)
		rec.Size = UDim2.new(0, 80, 0, 26)
		rec.Font = Enum.Font.FredokaOne
		rec.TextScaled = true
		rec.TextColor3 = Color3.fromRGB(255, 255, 255)
		rec.Parent = row
		local rcc = Instance.new("UICorner")
		rcc.CornerRadius = UDim.new(0, 8)
		rcc.Parent = rec
		if m.reclamada then
			rec.Text = "✓"
			rec.BackgroundColor3 = Color3.fromRGB(60, 80, 60)
		elseif m.reclamable then
			rec.Text = Locale.get("claim")
			rec.BackgroundColor3 = Color3.fromRGB(70, 170, 90)
			rec.Activated:Connect(function()
				Net.event("ClaimMission"):FireServer(m.id)
			end)
		else
			rec.Text = m.progreso .. "/" .. m.objetivo
			rec.BackgroundColor3 = Color3.fromRGB(60, 64, 78)
		end
	end
end

Net.event("MissionState").OnClientEvent:Connect(renderMisiones)
