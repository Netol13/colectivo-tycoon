---
name: roblox-mobile-ui
description: Construir o refactorizar un elemento de UI para que sea seguro en celular (la mayoría de los jugadores de Roblox están en teléfono). Escala con la pantalla, lejos del joystick, texto legible. Úsala al crear cualquier UI nueva.
---

# UI segura para celular

La mayoría juega en teléfono. Una UI hecha para PC se rompe en celular. Reglas y patrones (mirá `src/client/Hud.luau` como ejemplo vivo).

## Tamaño y posición
- Usá `Size` con **Scale** o un mix Scale+Offset chico, no solo Offset (un botón de 200px se ve gigante o diminuto según el teléfono).
- `TextScaled = true` SIEMPRE en labels/botones, para que el texto se adapte. Si querés un piso/techo de tamaño, sumá un `UITextSizeConstraint`.
- Botones táctiles: mínimo ~50px de alto. Dedos, no mouse.

## Zonas del pulgar (clave)
- Joystick = abajo-IZQUIERDA. Botones de salto/acción = abajo-DERECHA. **No pongas botones importantes ahí encima.**
- Acciones primarias → abajo-derecha (como el botón Renovar Flota).
- Info (plata, meta) → arriba-centro.
- Paneles que se abren → centro, con un fondo semi-transparente.
- Respetá el notch/barra: el HUD principal usa `IgnoreGuiInset = false`; para fondos a pantalla completa usá `IgnoreGuiInset = true`.

## Legibilidad
- Números grandes abreviados (`Format.abbreviate`): "1.2K", no "1,240".
- Alto contraste: texto claro sobre fondo oscuro semi-transparente, con `UIStroke` para que se lea sobre cualquier escena.
- Fuente con peso (`Enum.Font.FredokaOne` / `GothamBold`).

## Feedback táctil
- En celular NO hay hover: el jugador no sabe si tocó. Dale `Juice.punch(boton)` en cada `Activated` (ver skill `roblox-juice`).
- Botón deshabilitado/sin plata → `Juice.shake` + color apagado.

## Antipatrones
- ❌ Posiciones 100% en Offset.
- ❌ Texto fijo en píxeles.
- ❌ Botones en la zona del joystick o del botón de salto.
- ❌ Texto hardcodeado (rompe el bilingüe; ver skill `roblox-i18n`).
