# Actualización de Inferno El Descenso

Proyecto completo en Godot 4.7.2. Extrae el ZIP, importa `project.godot` y ejecuta con **F5**. Los archivos de la tabla se entregan completos en sus rutas. Para abrir sólo un círculo en el editor, carga su escena y pulsa **F6**. Para trasladar los cambios a otra copia, copia también los recursos nuevos y sus referencias.

## 1. Colisiones

| Archivo o escena | Nodo o ajuste |
| --- | --- |
| `project.godot` | Project Settings → Layer Names → 2D Physics. Capa 1 Dante y capa 2 Enemigos. |
| `scenes/Dante.tscn`, `scenes/DanteLujuria.tscn` | Raíz `Dante`. Capa 1, máscara vacía y `CollisionShape2D` circular de 10 px en los pies. |
| `scenes/LujuriaEnemigo.tscn`, `scenes/GulaEnemigo.tscn`, `scenes/GulaCerbero.tscn` | Raíz en capa 2 y máscara vacía. Conserva el `CollisionShape2D` en la raíz del actor. Los scripts de enemigos ajustan los radios de los tipos en ejecución. |
| `scripts/limbo.gd`, `scripts/lujuria.gd` | Ajusta `monument_outline` y la elipse de la estatua en `_is_ground` para seguir sus bases. La huella de los NPC se evalúa aparte de la navegación de enemigos en Lujuria. |
| `scenes/Gula.tscn`, `scenes/Traicion.tscn`, `scripts/gula.gd`, `scripts/traicion.gd` | Edita los vértices de `Suelo` y las zonas ambientales en el editor 2D. La consulta usa coordenadas locales de cada polígono, por lo que moverlo en el editor también mueve su área de juego. Las almas de Gula ocupan una huella reducida. |
| `scripts/violencia_geometry.gd`, `scripts/violencia.gd` | Edita los vértices de `_init`, las bases en `contains_point` y los límites del duelo en `ARENA`. **F3** dibuja polígonos de revisión durante la partida. |

El terreno usa fondos pintados `Sprite2D` y comprobaciones geométricas por código. No hay nodos `TileMap` ni recursos `TileSet` que editar en los cinco niveles. La máscara vacía evita duplicar bloqueos físicos sobre las restricciones del suelo y del combate. Los golpes siguen usando las pruebas de alcance propias de cada enemigo.

## 2. Personajes y enemigos

`scripts/dante.gd`, `scripts/lujuria_dante.gd`, `scripts/enemy_contrast.gd` y `shaders/enemy_contrast.gdshader` aplican la paleta verde petróleo a la capa de Dante y un perfil cálido a su silueta. La aplicación se hace sobre `Dante/AnimatedSprite2D` al cargar la escena. Los archivos `lujuria_enemigo.gd`, `gula_enemigo.gd`, `gula_cerbero.gd`, `violencia_enemy.gd`, `violencia_guardian.gd` y `traicion_lucifer.gd` usan el contorno de enemigo. Los marcadores con sprites también se distinguen mediante el material compartido en `lujuria_interactivo.gd`, `gula_marker.gd`, `violencia_marker.gd` y `traicion_marker.gd`. Edita `outline_width`, `light_edge` y `dark_edge` en el shader.

## 3. Ataques

`scripts/combat_fx.gd` dibuja un barrido o estallido con partículas y desvanecimiento por Tween. Los controladores de ataque indicados en el punto 2 lo disparan al ejecutar el golpe. Los tiempos internos de preparación siguen rigiendo el combate. Los enemigos esperan sin dibujar indicadores ni reproducir poses de ataque adelantadas. El ataque real conserva su proyectil, animación o efecto de impacto. Limbo es un escenario de exploración.

## 4. HUD

`scenes/HUD.tscn` monta el `CanvasLayer`. `scripts/hud.gd` crea los controles en ejecución. **Tab** o **Objetivos** muestra el panel, que arranca oculto. El minimapa ocupa la esquina inferior derecha y lo escala `scripts/minimap.gd`. Las pistas y mensajes de almas aparecen en un panel opaco superior y la interacción por **E** se muestra en un aviso inferior. Edita `_build` y `configure_chapter` para ajustar tamaños y posiciones del lienzo de 1280 × 720.

## 5. Menú principal

