# Auditoría Técnica de Entornos Virtuales - "Inferno: El Descenso"

**Proyecto auditado:** `C:\Users\alexa\OneDrive\Escritorio\INFERNO_LIMBO_REFINADO`
**Fecha de re-auditoría:** 2026-11-17 (incluye el nuevo Círculo IX — Traición).
**Motor:** Godot 4.7 (config/features `4.7`, renderizador `GL Compatibility`), `project.godot` con escena principal `res://scenes/MenuPrincipal.tscn`, autoload `Game = *res://scripts/game_state.gd`, ventana 1280x720 con stretch `canvas_items`, gravedad 2D = 0. El nombre del proyecto ahora es **"INFERNO: EL DESCENSO — TRAICIÓN"**.
**Documento de escenario propio:** `TRAICION_ESCENARIO.md` (mapa `cocito.png` de 1448×1086, juramentos, almas, Lucifer).

**Nota estructural (verificada en código):** el proyecto **NO usa TileMap/TileSet, TileMapLayer, ParallaxBackground, luces 2D (PointLight2D/DirectionalLight2D/CanvasModulate) ni nodos de partículas de motor (CPUParticles2D/GPUParticles2D)**. Los mapas son ilustraciones PNG (mostradas con `Sprite2D`) y las colisiones/zonas transitables se resuelven **analíticamente en los scripts** (`Geometry2D` sobre rects/elipses en Limbo y Lujuria; `Geometry2D` sobre polígonos de nodos en Gula y Traición). El audio se instancia por código con `AudioStreamPlayer` (no `AudioStreamPlayer2D`) y **no hay buses de audio personalizados** (solo el bus Master por defecto; no existe `default_bus_layout.tres`).

---

## 1. Inventario de Escenas de Niveles / Círculos

| Escena | Ruta exacta | Estado actual |
| --- | --- | --- |
| **Limbo (Círculo I)** | `scenes/Limbo.tscn` | Completo y jugable: exploración sin combate, puzzle de 3 santuarios en orden, 2 diálogos de almas con decisión moral, puerta condicionada, audio ambiental, minimapa, guardado/checkpoint. |
| **Lujuria (Círculo II)** | `scenes/Lujuria.tscn` | Completo y jugable: combate activo (4 oleadas + jefe Minos), 3 sellos ordenados, viento ambiental que empuja, 2 almas con decisión, HUD con vida/boss bar, guardado. |
| **Gula (Círculo III)** | `scenes/Gula.tscn` | Completo y jugable: layout con polígonos editables, lodo que ralentiza, 2 ofrendas, 2 almas con decisión, jefe Cerbero, guardado (sin audio propio). Su pantalla final (`FinGula`) ahora enlaza directamente con **Traición**. |
| **Traición (Círculo IX) — NUEVO** | `scenes/Traicion.tscn` | Completo y jugable: lago Cocito con suelo y **hielo fino** editables como polígonos, 2 juramentos (sellos) que se rompen, 2 almas (Ugolino y Bocca) con decisión, jefe **Lucifer**, nieve procedural, guardado y final del descenso. |
| Menu Principal | `scenes/MenuPrincipal.tscn` | Pantalla de Control con `main_menu.gd`; incluye ahora un acceso directo **"Jugar Traición — Círculo IX"** (`_start_traicion()`). |
| Transición | `scenes/Transicion.tscn` | Pantalla de Control con `transicion.gd`; puente entre círculos. |
| Fin Limbo | `scenes/FinLimbo.tscn` | Pantalla final de círculo (`fin_limbo.gd`, UI por código). |
| Fin Lujuria | `scenes/FinLujuria.tscn` | Pantalla final de círculo (`fin_lujuria.gd`, UI por código). |
| Fin Gula | `scenes/FinGula.tscn` | Pantalla final de círculo (`fin_gula.gd`); el botón continuar llama `Game.enter_traicion()` y carga `Traicion.tscn`. |
| **Fin Traición — NUEVO** | `scenes/FinTraicion.tscn` | Pantalla final del juego (`fin_traicion.gd`, UI por código, anclada a pantalla completa). |
| HUD | `scenes/HUD.tscn` | Solo un `CanvasLayer` (layer 8) con `hud.gd`; toda la UI se construye por código. `configure_chapter()` soporta "limbo/lujuria/gula/traicion" (subtítulo "IX — TRAICIÓN"). |
| Dante (Limbo) | `scenes/Dante.tscn` | Player `CharacterBody2D` para exploración (sin combate). |
| Dante (combate) | `scenes/DanteLujuria.tscn` | Player `CharacterBody2D` con vida, esquiva, golpe y verso; reutilizado por Lujuria, Gula **y Traición**. |
| Enemigo genérico | `scenes/LujuriaEnemigo.tscn` | `CharacterBody2D` con `lujuria_enemigo.gd`; 5 arquetipos (diablillo, carcelero, espectro, furia, minos). |
| Interactivo | `scenes/LujuriaInteractivo.tscn` | `Node2D` visual/semántico (NPC, sello, puerta) con `lujuria_interactivo.gd`. |
| Proyectil | `scenes/LujuriaProyectil.tscn` | `Node2D` con `lujuria_proyectil.gd`; simulado sin capas de física; tiñe el proyectil enemigo de cian `Color("80e8ff")` cuando `world.name == "Traicion"`. |
| Cerbero | `scenes/GulaCerbero.tscn` | `Node2D` jefe con `gula_cerbero.gd` (mordida, aullido, zarpazo). |
| **Lucifer — NUEVO** | `scenes/TraicionLucifer.tscn` | `Node2D` jefe con `traicion_lucifer.gd` (3 patrones: aliento helado en abanico, quiebre de hielo, golpe cercano). |

