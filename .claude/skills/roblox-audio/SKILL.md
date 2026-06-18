---
name: roblox-audio
description: Agregar un sonido a un evento usando src/client/Audio.luau y los SoundGroups. Sonidos del Creator Store, con variación de tono, debounce y gemelo visual. Úsala cuando quieras feedback sonoro (cobro, compra, error, hito, música).
---

# Agregar un sonido

El audio vive en `src/client/Audio.luau` (SoundGroups Music/SFX, debounce, variación de tono). Los IDs están en `Config.Audio`.

## Pasos
1. Conseguí el sonido del **Creator Store** (en Studio: Toolbox → Creator Store → Audio). Insertarlo desde ahí deja el `SoundId` con permisos válidos en la experiencia. **No pegues IDs de foros**: desde 2022 son privados por defecto y no suenan.
2. Poné el ID en `src/shared/Config.luau` → `Config.Audio` (Collect / Buy / Error / Milestone / Music, o uno nuevo).
3. Si es un tipo nuevo, agregá una función en `Audio.luau` copiando `Audio.buy` como molde: llama a `play(Config.Audio.X, pitch?)`.
4. Llamala desde el handler del evento en `ClientMain.client.luau`, junto al efecto visual (skill `roblox-juice`).

## Reglas
- Cada sonido necesita un **gemelo visual** (muchos chicos juegan en silencio; el switch de iOS mutea Roblox entero).
- Tres niveles: cobro rutinario = tick corto; compra = ka-ching; hito/rebirth = fanfarria de 1–2 s.
- El cobro sube de tono con la racha (ya está en `Audio.collect`).
- UI/feedback = 2D (en SoundService). Zumbido de una máquina = 3D (Sound dentro del Part).
- `Config.Audio.X = ""` → ese sonido no suena, sin romper nada (útil mientras no tengas el ID).
