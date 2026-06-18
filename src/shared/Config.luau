--!strict
-- Config.luau  (ReplicatedStorage.Config)
-- ⭐ EL ARCHIVO QUE MAS VAS A TOCAR. Todo el balance del juego vive acá:
-- precios, cuánta plata da cada línea, ritmo, rebirth, recompensa diaria, etc.
-- Lo ven cliente y servidor, pero el SERVIDOR es el que valida (nadie hace
-- trampa cambiando esto desde el cliente).

local Config = {}

Config.Currency = {
	Name = "Plata",
	Starting = 0,
}

-- ── LINEAS DE COLECTIVO ────────────────────────────────────────────────
-- Cada línea es un dropper que genera pasajes (= plata). La Línea 1 viene
-- gratis y activa. Curva de precios SUAVE a propósito (×~2.3 por línea, no
-- ×10): las victorias tempranas frecuentes son las que enganchan.
Config.Lineas = {
	{
		Id = "Linea1",
		Nombre = "Línea 1",
		Precio = 0,
		ValorPasaje = 5,
		Intervalo = 1.5,
		Color = Color3.fromRGB(214, 84, 32),
	},
	{
		Id = "Linea2",
		Nombre = "Línea 2",
		Precio = 75,
		ValorPasaje = 11,
		Intervalo = 1.4,
		Color = Color3.fromRGB(40, 110, 200),
	},
	{
		Id = "Linea3",
		Nombre = "Línea 3",
		Precio = 220,
		ValorPasaje = 24,
		Intervalo = 1.3,
		Color = Color3.fromRGB(60, 170, 90),
	},
	{
		Id = "Linea4",
		Nombre = "Línea 4",
		Precio = 650,
		ValorPasaje = 52,
		Intervalo = 1.2,
		Color = Color3.fromRGB(200, 60, 70),
	},
	{
		Id = "Linea5",
		Nombre = "Línea 5",
		Precio = 1800,
		ValorPasaje = 110,
		Intervalo = 1.1,
		Color = Color3.fromRGB(150, 80, 200),
	},
	{
		Id = "Linea6",
		Nombre = "Línea 6",
		Precio = 5000,
		ValorPasaje = 240,
		Intervalo = 1.0,
		Color = Color3.fromRGB(240, 190, 40),
	},
}

-- ── REBIRTH ("Renovar Flota") ──────────────────────────────────────────
-- El loop infinito: reiniciás las líneas a cambio de un multiplicador
-- permanente. Es lo que evita que el juego "se termine" al comprar todo.
Config.Rebirth = {
	Nombre = "Renovar Flota",
	RequiereTodasLasLineas = true, -- hay que tener todas compradas
	PlataMinima = 12000, -- y juntar al menos esto
	BonusPorRenovacion = 0.25, -- +25% de ingresos permanente por cada renovación
}

-- ── RECOMPENSA DIARIA ──────────────────────────────────────────────────
-- Racha de 7 días. Volver cada día da cada vez más. Si faltás un día, vuelve
-- al día 1. Engancha por el "no quiero perder mi racha".
Config.Daily = {
	Recompensas = {
		{ plata = 150 },
		{ plata = 400 },
		{ plata = 1000 },
		{ plata = 2500 },
		{ plata = 6000 },
		{ plata = 15000 },
		{ plata = 40000 }, -- día 7: premio grande
	},
}

-- ── GANANCIAS OFFLINE ──────────────────────────────────────────────────
-- "Mientras no estabas, tus colectivos ganaron $X". Tira a volver cada día.
Config.Offline = {
	Factor = 0.4, -- 40% de lo que ganarías estando online
	CapHoras = 8, -- tope: máximo 8 horas de ganancia acumulada
}

-- ── EVENTO "HORA PICO" ─────────────────────────────────────────────────
-- Evento rotativo que multiplica ingresos por una ventana corta (FOMO).
Config.Evento = {
	Multiplicador = 3,
	DuracionSeg = 120, -- dura 2 minutos
	CadaSeg = 600, -- aparece cada 10 minutos
	TinteColor = Color3.fromRGB(255, 215, 0), -- pasajes dorados durante el evento
}

-- ── AUDIO ──────────────────────────────────────────────────────────────
-- IDs de sonido del Creator Store. El de cobro está verificado; los demás
-- conviene reemplazarlos insertando audio desde el Toolbox de Studio
-- (Creator Store > Audio) para que tengan permisos válidos en la experiencia.
-- Dejar "" = ese sonido no suena (el efecto visual igual se ve).
Config.Audio = {
	Collect = "rbxassetid://7112275565", -- "Cash Register Kaching" (verificado)
	Buy = "rbxassetid://7112275565", -- reusa el de cobro con otro tono; reemplazar
	Error = "", -- sonido de "no te alcanza" (agregar desde Toolbox)
	Milestone = "", -- fanfarria de rebirth (agregar desde Toolbox)
	Music = "", -- música de fondo en loop (agregar desde Toolbox)
}

return Config
