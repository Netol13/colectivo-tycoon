# Colectivo Tycoon 🚌

Juego de Roblox tipo **Tycoon de colectivos**, hecho entre dos. Comprás líneas
de colectivo que generan pasajes → los pasajes llegan a la terminal → te dan
plata → comprás más líneas. El loop clásico de tycoon.

El código vive en archivos `.luau` (texto) que **Rojo** sincroniza con Roblox
Studio y **Git/GitHub** comparte entre las dos máquinas. Así los dos podemos
editar el juego (incluso con ayuda de Claude/IA) sin pisarnos.

---

## 📁 Cómo está organizado

```
colectivo-tycoon/
├─ default.project.json   # le dice a Rojo qué carpeta va a cada servicio de Roblox
├─ rokit.toml             # fija las versiones de las herramientas (Rojo, StyLua)
├─ stylua.toml            # estilo de formateo del código
├─ .gitignore             # qué NO se sube a git (los .rbxl, etc.)
└─ src/
   ├─ server/   → ServerScriptService  (la lógica, manda el servidor)
   │   ├─ ServerMain.server.luau  ← arranca todo cuando entra un jugador
   │   ├─ PlotBuilder.luau        ← construye el plot por código
   │   ├─ TycoonService.luau      ← genera pasajes y los cobra en la terminal
   │   ├─ PurchaseService.luau    ← maneja la compra de líneas nuevas
   │   ├─ DataManager.luau        ← guarda la plata y las líneas (ProfileStore)
   │   └─ ProfileStore.luau       ← módulo de terceros para guardar datos
   ├─ shared/   → ReplicatedStorage (lo ven cliente y servidor)
   │   └─ Config.luau             ← ⭐ PRECIOS Y VALORES: tocá esto para balancear
   └─ client/   → StarterPlayerScripts (solo lo ve cada jugador)
       └─ HudClient.client.luau   ← muestra la plata en pantalla
```

> **Regla de oro:** el código se edita **en los archivos** (VS Code / Claude),
> NUNCA dentro de Studio. Studio es solo para ver y probar el juego.

---

## 🛠️ Setup desde cero (una vez por máquina)

Hacé esto la primera vez en tu compu. Sirve igual para Santino y para el amigo.

### 1. Programas base
- **Roblox Studio** → descargalo de https://create.roblox.com/ (necesitás cuenta de Roblox).
- **VS Code** → https://code.visualstudio.com/
- **Git** → https://git-scm.com/download/win

### 2. Rokit (el que instala Rojo)
Abrí **PowerShell** y pegá:
```powershell
Invoke-RestMethod https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.ps1 | Invoke-Expression
```
**Cerrá y volvé a abrir la terminal** (para que tome el cambio de PATH).

### 3. Bajar el proyecto e instalar las herramientas
```powershell
git clone <URL-DEL-REPO-EN-GITHUB> D:\colectivo-tycoon
cd D:\colectivo-tycoon
rokit install          # instala Rojo y StyLua en las versiones del rokit.toml
rojo plugin install    # instala el plugin de Rojo dentro de Studio (una vez)
```

### 4. Extensiones de VS Code (recomendado)
- **`JohnnyMorganz.luau-lsp`** → autocompletado y tipos de Luau.
- **`JohnnyMorganz.stylua`** → formatea el código al guardar.

En la config de VS Code activá:
- `luau-lsp.sourcemap.enabled: true`
- `luau-lsp.sourcemap.rojoProjectFile: "default.project.json"`

---

## ▶️ Cómo trabajar y probar (el día a día)

1. En la carpeta del proyecto, levantá Rojo:
   ```powershell
   rojo serve
   ```
2. Abrí **Roblox Studio** con un lugar nuevo (Baseplate o vacío).
3. En la barra de Studio, botón **Rojo → Connect**. Listo: ahora todo lo que
   cambies en los archivos aparece en Studio al instante.
4. Editá los scripts en VS Code (o con Claude). Al guardar, Studio se actualiza.
5. Apretá **Play (F5)** para probar: vas a aparecer en tu plot, los pasajes
   empiezan a generarse, caen a la terminal y la plata sube. Comprá la Línea 2
   parándote sobre el botón y haciéndole click.

> Si **Connect** falla: fijate que `rojo serve` esté corriendo, y que el plugin
> y el CLI sean los dos versión 7. La primera vez Windows puede pedir permitir
> `rojo.exe` en el firewall (red privada): aceptá.

---

## 👥 Colaborar entre los dos sin pisarse

El código se comparte por **GitHub**. Reglas simples para no chocar:

- **Antes de empezar**, siempre traé lo último:
  ```powershell
  git checkout main
  git pull
  ```
- **Trabajá en una rama**, nunca directo en `main`:
  ```powershell
  git checkout -b mi-cambio
  # ...editás, probás en Studio...
  git add .
  git commit -m "Que hice"
  git push -u origin mi-cambio
  ```
  Después abrís un **Pull Request** en GitHub, el otro lo revisa y lo mergea.
- **Repartirse archivos:** si cada uno toca archivos distintos, git nunca tiene
  conflictos. Sugerencia inicial:
  - Santino → `src/server/` (la lógica del tycoon)
  - El amigo → `src/client/` (la interfaz / HUD)
  - `src/shared/Config.luau` → avisarse antes de tocarlo los dos a la vez.
- Después de un merge, los dos hacen `git checkout main && git pull`.

### ⚠️ Lo más importante de entender
Rojo y Git versionan **solo los scripts**. Lo que dibujes a mano en Studio
(modelos, mapas, GUIs arrastradas) **NO** se guarda en git. Por eso este juego
construye el plot **por código** (ver `PlotBuilder.luau`): así, cuando hacés
`git pull`, tenés exactamente el mismo juego que el otro, sin tener que pasarse
archivos `.rbxl`.

Más adelante, si quieren modelos lindos de colectivos hechos a mano, se usa
**Team Create** (edición en la nube de Studio) para esos modelos, y se siguen
manejando los scripts por Rojo/Git.

---

## 🚀 Jugar juntos (de verdad, en red)

`rojo serve` es para probar uno solo en su Studio. Para jugar los dos al mismo
servidor:
1. En Studio, con Rojo conectado: **File → Publish to Roblox** (la primera vez
   creás el lugar; las siguientes, "Publish").
2. Abran el juego desde la app de Roblox y únanse al mismo servidor.

Recién ahí el guardado (ProfileStore) persiste de verdad en la nube.

---

## ⚙️ Balancear el juego

Casi todo lo que vas a querer cambiar está en **`src/shared/Config.luau`**:
precio de cada línea, cuánta plata da cada pasaje, cada cuánto se generan. Para
agregar una **Línea 4**, copiá un bloque del array `Config.Lineas` y agregá un
carril en `LANE_X` dentro de `PlotBuilder.luau`.

---

## 🧰 Comandos útiles

| Comando | Qué hace |
|---|---|
| `rojo serve` | Sincroniza los archivos con Studio en vivo |
| `rojo build -o juego.rbxl` | Arma un archivo de lugar desde el código |
| `rokit install` | Instala/actualiza las herramientas del proyecto |
| `stylua src` | Formatea todo el código |
| `stylua --check src` | Revisa formato y que todo parsee bien |
