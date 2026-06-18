---
name: roblox-i18n
description: Registrar textos de UI en español e inglés en el juego. Úsala cada vez que agregues un texto visible al jugador. El servidor manda claves, el cliente traduce con src/shared/Locale.luau.
---

# Textos bilingües (ES/EN)

Todo texto que ve el jugador pasa por `src/shared/Locale.luau`. El cliente detecta el idioma (`player.LocaleId`) y elige la tabla.

## Agregar un texto
1. En `src/shared/Locale.luau`, agregá la clave en las DOS tablas (`es` y `en`) con el MISMO nombre:
   ```lua
   es = { mi_clave = "Comprá %s ahora" },
   en = { mi_clave = "Buy %s now" },
   ```
   Usá `%s` / `%d` para los valores dinámicos (van por `string.format`).
2. En el cliente, mostralo con `Locale.get("mi_clave", arg1, arg2)`.

## Mensajes del servidor (Notify)
- El servidor NO traduce: manda la CLAVE + los args por el remote `Notify`:
  ```lua
  Net.event("Notify"):FireClient(player, "mi_clave", "good", valor)
  ```
- El cliente ya hace `Hud.notify(Locale.get(key, ...), kind)` (en `ClientMain.client.luau`). No toques eso.
- Si un arg es plata/número grande, formatealo en el servidor con `Format.money(n)` antes de mandarlo (así llega listo: "$1.2K").

## Datos para el HUD (no texto)
- Si es un número/estado (no una frase), NO lo mandes como texto: usá un ATRIBUTO del player (ver skill `roblox-mechanic`) y armá la frase en el cliente con `Locale.get`.

## Reglas
- NUNCA escribas un string en español (o inglés) directo en el código de UI.
- Si una clave existe en `es` pero falta en `en`, `Locale.get` cae a `es` como fallback (no rompe, pero completá las dos).
- Nombres propios cortos ("Línea 2") pueden ir como arg sin traducir.