**Pruebas nuevas:** `tests/traicion_smoke.gd` (carga, combate, decisiones, persistencia; se ejecuta con `godot --headless`) y `tests/traicion_geometry.cjs` (verifica dimensiones de imagen, suelo, abismo y rutas a los 6 marcadores; se ejecuta con Node). Documentadas en `TRAICION_ESCENARIO.md`.

---

## 2. Desglose Técnico por Círculo / Escenario

### CÍRCULO I — LIMBO (`scenes/Limbo.tscn` + `scripts/limbo.gd`)

#### A. Regla Ambiental y Scripts (.gd)
- **`scripts/limbo.gd`** (310 líneas, raíz `Node2D`): lógica del círculo completo.
  - **Regla ambiental:** círculo *sin combate* (`player.combat_enabled = false`). Validación de paso `can_walk()` con 9 puntos de muestreo (`COLLISION_SAMPLES`).
  - **Mecánica especial de salto:** `lake_jump_target()` permite cruzar los dos estanques elípticos (centros `(285,568)` y `(1253,568)`), solo en dirección vertical (`|dir.y| ≥ 0.88`), con aterrizaje a 225 px.
  - **Colisión analítica:** `_is_path()` combina 8 `Rect2` de caminos de piedra con elipses de estanques como sólidos y el polígono del monumento central (`monument_outline`, 15 vértices, con `Geometry2D.is_point_in_polygon`). Límites: x ∈ [16,1524], y ∈ [218,964].
  - **Puzzle:** activación ordenada de 3 santuarios (`ORDER = ["altar_memoria","altar_saber","altar_compasion"]`); errores suman `puzzle_errors` y a los 2 errores Virgilio da la pista.
  - **Dilemas morales:** `_talk_to_soul()` / `Game.decide()` (Redención/Rigor); `_handle_door()` da veredicto según el balance y transita a Lujuria vía `Transicion.tscn`.
  - **Scripts de apoyo:** `dante.gd` (jugador, velocidad 196, dash 475), `hotspot.gd`, `particles.gd`, `gate_visual.gd`, `shadow.gd`, `minimap.gd`, `hud.gd`.
- **Sin física de colisiones estándar:** no hay `StaticBody2D`, `Area2D` ni `CollisionPolygon2D` de nivel.

#### B. Aspecto Visual y Nodos de Godot 4
- **Mapa:** sin TileMap. `Background` (`Sprite2D`, `z_index=-20`, filter lineal) con `res://assets/world/limbo_master.png`.
- **Fondo/Profundidad:** sin Parallax; profundidad por `z_index` (fondo -20, partículas 12, portal 2, jugador 6).
- **Iluminación y partículas:** sin nodos de luz ni partículas de motor:
  - **`Particles`** (`particles.gd`): 75 motas deterministas (semilla 7060), `draw_circle` color `Color(0.83,0.85,0.87,α)` α 0.11–0.26.
  - **`GateVisual`** (`gate_visual.gd`): niebla del portal `Color(0.050,0.063,0.083,0.94)`, arco `Color(0.72,0.82,0.87)` con glow pulsante `0.34+0.18·sin` y 6 orbes; solo visible con `open=true`.
  - **Tinte de círculo:** `CIRCLE_TINTS["limbo"] = "#9aa0a6"` (gris frío) en los hotspots.

#### C. Catálogo de Nodos y Objetos en la Escena

| Nodo (árbol real de Limbo.tscn) | Tipo | Función |
| --- | --- | --- |
| `Limbo` | Node2D + script | Raíz con `limbo.gd`. |
| `Background` | Sprite2D | Mapa ilustrado (limbo_master.png), z=-20. |
| `World` | Node2D | Contenedor de jugador y hotspots. |
| `World/Dante` | CharacterBody2D (Dante.tscn) | Spawn `(769,834)`, `combat_enabled=false`. |
| `World/[8 hotspots por código]` | Node2D + `hotspot.gd` | virgilio (936,886), inscripcion (770,850), 3 altares (282,362 / 1255,362 / 770,620), almas elio (67,633) y livia (1092,287), puerta (769,236). |
| `Particles` | Node2D + script | Motas ambientales (z=12). |
| `GateVisual` | Node2D + script | Portal con niebla (z=2). |
| `[HUD por código]` | CanvasLayer (layer 8) | Retratos, objetivos, minimapa, diálogo, pausa, toast. |
| `[ambient/sfx por código]` | AudioStreamPlayer | Audio ambiental y efectos. |

- **Estructurales:** paredes/abismos analíticos en `_is_path()` (rects + elipses de estanques + polígono del monumento). Sin nodos de colisión física.
- **Decorativos:** ilustración del jardín; sombra del jugador (`shadow.gd`, elipse `Color(0,0,0,0.25/0.16)`).
- **Interactivos:** 8 hotspots por radio de distancia (77–135 px): guía, inscripción, 3 santuarios, 2 almas, puerta.

