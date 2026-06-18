---
name: roblox-audit
description: Pasada de seguridad y performance sobre el código de Roblox. Detecta remotes que confían en el cliente, falta de validación, loops por jugador, partículas sin tope y guardados en cada tick. Úsala antes de publicar o de tocar economía/Robux.
---

# Auditoría de seguridad y performance

Revisá el código contra esta checklist. Reportá cada hallazgo con archivo, severidad y fix. (En este proyecto, podés correr `stylua --check src` para sintaxis; esto es para BUGS y RIESGOS que el formateador no ve.)

## Seguridad (server-authoritative)
- [ ] ¿Algún `RemoteEvent` confía en datos del cliente? El cliente solo manda INTENCIÓN (un id), nunca precio, cantidad ni resultado.
- [ ] ¿Cada `OnServerEvent` valida con `typeof()` los argumentos y chequea rangos? Un exploiter puede mandar cualquier cosa.
- [ ] ¿La plata, los precios y "lo que posee" viven SOLO en el servidor (ProfileStore / leaderstats escritos por el server)?
- [ ] ¿Las compras validan: le alcanza + no lo tiene ya + es el dueño quien clickea?
- [ ] ¿Hay rate-limit por jugador en los remotes spameables? (cooldown con `os.clock()`).
- [ ] ¿`ProcessReceipt` es idempotente (guarda `PurchaseId` procesados)?

## Correctness (bugs de runtime)
- [ ] ¿Se lee alguna propiedad de un Instance DESPUÉS de `:Destroy()`? Capturá el valor antes.
- [ ] ¿Una línea empieza con `(` justo después de otra expresión? Luau lo lee como llamada (bug silencioso). Usá variable intermedia.
- [ ] ¿`player:GetAttribute(x)` puede ser `nil` y se usa en `string.format`/math? Poné `or 0` / `or ""`.
- [ ] ¿El contrato cliente↔servidor coincide (orden y cantidad de args de cada remote)?
- [ ] ¿Doble conteo en `.Touched`? Usá un guard (atributo "Collected") + destruir.

## Performance (mobile manda)
- [ ] ¿Loops `while`/`Heartbeat` por jugador o por objeto que se acumulan? Preferí UNO global que recorra el estado.
- [ ] ¿Partículas con `Enabled = true` permanente? Usá `Emit()` one-shot con tope (< 200) y `Debris`.
- [ ] ¿Visuales (movimiento de partes decorativas) en el SERVIDOR? Mové lo cosmético al cliente; el server solo guarda el número.
- [ ] ¿Guardás en DataStore en cada tick/acción? Dejá que ProfileStore autosave; no fuerces saves seguidos.
- [ ] ¿Probaste en un teléfono real (o emulación de dispositivo en Studio)? La memoria es el límite.

## Salida
Por cada hallazgo: `archivo:ubicación — severidad (alto/medio/bajo) — qué rompe — fix concreto`.
