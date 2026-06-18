--!strict
-- Format.luau  (ReplicatedStorage.Format)
-- Abrevia numeros grandes para que se lean en un celular: 1240 -> "1.2K",
-- 3400000 -> "3.4M". Los telefonos no pueden con "1,240,000" y un numero
-- corto y legible se siente mas gratificante (mejor practica mobile de Roblox).

local Format = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc" }

-- 1500 -> "1.5K"
function Format.abbreviate(n: number): string
	n = math.floor(n)
	if n < 1000 then
		return tostring(n)
	end
	local idx = math.floor(math.log(n, 1000))
	idx = math.clamp(idx, 1, #SUFFIXES - 1)
	local scaled = n / (1000 ^ idx)
	local str: string
	if scaled < 100 then
		str = string.format("%.1f", scaled)
		str = (str:gsub("%.0$", "")) -- "5.0K" -> "5K"
	else
		str = tostring(math.floor(scaled))
	end
	return str .. SUFFIXES[idx + 1]
end

-- 1500 -> "$1.5K"
function Format.money(n: number): string
	return "$" .. Format.abbreviate(n)
end

return Format