#### D. Audio y Paisaje Sonoro
- **Ambiental:** `limbo_ambiente.wav` a `-24 dB`, bucle manual (`finished → play()`).
- **Efectos:** `santuario.wav` (-9 dB), `esquiva.wav` (-17 dB), `decision.wav` (-10 dB), `umbral.wav` (-8 dB), todos en `assets/audio/`.
- **Buses:** Master por defecto; sin audio posicional.

#### E. Layout y Estructura de Jugabilidad
- **Spawn:** `(769,834)` sur de la plaza; checkpoint por `Game.progress`. Cámara: zoom 0.96, smoothing 4.5, límites (0,0)-(1540,980).
- **Distribución:** entrada y Virgilio al sur; inscripción y santuario de Compasión al centro; santuarios Memoria/Oeste y Saber/Este; almas en extremos; **puerta final** al norte `(769,236)`.
- **UI/HUD:** HUD completo por código (`hud.gd`): retrato, dash, objetivos, minimapa (modo "limbo"), diálogo, pausa, toast.

---

### CÍRCULO II — LUJURIA (`scenes/Lujuria.tscn` + `scripts/lujuria.gd`)

#### A. Regla Ambiental y Scripts (.gd)
- **`scripts/lujuria.gd`** (601 líneas): círculo con **combate activo**.
  - **Regla ambiental: viento** — `wind_at(p)` con empuje por `Rect2`: ala izquierda `Rect2(130,420,425,145)` intensidad 116 (42 tras `sello_izquierdo`), dir `(0.97,0.22)`; ala derecha `Rect2(880,420,450,145)` 126 (43 tras sello), dir `(-0.95,0.31)`; patio superior `Rect2(540,277,380,118)` empuje `(0.42,-0.90)·45` (19 tras los 3 sellos). Oscilación `0.78+0.22·sin(t·1.35/1.50)`. El jugador aplica `wind * 0.36` (`lujuria_dante.gd:78`).
  - **Ráfaga de Minos:** `pulse_wind()` onda radial 165·pulse_left en radio 285 px durante 0.6 s.
  - **Colisión analítica** `_is_ground()`: rects + 4 elipses + 5 polígonos (rampas laterales, corte superior, pisos laterales); excluye estatua central (elipse `(727,503)` 125x116), abismos bajo balcones `(347,616)` y `(1101,616)` 118x72, arco muro `Rect2(654,670,146,85)`. Límites: x ∈ [104,1342], y ∈ [155,1070].
  - **IA/navegación:** 3 `AStarGrid2D` (61x46 celdas de 24 px, clearances 14/24/36 px) + `route_to()` para enemigos; `has_clear_path()` raycast discreto.
  - **Combate:** `melee_hit()` (daño 2; alcance 100 vs Minos / 72 resto), `spawn_projectile()` (258 hostil / 355 jugador), oleadas por posición (`inicio` y<932, `izquierda` x<480, `derecha` x>975, `patio` tras 2 sellos), jefe cuando 3 sellos + 2 almas + oleada patio + sin hostiles a <750 px.
  - **Scripts de apoyo:** `lujuria_dante.gd` (vida 6), `lujuria_enemigo.gd` (5 arquetipos: diablillo hp5/vel116, carcelero hp10/74, espectro hp6/103 r230, furia hp13/107, minos hp38/55 r250), `lujuria_proyectil.gd`, `lujuria_interactivo.gd`, `lujuria_viento_visual.gd`, `walk_solver.gd`.
- **Capas de física:** héroe `layer=1/mask=2`, enemigos `layer=2/mask=1`, pero los impactos se resuelven por distancia en scripts.

#### B. Aspecto Visual y Nodos de Godot 4
- **Mapa:** `MapaPintado` (`Sprite2D`, `centered=false`) con `res://assets/lujuria/world/lujuria_base.png`.
- **Profundidad:** `y_sort_enabled=true` en raíz, Interactivos y Enemigos; `z_index`: mapa 0, viento 2, interactivos/enemigos 4, jugador 4, proyectiles 7, HUD layer 10.
- **Iluminación y partículas:** sin luces ni partículas de motor. **`EfectosViento`** (`lujuria_viento_visual.gd`): glifos `draw_arc`/`draw_line` púrpura `Color(0.72,0.42,0.91)` / `Color(0.69,0.42,0.89)` (opacidad 0.52 activo / 0.20 tras sello), anillo de ráfaga `Color(0.78,0.44,0.94)`; sellos brillan `Color("9d68ca")` → `Color("9bc9a1")`.

#### C. Catálogo de Nodos y Objetos en la Escena

