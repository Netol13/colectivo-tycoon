---
name: roblox-mechanic
description: Crear una mecánica nueva server-authoritative en un juego de Roblox (rebirth, misiones, robo, mascotas, upgrades) siguiendo los patrones del proyecto Colectivo Tycoon. Úsala cuando agregues cualquier sistema de juego nuevo.
---

# Crear una mecánica server-authoritative

Seguí estos pasos para que la mecánica sea segura (el servidor manda, el cliente solo pide) y consistente con el resto del proyecto.

## 1. Datos (si persiste entre sesiones)
- Agregá el/los campo(s) en `src/server/DataManager.luau`, en `PROFILE_TEMPLATE` **y** en `defaultData()`.
- `profile:Reconcile()` ya completa el campo en jugadores viejos, no hace falta migración.

## 2. Config (los números)
- Precios, valores, tiempos y cantidades van SIEMPRE en `src/shared/Config.luau`. Nunca hardcodees números en la lógica.

## 3. Red (si el cliente pide algo)
- Agregá el nombre del RemoteEvent al array `EVENTS` de `src/shared/Net.luau`.
- Convención: `RequestX` (cliente → servidor), `XFX` / `XState` (servidor → cliente).

## 4. Servicio del servidor
- Creá `src/server/XService.luau` (ModuleScript) con una función `.start()` que conecta `Net.event("RequestX").OnServerEvent`.
- Dentro del handler, SIEMPRE en este orden:
  1. `local state = PlayerState.get(player)` → `if not state then return end`.
  2. **Validá TODO server-side**: que pueda, que le alcance, que no lo tenga ya. Nunca confíes en el cliente.
  3. Aplicá el efecto sobre `state.data` / `state.plata`.
  4. `Stats.update(player)` para refrescar meta y HUD.
  5. Avisá al cliente: `Net.event("XFX"):FireClient(player, ...)` para disparar los efectos.
- Importá el servicio y llamá `XService.start()` en `src/server/ServerMain.server.luau`.

## 5. Estado visible (HUD)
- Si el HUD muestra un dato, NO mandes texto por remote: seteá un ATRIBUTO en el player desde `src/server/Stats.luau` y leelo en el cliente con `player:GetAttribute(...)` + `GetAttributeChangedSignal`. Es más robusto (no se pierde si el cliente aún no escuchaba).

## 6. Cliente
- En `src/client/ClientMain.client.luau`, conectá `Net.event("XFX").OnClientEvent` a los efectos (`Juice`, `Audio`, `Hud`).
- Botones: disparan `Net.event("RequestX"):FireServer(idMinimo)` con datos MÍNIMOS (un id, nunca el precio ni la cantidad de plata).

## 7. Textos
- Todo texto visible va en `src/shared/Locale.luau` (clave en `es` y en `en`). El servidor manda la CLAVE en `Notify`; el cliente traduce con `Locale.get(clave, ...)`.

## Antipatrones (evitar)
- ❌ Que el cliente mande el precio, la cantidad o el resultado.
- ❌ Loops de generación o conexiones `.Touched` del lado del cliente.
- ❌ Strings de UI hardcodeados (rompe el bilingüe).
