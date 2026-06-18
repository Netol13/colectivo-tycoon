--!strict
-- Theme.luau  (ReplicatedStorage.Theme)
-- Paleta y materiales del juego en UN solo lugar. Todo lo que se construye lee
-- de acá, así el mundo se ve "dirigido" y no un arcoíris random de grises.
-- Regla: máximo ~5 colores fuertes en pantalla; el resto son tonos de estos.

local Theme = {}

Theme.Palette = {
	Asphalt = Color3.fromRGB(38, 40, 46), -- calles, piso de la pista
	Concrete = Color3.fromRGB(120, 122, 130), -- base del plot, paredes
	Curb = Color3.fromRGB(225, 228, 235), -- cordones, bordes claros
	Hero = Color3.fromRGB(230, 96, 38), -- el naranja de la marca, más vivo
	Sky = Color3.fromRGB(86, 170, 230), -- celeste
	Cash = Color3.fromRGB(95, 220, 120), -- verde plata
	Gold = Color3.fromRGB(255, 205, 70), -- dorado / eventos
	Dark = Color3.fromRGB(28, 28, 34), -- cuerpos de botones, acentos oscuros
	Grass = Color3.fromRGB(120, 170, 95), -- pasto del mundo
	Wood = Color3.fromRGB(110, 78, 50), -- troncos
	Leaf = Color3.fromRGB(86, 156, 84), -- copas de árboles
}

Theme.Mat = {
	Road = Enum.Material.Asphalt,
	Wall = Enum.Material.Concrete,
	Metal = Enum.Material.Metal,
	Glass = Enum.Material.Glass,
	Ground = Enum.Material.Grass,
	Glow = Enum.Material.Neon,
	Plastic = Enum.Material.SmoothPlastic,
	Wood = Enum.Material.Wood,
}

return Theme
