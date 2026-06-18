# Colectivo Tycoon — Roadmap y decisiones

Basado en una investigación de los juegos top de Roblox 2025-2026 (Grow a Garden,
Steal a Brainrot, Pet Sim 99, etc.) y sus mecánicas de enganche, retención,
efectos y monetización. Resumen para vos y tu amigo.

## 🧭 Veredicto del concepto

**Mantener el tema "colectivos", sumarle el gancho social de ROBAR.**

Los juegos que explotaron no ganaron por el tema, sino por una **capa social
robable que se graba sola para TikTok**. Steal a Brainrot (récord: 25M de
jugadores a la vez) le ganó a Grow a Garden siendo *más simple*: comprás algo que
genera plata en una cinta y otros te lo pueden robar. Esa tensión es el producto.

El "colectivo" es un buen disfraz: universal (cualquier nene entiende que un bus
levanta pasajeros y gana plata = cero explicación, ideal para celular y para
ES/EN), reconocible y memeable. **No hay que cambiar el tema, hay que agregarle el
gancho.**

El esqueleto que ya teníamos (droppers = ingreso pasivo, terminal = la cinta,
ProfileStore, server-authoritative) era el 90%. Lo que faltaba era el **gancho
emocional** y el **"juice"**, no más profundidad de tycoon.

## ✅ Implementado en esta tanda

Todo esto ya está en el código y andando:

- **Más contenido y mejor curva:** 6 líneas con curva de precios suave (victorias
  tempranas frecuentes = hábito), no 3 que se terminan.
- **Juice (efectos):** numeritos "+$X" que saltan al cobrar, confeti al comprar,
  golpe de escala en botones, flash de celebración al renovar, conteo animado de
  la plata. Todo en `src/client/Juice.luau`.
- **Audio:** sonido de caja registradora al cobrar (sube de tono con la racha),
  sonido de compra, SoundGroups de Música/SFX. En `src/client/Audio.luau`.
  *(Algunos IDs hay que reemplazarlos por sonidos del Creator Store — ver Config.)*
- **Rebirth "Renovar Flota":** el loop infinito. Cuando tenés todas las líneas y
  juntás la plata mínima, reiniciás por un +25% permanente. `RebirthService`.
- **Recompensa diaria:** racha de 7 días que crece. `DailyService`.
- **Ganancias offline:** "mientras no estabas ganaste $X" al volver. `OfflineService`.
- **Evento "Hora Pico":** cada 10 min, ingresos x3 por 2 min con pasajes dorados
  (FOMO). `EventService`.
- **HUD mobile-first:** plata grande arriba, plata/min, meta actual ("Meta:
  comprá Línea 2"), botón de renovar en la zona del pulgar. `src/client/Hud.luau`.
- **Onboarding:** brillo verde en los botones comprables + meta siempre visible.
- **Bilingüe ES/EN:** detecta el idioma del jugador. `src/shared/Locale.luau`.
- **Balance centralizado:** todo en `src/shared/Config.luau`.

## 🔜 Lo más importante que falta: la capa de ROBO

Es el gancho viral y por eso es la próxima gran feature. **No la hice de noche a
propósito** porque necesita pruebas multijugador reales (dos jugadores en el mismo
servidor), y eso conviene hacerlo con vos despierto para testear juntos.

Diseño propuesto:
- Cuando un colectivo llega a la terminal cargado de plata, si no cobrás a tiempo,
  **otro jugador puede interceptarlo y robar parte** (ProximityPrompt con tiempo
  de "mantener apretado" = tensión, momento grabable).
- Comprás **defensas** (inspector de boletos, barrera) y **ofensiva** (gancho para
  robar más rápido).
- Un `BillboardGui` muestra cuánta plata lleva cada colectivo = la carnada visible.

## 🗺️ Roadmap priorizado (lo que sigue, por impacto)

| Prioridad | Mejora | Por qué |
|-----------|--------|---------|
| 1 | Capa de **robo + defensas** | El gancho viral, lo que se graba para TikTok |
| 2 | **Misiones diarias** (3-5 rotativas) | Metas claras = retención D7 |
| 3 | **Skins de colectivo** | Vitrina visible + base de monetización limpia |
| 4 | **Leaderboard entre servidores** (semanal) | Competencia + viralidad |
| 5 | **Sonidos faltantes** del Creator Store | Cerrar el feedback de audio |
| 6 | **Mover visuales de pasajes al cliente** | Performance en celular bajo carga |
| 7 | **Códigos canjeables** | "seguinos para códigos" = marketing gratis |
| 8 | **Monetización** (ver skill `roblox-monetize`) | Recién cuando la retención esté probada |

## 💰 Monetización (para más adelante)

Diseñar los hooks ahora, activarlos cuando haya retención. Roblox se queda el 30%.
Lo que vende en tycoons: gamepass **x2 dinero** (~199 R$, el más vendido),
**auto-cobro** (~149 R$), **VIP** (skin visible + status), **pack de inicio** y
**skins**. Para cobrar plata real (DevEx): cuenta 13+, ID verificado, 30 días de
antigüedad y 30.000 Robux acumulados para el primer retiro. Detalle en la skill
`roblox-monetize`.

## 🛠️ Skills de Claude Code creadas

En `.claude/skills/` (las tienen los dos al clonar el repo):
`roblox-mechanic`, `roblox-juice`, `roblox-audio`, `roblox-monetize`,
`roblox-mobile-ui`, `roblox-i18n`, `roblox-audit`. Se invocan escribiendo
`/roblox-...` y guían cómo agregar cada cosa siguiendo los patrones del proyecto.