`scenes/MenuPrincipal.tscn` conserva su nodo `Control`; `scripts/main_menu.gd` crea las páginas de inicio, selección y configuración. `scripts/game_state.gd` carga y guarda el progreso de campaña en `user://inferno_save_v2.json`. Selección de niveles inicia una visita a cualquiera de los cinco círculos en modo libre, con archivo aparte. **Continuar partida anterior** reanuda la campaña. El interruptor y el volumen se aplican al bus `Master` y se guardan en `user://inferno_settings.cfg`.

## 6. Botones y contraste

`themes/inferno.tres` define cinco `StyleBoxFlat` de `Button`: normal, hover, pressed, focus y disabled. Cambia el recurso en Project Settings → GUI → Theme → Custom. El foco tiene borde propio y el texto usa tonos oscuros sobre fondos claros. Los botones de pausa, diálogo, transiciones y pantallas finales heredan este recurso.

## 7. Fondos, piezas de suelo y decoración

Los escenarios intervenidos son mapas pintados. Los fondos listos para importar ya están en `assets/violencia/flegetonte_terrazas.png` y `assets/traicion/world/cocito.png`. En `assets/violencia/atlas/` y `assets/traicion/atlas/` se incluyen recortes reutilizables como `AtlasTexture` de piedra, escalera, brasero, monumento, hielo y ruinas, enlazados con esos PNG. Puedes arrastrarlos a `Sprite2D.texture` o usar el mismo PNG como origen de un eventual atlas para un TileSet. Son piezas pictóricas del original y sus regiones no están pensadas como patrones continuos ni forman parte de las colisiones. Las ruinas y la piedra detallada mantienen el lenguaje visual del Limbo, con acentos rojos de Violencia y azul hielo de Cocito.

## 8. Traición

`scenes/Traicion.tscn` incluye el `Sprite2D` `Cocito` como fondo y `BrumaDeCocito` como `ColorRect` con `shaders/cocito_atmosphere.gdshader`. Edita el material para cambiar la bruma móvil, el halo y las sombras. `traicion_nieve.gd` anima las partículas de nieve, `traicion.gd` dibuja las grietas pulsantes sobre `HieloFino`, `traicion_marker.gd` anima las figuras y juramentos, y `traicion_lucifer.gd` anima la respiración y los ataques de Lucifer. El dibujo de grietas usa los mismos polígonos que aplican la regla del hielo.

## 9. Puertas, sonido y transición

`scripts/gate_visual.gd` anima la elevación de la reja, ilumina el arco y reproduce el sonido de umbral al desbloquearla. En `scenes/Limbo.tscn`, selecciona `GateVisual` y ajusta las propiedades exportadas `aperture` y `tint`. Los otros cuatro círculos instancian el mismo script desde `_ready`, donde se indican el rectángulo y el color del arco. `Game.cross_threshold` ejecuta el fundido al confirmar la salida. Las escenas de cierre usan `scripts/transicion.gd`, `fin_lujuria.gd`, `fin_gula.gd` y `fin_violencia.gd` para el siguiente círculo disponible.

## 10. Violencia

`scenes/Violencia.tscn` usa **Terrazas góticas del río Flegetonte**. `Mapa.texture` apunta a `flegetonte_terrazas.png`; la escala del fondo es 1,59116 y la cámara de Dante limita el mundo a 2304 × 1728. `scripts/violencia_geometry.gd` define el puente, escaleras, terrazas, pedestal, patio del jefe y salida. `violencia.gd` ubica los tres votos, los guardianes, Virgilio, las almas y el Minotauro. `minimap.gd` utiliza los nuevos polígonos y `fin_violencia.gd` utiliza la misma ilustración. Al cargar un guardado creado antes del mapa nuevo, Dante reaparece en la entrada y se conservan sus votos, decisiones y derrotas registradas.

## Pruebas

Las pruebas automatizadas recorren la campaña, validan navegación, guardado y combate, y comprueban que el nuevo mapa permita llegar a los puntos de interacción. Para ejecutarlas con datos aislados en PowerShell:

```powershell
$env:APPDATA = Join-Path $env:TEMP "inferno-pruebas"
godot --headless --path . --script res://tests/five_circles_smoke.gd
godot --headless --path . --script res://tests/violencia_full_smoke.gd
godot --headless --path . --script res://tests/violencia_guardians_smoke.gd
```

En Linux, usa `XDG_DATA_HOME` con una carpeta temporal. En la revisión gráfica se observaron el menú, la configuración, Traición y Violencia con sus portales y HUD. Las comprobaciones automatizadas no equivalen a jugar manualmente todo el recorrido.