| Nodo (árbol real de Lujuria.tscn) | Tipo | Función |
| --- | --- | --- |
| `Lujuria` | Node2D + script (y_sort) | Raíz con `lujuria.gd`. |
| `MapaPintado` | Sprite2D | Mapa (lujuria_base.png). |
| `EfectosViento` | Node2D + script | Glifos de viento y ráfagas (z=2). |
| `Interactivos` | Node2D (y_sort, z=4) | Instancias `LujuriaInteractivo.tscn` por código. |
| `Enemigos` | Node2D (y_sort, z=4) | Instancias `LujuriaEnemigo.tscn` (CharacterBody2D). |
| `Proyectiles` | Node2D (z=7) | Instancias `LujuriaProyectil.tscn`. |
| `Dante` | CharacterBody2D (DanteLujuria.tscn) | Spawn `(723,977)`, z=4, grupo "hero". |
| `HUD` | CanvasLayer (HUD.tscn) | layer 10. |

- **Interactivos por código** (`_make_interactives()`): `virgilio` (858,877), `paolo` (293,575), `francesca` (1153,575) — estatuas `assets/lujuria/npcs/*_statue.png` con sombra elíptica `Color(0.02,0.01,0.04,0.32)`; `sello_inicio` "SELLO DE LA MEMORIA" (722,689), `sello_izquierdo` "SELLO DEL ALIENTO" (387,422), `sello_derecho` "SELLO DEL JUICIO" (1052,420) — orden `SEAL_ORDER`, bloqueados con enemigos a <140 px; `puerta` "UMBRAL HACIA LA GULA" (720,179).
- **Estructurales:** analíticos en `_is_ground()`.
- **Combate:** enemigos (CircleShape2D dinámico r 16–35) y proyectiles.

#### D. Audio y Paisaje Sonoro
- **Ambiental:** `lujuria_ambiente.wav` a `-19 dB` (bucle manual).
- **Efecto:** `sello.wav` a `-12 dB` (sellos, decisiones, muertes, golpes).
- **Buses:** Master por defecto.

#### E. Layout y Estructura de Jugabilidad
- **Spawn:** `(723,977)`; checkpoints `(720,790)` tras sello 1 y `(544,390)` tras 3 sellos. Cámara límites (0,0)-(1448,1086).
- **Zonas:** entrada con oleada "inicio"; rampas a alas laterales (almas y sellos); anillo de estatua central; patio superior = **arena del jefe** (Minos en `(716,317)`); puerta al norte.
- **UI/HUD:** layer 10 con retrato, vida 6, dash, objetivos, minimapa "lujuria", boss bar "MINOS", diálogo Redención/Rigor, pausa, toast.

---

### CÍRCULO III — GULA (`scenes/Gula.tscn` + `scripts/gula.gd`)

#### A. Regla Ambiental y Scripts (.gd)
- **`scripts/gula.gd`** (304 líneas):
  - **Regla ambiental: LODO** — `movement_factor(p)` devuelve **0.56** en polígonos del nodo `Lodo` (LodoSur/LodoOeste/LodoEste); multiplicador de velocidad y esquiva. Visual: `_draw()` pinta los charcos `Color(0.27,0.35,0.10,0.20)`.
  - **Colisión por polígonos editables:** `can_walk()` con `Geometry2D.is_point_in_polygon` sobre los 9 `Polygon2D` de `Suelo`.
  - **Scripts de zona:** `gula_area.gd` (`@tool`, `@export_enum("suelo","lodo")`) — editor: suelo verde `Color(0.22,0.8,0.3,0.18)`, lodo naranja `Color(0.83,0.55,0.1,0.36)`; en juego `visible=false`.
  - **Combate:** `melee_hit()` solo daña al jefe (alcance 126); `spawn_projectile()` reutiliza `LujuriaProyectil.tscn` (hostil 245 / jugador 355; proyectil enemigo verde `Color("b5dd73")` si `world.name=="Gula"`).
  - **Jefe:** Cerbero (`gula_cerbero.gd`) — hp 36, radio 62; patrones: mordida (<120 px, daño 2), aullido (3 proyectiles ±0.24 rad, daño 1), zarpazo (<170 px, daño 2); cooldown 1.6→1.1 s bajo 50%, windup 0.78→0.58 s, aviso `Color(0.8,1.0,0.35,0.65)`. Bloqueo de paso a <70 px del jefe.
  - **Activación:** 2 ofrendas hundidas + 2 almas decididas → `_check_boss_spawn()`.
  - **Transición:** `_complete_level()` → `FinGula.tscn`, cuyo botón continuar ahora ejecuta `Game.enter_traicion()` y carga `Traicion.tscn`.

#### B. Aspecto Visual y Nodos de Godot 4
- **Mapa:** `MapaPintado` (`Sprite2D`, z=-20) con `res://assets/gula/world/gula_base.png` (+ `gula_rutas.png` de revisión).
- **Profundidad:** sin Parallax; y_sort en `Enemigos`; z: mapa -20, enemigos/jugador 4, proyectiles 7, HUD 10.
- **Iluminación y partículas:** sin luces ni partículas de motor ni `_draw()` de ambiente. Marcadores verdes `Color("#b7e26c")`/`Color("#98c66a")` (`gula_marker.gd`); ofrendas se hunden visualmente (offset `sink*14 px`, opacidad 1−0.75·sink).

#### C. Catálogo de Nodos y Objetos en la Escena

