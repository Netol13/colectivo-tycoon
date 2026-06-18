---
name: roblox-juice
description: Agregar "juice" (efectos visuales satisfactorios) a un evento del juego usando el módulo central src/client/Juice.luau. Numeritos flotantes, confeti, golpes de escala, celebraciones, sacudidas, con cap para celular. Úsala cuando un evento se sienta "seco" o quieras más dopamina visual.
---

# Agregar juice a un evento

Todo el juice vive en `src/client/Juice.luau`. Reusá esas funciones; no escribas efectos sueltos por todos lados.

## Funciones disponibles
- `Juice.popNumber(worldPos, text, color?)` — numerito "+$X" que sube y se desvanece (posición del mundo).
- `Juice.punch(guiObject)` — golpe de escala que rebota (botones al tocar).
- `Juice.shake(guiObject)` — sacudida (errores, "no te alcanza").
- `Juice.burst(worldPos, color?)` — estallido de partículas (compra, logro).
- `Juice.celebrate()` — flash blanco de pantalla completa (rebirth, hito).
- `Juice.countUp(setter, from, to, dur?)` — anima un número subiendo en vez de saltar.

## Cómo conectarlo
1. El SERVIDOR avisa del evento con un RemoteEvent (ver skill `roblox-mechanic`). Si el efecto es en 3D, manda la POSICIÓN del mundo.
2. En `src/client/ClientMain.client.luau`, dentro del handler `OnClientEvent`, llamá la función de Juice.
3. Combiná SIEMPRE visual + sonido (skill `roblox-audio`): cada sonido necesita gemelo visual porque muchos juegan en silencio.

## Reglas mobile (importante)
- Partículas: < 200 simultáneas, lifetime 2–4 s, siempre `Emit()` one-shot (nunca `Enabled = true` permanente). `Juice.burst` ya baja el conteo en celular.
- Debris-limpiá todo lo que crees (Juice ya lo hace).
- Camera shake SOLO en eventos raros (rebirth/robo), nunca en cobros rutinarios (marea en celular).

## Qué efecto para qué evento
- Feedback de UI (botón) → `punch` (éxito) / `shake` (error).
- Ganancia de plata en el mundo → `popNumber` + `burst` chico.
- Hito grande (rebirth) → `celebrate` + `burst` grande + `Audio.milestone()`.
- Número del HUD que cambia → `countUp` (ya lo usa `Hud.setCash`).
