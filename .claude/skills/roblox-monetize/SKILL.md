---
name: roblox-monetize
description: Agregar un gamepass o developer product a un juego de Roblox de forma server-authoritative (prompt nativo, validación, idempotencia, efecto aplicado en el servidor). Úsala cuando quieras vender algo por Robux. Construir DESHABILITADO hasta que la retención esté probada.
---

# Agregar monetización (gamepass o developer product)

Roblox se queda el **30%** (cobrá pensando `neto = precio * 0.7`). Evitá pases de < 25 R$ (la comisión los vuelve inútiles). Usá SIEMPRE el prompt **nativo** de Roblox, nunca UI de pago propia.

## Gamepass (compra permanente: x2 dinero, VIP, auto-cobro)
1. Creá el gamepass en la web de creador y guardá su ID en `Config` (ej. `Config.Gamepasses.DobleDinero = 0`).
2. Prompt: `MarketplaceService:PromptGamePassPurchase(player, id)`.
3. Verificá posesión server-side al entrar y en `PromptGamePassPurchaseFinished`:
   `MarketplaceService:UserOwnsGamePassAsync(userId, id)` (envolvé en `pcall`, cacheá el resultado por jugador).
4. Aplicá el efecto en el SERVIDOR (ej. multiplicar el ingreso en `TycoonService`). Nunca confíes en que el cliente diga "tengo el pase".

## Developer Product (compra repetible: boost 15 min, cofre de plata, pack de inicio)
1. ID en `Config.Productos.X`.
2. Prompt: `MarketplaceService:PromptProductPurchase(player, id)`.
3. **UN solo** `MarketplaceService.ProcessReceipt` en un Script de `ServerScriptService` que maneje todos los productos.
4. **Idempotencia**: guardá los `PurchaseId` ya procesados en ProfileStore; si ya está, devolvé `Enum.ProductPurchaseDecision.PurchaseGranted` sin volver a otorgar. Si falla el guardado, devolvé `NotProcessedYet` (Roblox reintenta).

## Qué vender en un tycoon (sin pay-to-win agresivo)
- Gamepass **x2 Dinero** (~199 R$) — el más vendido. Mantenelo en x2, no x5.
- Gamepass **Auto-Cobro** (~149 R$) — saca la tarea repetitiva en celular.
- Gamepass **VIP** (~499 R$) — tag de chat + skin visible + zona VIP. Status, no poder.
- Producto **Pack de Inicio** (una vez) — convierte free → primer pagador.
- **Skins de colectivo** — ingreso limpio, sin pay-to-win, FOMO por temporada.

## Requisitos para COBRAR plata real (DevEx)
La cuenta que publica debe ser 13+ con ID verificado, 30+ días de antigüedad, email verificado, y necesitás **30.000 Robux** acumulados para el primer retiro. Nada de esto bloquea construir/probar: solo el retiro.

## Importante
- Construí el código de compra AHORA pero dejalo **deshabilitado** hasta tener retención.
- La retención ES monetización: Creator Rewards paga por jugadores activos con sesiones de 10+ min.