| Nodo (árbol real de Gula.tscn) | Tipo | Función |
| --- | --- | --- |
| `Gula` | Node2D + script | Raíz con `gula.gd`. |
| `MapaPintado` | Sprite2D | Mapa (gula_base.png), z=-20. |
| `Suelo` | Node2D | 9 `Polygon2D` + `gula_area.gd`: Entrada (590,1086)…(850,944); PlazaSur; RampaOeste/RampaEste; PatioOeste/PatioEste; ArenaCerbero; EscaleraCerbero; UmbralNorte. |
| `Lodo` | Node2D | 3 `Polygon2D` tipo="lodo": LodoSur (570,826)…(905,896); LodoOeste; LodoEste. |
| `Marcadores` | Node2D | 6 marcadores `gula_marker.gd`: Virgilio (857,935) "guia"; OfrendaOeste (243,501) y OfrendaEste (1205,501) "ofrenda"; Daria (171,591) y Olmo (1277,591) "alma"; Puerta (724,141) "puerta" — "UMBRAL HACIA AVARICIA". |
| `Enemigos` | Node2D (y_sort, z=4) | Contenedor del jefe. |
| `Proyectiles` | Node2D (z=7) | Contenedor de proyectiles. |
| `Dante` | CharacterBody2D (DanteLujuria.tscn) | Spawn `(724,1015)`, z=4. |
| `HUD` | CanvasLayer | layer 10. |

- **Estructurales:** todo el piso transitable/abismos definidos con los 9 `Polygon2D` de `Suelo`.
- **Interactivos:** ofrendas (hundimiento), almas con diálogo (Daria/Olmo), guía, puerta condicionada a `boss_defeated`.

#### D. Audio y Paisaje Sonoro
- **Sin audio propio:** `gula.gd` no crea `AudioStreamPlayer` ni ambiental (verificado; no hay archivos en `assets/gula/`).
- **Buses:** Master por defecto.

#### E. Layout y Estructura de Jugabilidad
- **Spawn:** `(724,1015)`; jefe en `(724,257)`. Cámara de `DanteLujuria.tscn` (límites (0,0)-(1448,1086)).
- **Distribución:** entrada sur → plaza sur con estanque de lodo central → dos rampas con charcos → patios laterales (ofrenda + alma por lado) → escalera/arena de Cerbero al norte → UmbralNorte.
- **UI/HUD:** layer 10; boss bar `hud.boss_text.text = "CERBERO"`; minimapa modo "gula" (verde).

---

### CÍRCULO IX — TRAICIÓN / COCITO (`scenes/Traicion.tscn` + `scripts/traicion.gd`) — NUEVO

#### A. Regla Ambiental y Scripts (.gd)
- **`scripts/traicion.gd`** (315 líneas, raíz `Node2D`): "Círculo IX: Cocito, juramentos rotos y el guardián del hielo".
  - **Regla ambiental: HIELO FINO** — mecánica exclusiva de este círculo, en dos capas:
    1. **Ralentización:** `movement_factor(p)` devuelve **0.72** si el punto está sobre hielo fino y **0.92** en suelo normal (aplicado por `lujuria_dante.gd` a velocidad y esquiva).
    2. **Quiebre por permanencia:** en `_process()`, si el héroe está sobre hielo fino (`_on_thin_ice()` con `Geometry2D.is_point_in_polygon`) y NO está esquivando (`hero.dash_time <= 0.0`), se acumula `frost_time`; al llegar a **2.2 s** inflige 1 de daño y avisa "El hielo se quiebra bajo tus pies. Muévete o esquiva.". Fuera del hielo, el contador decae al doble de velocidad (`frost_time - delta*2.0`).
  - **Visual del hielo:** `_draw()` pinta cada polígono de `HieloFino` con relleno `Color(0.35,0.84,1.0,0.12)` y bordes `Color(0.65,0.93,1.0,0.48)` de 2 px.
  - **Colisión por polígonos editables:** igual que Gula — `can_walk()` verifica 9 muestras contra los 6 `Polygon2D` de `Suelo`.
  - **Combate:** `melee_hit()` solo daña al jefe (alcance 125); `spawn_projectile()` reutiliza `LujuriaProyectil.tscn` (hostil 230 —el más lento del juego— / jugador 355; el proyectil enemigo se tiñe cian `Color("80e8ff")` si `world.name == "Traicion"`). `wind_at()` devuelve `Vector2.ZERO` (no hay viento aquí).
  - **Jefe Lucifer (`traicion_lucifer.gd`, 90 líneas):** hp **48** (el mayor del juego), radio 58, escala del sprite 0.21, flash de daño `Color("#8eeaff")`. 3 patrones con ciclo `(pattern+1)%3`:
    - **0 — Aliento helado:** abanico de **5 proyectiles** (±0.35, ±0.17, 0 rad, daño 1) apuntados a la posición registrada al telegrafiarse (`target`), esquivables.
    - **1 — Quiebre del hielo:** zona en el punto objetivo; si el héroe está a <112 px del `target` al resolverse, daño 2. Aviso: círculo relleno `Color(0.2,0.8,1.0,0.09)` + anillo `Color(0.58,0.94,1.0,0.8)` r=112 dibujado en coordenadas `to_local(target)`.
    - **2 — Golpe cercano:** si está a <145 px, daño 2; aviso anillo r=145. El aviso del patrón 0 usa anillo r=72.
    - Cooldown 1.45→1.0 s bajo 50% de vida; windup 0.90→0.65 s; solo ataca si el héroe está a <480 px. Sombra elíptica r=76 `Color(0,0.02,0.05,0.48)`.
  - **Activación del jefe:** `_check_boss_spawn()` al romper los 2 juramentos + decidir sobre las 2 almas; Lucifer aparece en `(724,355)`; barra del jefe con texto `hud.boss_text.text = "LUCIFER · GUARDIÁN DE COCITO"`.
  - **Guardado:** `Game.progress` claves `traicion_*` (seals, decisions, intro_seen, boss_spawned, boss_defeated, checkpoint_x/y) gestionadas por `game_state.gd` (que ahora incluye defaults `traicion_*` y `enter_traicion()`, y `next_scene()` devuelve `Traicion.tscn`/`FinTraicion.tscn`).
  - **Scripts de apoyo:** `traicion_area.gd`, `traicion_marker.gd`, `traicion_nieve.gd`, `lujuria_dante.gd` (héroe), `lujuria_proyectil.gd`, `hud.gd`, `minimap.gd`, `game_state.gd`, `fin_traicion.gd`.
