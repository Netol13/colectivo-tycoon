--!strict
-- StepPad.luau  (ServerScriptService.StepPad)
-- Helper para "pisar pads": cuando el DUEÑO del plot camina sobre un pad, se
-- dispara la acción (comprar, cobrar). Con debounce para que no se dispare mil
-- veces por frame. Reemplaza los clicks por pisar (estilo tycoon clásico).

local Players = game:GetService("Players")

local StepPad = {}

function StepPad.onStep(pad: BasePart, owner: Player, callback: () -> ())
	local busy = false
	pad.Touched:Connect(function(hit: BasePart)
		if busy then
			return
		end
		local char = hit.Parent
		if not char then
			return
		end
		local plr = Players:GetPlayerFromCharacter(char)
		if plr ~= owner then
			return -- solo el dueño dispara su propio pad
		end
		busy = true
		callback()
		task.wait(0.4)
		busy = false
	end)
end

return StepPad
