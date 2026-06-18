--!strict
-- Config.luau  (ReplicatedStorage.Config)
-- Tabla central de configuracion del Tycoon de colectivos.
-- Es lo PRIMERO que van a querer tocar para balancear el juego:
-- precios, cuanta plata da cada pasaje y cada cuanto se genera.
-- La ven tanto el servidor como el cliente, pero el servidor es el que
-- decide y valida (server-authoritative).

local Config = {}

-- Moneda que ve el jugador en el leaderboard (arriba a la derecha).
Config.Currency = {
	Name = "Plata",
	Starting = 0,
}

-- Cada "Linea" de colectivo es un dropper: genera pasajes que valen plata.
-- La Linea 1 viene gratis y arranca activa. Las demas se compran con un boton.
-- El orden del array define los carriles de izquierda a derecha en el plot.
Config.Lineas = {
	{
		Id = "Linea1",
		Nombre = "Linea 1",
		Precio = 0, -- gratis, activa de entrada
		ValorPasaje = 5, -- plata que da cada pasaje al llegar a la terminal
		Intervalo = 1.5, -- segundos entre cada pasaje
		Color = Color3.fromRGB(214, 84, 32), -- naranja
	},
	{
		Id = "Linea2",
		Nombre = "Linea 2",
		Precio = 50,
		ValorPasaje = 9,
		Intervalo = 1.3,
		Color = Color3.fromRGB(40, 110, 200), -- azul
	},
	{
		Id = "Linea3",
		Nombre = "Linea 3",
		Precio = 250,
		ValorPasaje = 18,
		Intervalo = 1.1,
		Color = Color3.fromRGB(60, 170, 90), -- verde
	},
}

return Config