- **Regla de diseño (según `TRAICION_ESCENARIO.md`):** los ataques del jefe tienen avisos visibles y son esquivables; los círculos IV–VIII no están construidos, `FinGula` ofrece acceso directo al final.

#### B. Aspecto Visual y Nodos de Godot 4
- **Mapa:** sin TileMap. Nodo **`Cocito`** (`Sprite2D`, `centered=false`, filter lineal, z=-20) con `res://assets/traicion/world/cocito.png` (lago helado, ruinas, arena central).
- **Profundidad:** sin Parallax; y_sort en `Enemigos`; `z_index`: mapa -20, nieve 8 (sobre proyectiles), enemigos/jugador 4, proyectiles 7, HUD layer 10.
- **Iluminación y partículas:** sin luces ni partículas de motor. **Nieve procedural con `traicion_nieve.gd`** (nodo `Nieve`, `Node2D`, z=8): 88 copos (`COUNT=88`, semilla 91739) con deriva diagonal (viento x: 24+prof·15, caída y: 33+prof·23 px/s), reinicio en wrap (`x>1455 → -8`); cada copo = trazos `draw_line` `Color(0.81,0.95,1.0,0.36)` + `draw_circle` `Color(0.91,0.98,1.0,0.60)` con profundidad 0.65–1.5.
- **Paleta del círculo:** cian/azul hielo. Marcadores (`traicion_marker.gd`): sello `Color("#79d9ef")` completado / `Color("#b5ebf7")` activo, con cruz dibujada para "sello"; alma `Color("#d6e4f1")`; guía `Color("#e8ddc7")`; puerta `Color("#b9f5fa")` abierta / `Color("#607d89")` cerrada; sombra elíptica `Color(0,0.05,0.08,0.45)` y pulso `1.0+sin(phase·2.4)·0.08`. **Tinte registrado:** `CIRCLE_TINTS["traicion"] = "#5ba4cf"` en `game_state.gd:14`.

#### C. Catálogo de Nodos y Objetos en la Escena

| Nodo (árbol real de Traicion.tscn) | Tipo | Función |
| --- | --- | --- |
| `Traicion` | Node2D + script | Raíz con `traicion.gd`. |
| `Cocito` | Sprite2D | Mapa ilustrado (cocito.png), z=-20. |
| `Suelo` | Node2D | Zonas transitables. |
| `Suelo/Entrada` | Polygon2D + `traicion_area.gd` | Corredor sur (620,1086)…(823,713)/(615,713). |
| `Suelo/ExplanadaSur` | Polygon2D | Franja sur del lago (14 vértices, en V). |
| `Suelo/PatioOeste` | Polygon2D | Patio lateral oeste (12 vértices). |
| `Suelo/PatioEste` | Polygon2D | Patio lateral este (12 vértices). |
| `Suelo/Arena` | Polygon2D | **Arena central de Lucifer** (12 vértices, elipse irregular). |
| `Suelo/Umbral` | Polygon2D | Salida norte (594,253)…(854,253)/(614,164). |
| `HieloFino` | Node2D | Zonas de hielo quebradizo. |
| `HieloFino/GrietaOeste` | Polygon2D (tipo="hielo_fino") | (501,658)…(579,762) — acceso al patio oeste. |
| `HieloFino/GrietaEste` | Polygon2D (tipo="hielo_fino") | (947,658)…(869,762) — acceso al patio este. |
| `HieloFino/GrietaArena` | Polygon2D (tipo="hielo_fino") | (603,420)…(845,420) — acceso a la arena. |
| `Marcadores` | Node2D | 6 marcadores `Node2D` + `traicion_marker.gd`: Virgilio (811,947) "guia"; SelloOeste (270,523) y SelloEste (1178,523) "sello" — "ROMPER EL JURAMENTO DEL OESTE/ESTE"; AlmaUgolino (180,619) y AlmaBocca (1268,619) "alma"; Salida (724,185) "puerta" — "CRUZAR EL CENTRO DEL INFIERNO". |
| `Enemigos` | Node2D (y_sort, z=4) | Contenedor del jefe Lucifer. |
| `Proyectiles` | Node2D (z=7) | Contenedor de proyectiles. |
| `Nieve` | Node2D + script | Nieve procedural (z=8). |
| `Dante` | CharacterBody2D (instancia DanteLujuria.tscn) | Spawn `(724,1000)`, z=4. |
| `HUD` | CanvasLayer (instancia HUD.tscn) | layer 10. |

