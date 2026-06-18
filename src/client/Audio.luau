--!strict
-- Audio.luau  (cliente)
-- Reproduce los sonidos del juego. Usa SoundGroups (Música / SFX) para poder
-- subir o bajar cada categoría por separado. El sonido de cobro sube de tono
-- con cada cobro seguido (racha) = más satisfacción (truco de los simuladores).
--
-- IMPORTANTE: en celular muchos chicos juegan en silencio (el switch de iOS
-- mutea el audio de Roblox). Por eso TODO sonido tiene un gemelo visual (Juice).

local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Config = require(ReplicatedStorage:WaitForChild("Config"))

local Audio = {}

local sfxGroup = Instance.new("SoundGroup")
sfxGroup.Name = "SFX"
sfxGroup.Volume = 0.7
sfxGroup.Parent = SoundService

local musicGroup = Instance.new("SoundGroup")
musicGroup.Name = "Music"
musicGroup.Volume = 0.25
musicGroup.Parent = SoundService

local lastPlay: { [string]: number } = {}

local function play(id: string, pitch: number?)
	if id == "" then
		return -- sonido no configurado: no suena (el efecto visual cubre)
	end
	local now = os.clock()
	if now - (lastPlay[id] or 0) < 0.05 then
		return -- debounce: no más de ~20 del mismo por segundo
	end
	lastPlay[id] = now

	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.SoundGroup = sfxGroup
	sound.PlaybackSpeed = pitch or (1 + (math.random() - 0.5) * 0.08) -- ±4% de variación
	sound.Parent = SoundService
	sound:Play()
	Debris:AddItem(sound, 5)
end

-- Racha de cobro: el tono trepa con cobros seguidos y se reinicia tras 1.5s.
local streak = 0
local lastCollect = 0

function Audio.collect()
	local now = os.clock()
	if now - lastCollect < 1.5 then
		streak = math.min(streak + 1, 10)
	else
		streak = 0
	end
	lastCollect = now
	play(Config.Audio.Collect, 1 + math.min(streak * 0.06, 0.6))
end

function Audio.buy()
	play(Config.Audio.Buy, 1.15)
end

function Audio.error()
	play(Config.Audio.Error, 1)
end

function Audio.milestone()
	play(Config.Audio.Milestone, 1)
end

function Audio.setSfxVolume(v: number)
	sfxGroup.Volume = math.clamp(v, 0, 1)
end

function Audio.setMusicVolume(v: number)
	musicGroup.Volume = math.clamp(v, 0, 1)
end

function Audio.startMusic()
	if Config.Audio.Music == "" then
		return
	end
	local music = Instance.new("Sound")
	music.SoundId = Config.Audio.Music
	music.Looped = true
	music.SoundGroup = musicGroup
	music.Parent = SoundService
	music:Play()
end

return Audio