- **Estructurales:** piso transitable y abismos definidos exclusivamente por los 6 `Polygon2D` de `Suelo` (fuera de ellos no se camina); el hielo fino son zonas de riesgo, no bloqueos.
- **Decorativos:** ilustración de Cocito; nieve procedural; sombra elíptica del jefe.
- **Interactivos:** 2 juramentos (sellos que se rompen, sin requisito de orden ni enemigos cercanos — a diferencia de Lujuria), 2 almas con diálogo (Ugolino: "¿Me recordarás como hombre, pese a mis faltas?"; Bocca: "¿Puedo confesar la verdad ahora?" — ambos con opciones Redención/Rigor vía `Game.decide()`), guía Virgilio, Salida condicionada a `boss_defeated` (al vencer al jefe `$Marcadores/Salida.set_done(true)`).

#### D. Audio y Paisaje Sonoro
- **Sin audio propio:** `traicion.gd` no crea `AudioStreamPlayer` ni ambiental ni efectos (verificado; no hay archivos en `assets/traicion/`). Como en Gula, el sonido queda pendiente para este círculo.
- **Buses:** Master por defecto.

#### E. Layout y Estructura de Jugabilidad
- **Spawn del jugador:** `Dante` en `(724,1000)` (corredor de entrada sur); **punto de aparición del jefe:** `(724,355)` (centro de la arena); checkpoint por defecto `traicion_checkpoint = (724,1000)`. Cámara: la de `DanteLujuria.tscn` (zoom 0.96, smoothing 4.5, límites (0,0)-(1448,1086), igual que las dimensiones del mapa).
- **Distribución:** entrada sur → explanada sur del lago → **tres rutas**: grieta de hielo fino oeste y este hacia los patios laterales (juramento + alma a cada lado), y grieta central `GrietaArena` hacia la **arena central = arena del jefe**; Umbral norte como salida final ("CRUZAR EL CENTRO DEL INFIERNO"). Virgilio espera junto a la entrada (811,947).
- **UI/HUD:** `CanvasLayer` layer 10; subtítulo de capítulo **"IX — TRAICIÓN"** (`hud.gd configure_chapter()`); boss bar "LUCIFER · GUARDIÁN DE COCITO"; vida 6; dash; panel de objetivos (`set_traicion_state()` muestra juramentos/almas/puerta); minimapa con **modo "traicion"** (`minimap.gd _draw_traicion()`, paleta azul hielo); diálogo, pausa y toast compartidos.

---

## 3. Resumen Consolidado de Nodos y Rutas

| Círculo/Nivel | Escena Principal (.tscn) | Scripts Asociados (.gd) | Nodos Clave Utilizados |
| --- | --- | --- | --- |
| **Menú / Transiciones** | `scenes/MenuPrincipal.tscn`, `scenes/Transicion.tscn`, `scenes/FinLimbo.tscn`, `scenes/FinLujuria.tscn`, `scenes/FinGula.tscn`, `scenes/FinTraicion.tscn` | `main_menu.gd`, `transicion.gd`, `fin_limbo.gd`, `fin_lujuria.gd`, `fin_gula.gd`, `fin_traicion.gd`, `game_state.gd` (autoload `Game`) | Control, UI construida por código |
| **Círculo I — Limbo** | `scenes/Limbo.tscn` | `limbo.gd`, `dante.gd`, `hotspot.gd`, `particles.gd`, `gate_visual.gd`, `shadow.gd`, `hud.gd`, `minimap.gd`, `game_state.gd` | Node2D, Sprite2D (limbo_master.png), CharacterBody2D + CircleShape2D + Camera2D (Dante.tscn), Node2D+_draw (hotspots/partículas/portal), CanvasLayer (HUD), AudioStreamPlayer (código) |
| **Círculo II — Lujuria** | `scenes/Lujuria.tscn` | `lujuria.gd`, `lujuria_dante.gd`, `lujuria_enemigo.gd`, `lujuria_interactivo.gd`, `lujuria_proyectil.gd`, `lujuria_viento_visual.gd`, `walk_solver.gd`, `hud.gd`, `minimap.gd`, `game_state.gd` | Node2D (y_sort), Sprite2D (lujuria_base.png), CharacterBody2D (héroe+enemigos, CircleShape2D), Sprite2D interactivos (estatuas/sellos/puerta), Node2D+_draw (viento), Node2D (proyectiles), CanvasLayer (HUD layer 10), AudioStreamPlayer (código), AStarGrid2D (IA) |
| **Círculo III — Gula** | `scenes/Gula.tscn` | `gula.gd`, `gula_area.gd`, `gula_marker.gd`, `gula_cerbero.gd`, `lujuria_dante.gd` (héroe), `lujuria_proyectil.gd`, `hud.gd`, `minimap.gd`, `game_state.gd` | Node2D, Sprite2D (gula_base.png), **Polygon2D** (9 suelo + 3 lodo, script @tool), Node2D+export (marcadores), Node2D jefe (Sprite2D + _draw), Node2D (proyectiles), CanvasLayer (HUD layer 10) |
| **Círculo IX — Traición (NUEVO)** | `scenes/Traicion.tscn` | `traicion.gd`, `traicion_area.gd`, `traicion_marker.gd`, `traicion_nieve.gd`, `traicion_lucifer.gd`, `lujuria_dante.gd` (héroe), `lujuria_proyectil.gd`, `hud.gd`, `minimap.gd`, `game_state.gd`, `fin_traicion.gd` | Node2D, Sprite2D (cocito.png), **Polygon2D** (6 suelo + 3 hielo fino, script @tool `traicion_area.gd`), Node2D+export (6 marcadores), Node2D jefe Lucifer (Sprite2D lucifer.png + _draw de avisos), Node2D nieve procedural (z=8), Node2D (proyectiles), CanvasLayer (HUD layer 10) |
| **HUD compartido** | `scenes/HUD.tscn` | `hud.gd` (~19.8 KB), `minimap.gd` (~5.3 KB, 4 modos: limbo/lujuria/gula/traicion) | CanvasLayer; toda la UI (paneles, barras, retratos, diálogo, pausa, minimapa, boss bar) construida por código |
| **Jugador** | `scenes/Dante.tscn` (exploración), `scenes/DanteLujuria.tscn` (combate; usado en Lujuria, Gula y Traición) | `dante.gd`, `lujuria_dante.gd`, `shadow.gd` | CharacterBody2D, AnimatedSprite2D (sheets `assets/dante/*.png`, frames 80x96), CircleShape2D r=10, Camera2D (zoom 0.96, smoothing 4.5) |
| **Enemigos / Jefes** | `scenes/LujuriaEnemigo.tscn`, `scenes/GulaCerbero.tscn`, `scenes/TraicionLucifer.tscn` | `lujuria_enemigo.gd` (5 arquetipos), `gula_cerbero.gd` (hp 36), `traicion_lucifer.gd` (hp 48), `lujuria_proyectil.gd` | CharacterBody2D + AnimatedSprite2D + CircleShape2D (Lujuria); Node2D + Sprite2D + _draw (telegraphs) (Gula/Traición) |

### Cadena de progreso verificada
`MenuPrincipal` → `Limbo` → (`FinLimbo`) → `Lujuria` → `FinLujuria` → `Gula` → `FinGula` → **(botón continuar → `Game.enter_traicion()`)** → `Traicion` → `FinTraicion` (final del descenso). `game_state.gd` también permite "Continuar partida" (`next_scene()`): FinTraicion > Traicion > Gula > Lujuria > Limbo según el círculo guardado. El menú principal ofrece el acceso directo "Jugar Traición — Círculo IX".

### Assets de entorno por círculo
- **Limbo:** `assets/world/limbo_master.png`; audio en `assets/audio/`.
- **Lujuria:** `assets/lujuria/world/lujuria_base.png`, `assets/lujuria/npcs/{virgilio,paolo,francesca}_statue.png`, `sello.png`, `gate.png`, `assets/lujuria/enemies/*` (idle/walk/attack/hurt/death), audio en `assets/lujuria/audio/`.
- **Gula:** `assets/gula/world/gula_base.png` (+ `gula_rutas.png`), `assets/gula/enemies/cerbero.png`.
- **Traición (NUEVO):** `assets/traicion/world/cocito.png` (mapa del lago) y `assets/traicion/enemies/lucifer.png` (sprite del jefe).
- **UI:** `assets/ui/retrato_{dante,virgilio,alma,piedra}.png`.

### Reglas ambientales por círculo (comparativa)
| Círculo | Regla ambiental | Factor de movimiento | Daño ambiental | Jefe |
| --- | --- | --- | --- | --- |
| I Limbo | Jardín tranquilo; salto sobre estanques | 1.0 | Ninguno | — (sin combate) |
| II Lujuria | Viento direccional por zonas + ráfagas de Minos | 1.0 (empuje externo) | Por contacto/proyectil | Minos (hp 38) |
| III Gula | Lodo (charcos poligonales) | **0.56** en lodo | Por contacto del jefe | Cerbero (hp 36) |
| IX Traición | Hielo fino (grietas poligonales) + nieve visual | **0.72** en hielo / 0.92 normal | **1 de daño cada 2.2 s** parado sobre hielo (no durante esquiva) | **Lucifer (hp 48)** |

### Pruebas de verificación existentes
`tests/navigation_smoke.gd`, `tests/gula_smoke.gd`, `tests/visual_debug.gd`, `tests/gula_visual_debug.gd`, **`tests/traicion_smoke.gd` (Godot headless) y `tests/traicion_geometry.cjs` (Node)**. Documentadas en `README.md`, `PRUEBAS.md`, `GULA_ESCENARIO.md`, `TRAICION_ESCENARIO.md`, `ENTREGA_ENTORNO_VIRTUAL.md`, `PRUEBAS_MANUALES.md`.

---

*Informe regenerado por auditoría directa de `*.tscn`, `*.gd` y `project.godot` el 2026-11-17, incluyendo el Círculo IX (Traición/Cocito). Ningún dato fue asumido: cada afirmación corresponde a código presente en el repositorio.*
