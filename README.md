# INFERNO: EL DESCENSO — CAPÍTULO I: LIMBO

Proyecto de Godot 4.3+ para Windows. Primer círculo **jugable y autocontenido** (sin prometer contenido de los siguientes niveles).

## Cómo abrirlo

1. Descomprimir `INFERNO_LIMBO_REFINADO_GODOT4.zip`.
2. Abrir Godot 4.3 o superior (preferiblemente Godot 4.4 o 4.5).
3. `Importar` → elegir la carpeta del juego → abrir `project.godot`.
4. Esperar a que el editor importe los PNG/WAV. Pulsar **F5** para comenzar desde el menú.
5. Si no quieres perder el progreso, usa **Continuar partida**: el guardado se guarda en `user://inferno_save_v2.json`.

## Controles

| Tecla | Acción |
|---|---|
| WASD o flechas | Mover a Dante (ocho direcciones) |
| ESPACIO | Esquiva corta con enfriamiento |
| E | Interactuar con almas, piedras y santuarios |
| Q | Solicitar una pista contextual de Virgilio |
| 1 / 2, o clic | Elegir una respuesta en los diálogos |
| ESC | Pausa y reanudación |
| J / K | Preparados para otros capítulos; **desactivados en el Limbo** |

## Recorrido completo del primer círculo

**1. Inicio:** dialogar con Virgilio. Los pasos se guardan automáticamente tras cada decisión o evento relevante.

**2. Descifrar la inscripción:** explorar la explanada del sur, junto al pavimento circular; leerla con E. La inscripción da el orden del rompecabezas.

**3. Puzzle:** activar en este orden **Memoria (oeste) → Saber (este) → Compasión (centro, frente a la estatua)**. El orden incorrecto muestra una pista, sin bloquear para siempre el nivel.

**4. Decisiones morales:** hablar con Elio (al oeste, junto al estanque) y Livia (al noreste). Una elección suma **Redención** y la otra **Rigor**; no hay una respuesta «correcta» forzada. Se guardan por separado.

**5. Descenso:** dirigirse a la puerta del norte cuando los tres santuarios y ambas almas estén completados. Aparece la pantalla **Capítulo I completado**. Lujuria queda expresamente como contenido futuro; no hay una escena falsa.

## Qué está implementado

- Mapa ilustrado cenital con la composición que aprobaste, ambientación en escala de grises y acento Limbo `#9AA0A6`.
- Dante rediseñado a partir de la hoja de concepto: cinco hojas de animaciones independientes y transparentes, cuatro orientaciones (`idle`, `walk`, `dash`, `interact`, `ready`). Son **96 fotogramas** en total: `(4 + 8 + 4 + 4 + 4) × 4 = 96`.
- Movimiento en ocho direcciones y animaciones en cuatro orientaciones. Colisión física con límites, estanques, estatuas y ruinas principales.
- Interacciones por proximidad y marcadores luminosos, escaneo de objetivos, pistas dinámicas, puzzle ordenado y respuestas morales.
- HUD dinámico y no impreso en el fondo: retrato de Dante, tres corazones, barras Redención/Rigor, objetivos, minimapa con posición, esquiva, diálogo, notificaciones y pausa.
- Menú principal, continuar partida, guardado JSON local, capítulos reutilizables, cierre del Limbo y sonido ambiente.
- La paleta de colores de los diez niveles está centralizada en `scripts/game_state.gd` (`CIRCLE_TINTS`). **No se aplican los pecados de los otros círculos al Limbo**.

## Estructura

```
project.godot
scenes/
  MenuPrincipal.tscn  # menú
  Limbo.tscn          # mundo, colisiones y eventos
  Dante.tscn          # CharacterBody2D reutilizable
  HUD.tscn            # interfaz dinámica
  FinLimbo.tscn       # fin real del capítulo
scripts/
  game_state.gd       # guardado, puntuaciones y paleta por círculo
  dante.gd            # movimiento, evasión, animaciones y señales
  limbo.gd            # diseño del nivel, puzzle, almas y puerta
  hud.gd              # cuadros y medidores
  minimap.gd          # plano que sigue la posición de Dante
  hotspot.gd          # señalización contextual
  gate_visual.gd      # puerta desbloqueada
  particles.gd        # motas ambientales
  shadow.gd           # sombra bajo los pies
  main_menu.gd
  fin_limbo.gd
assets/
  dante/              # 5 spritesheets RGBA, 80 × 96 px por fotograma
  world/              # ilustración del jardín, sin retrato de jugador fijo
  ui/                 # retratos circulares
  audio/              # ambiente sonoro
```

## Siguiente paso para la versión de publicación

Esta entrega es una **versión jugable del capítulo I**, no un juego de nueve círculos. Se priorizó que los activos de interfaz y personaje estuviesen separados del fondo y que el progreso funcione. Para llevarlo a calidad de publicación, conviene ejecutar pruebas en Godot en Windows, revisar la precisión de las colisiones en cada rincón, probar distintas resoluciones y completar animaciones avanzadas del personaje (muerte y combate real cuando llegue un círculo que lo requiera).

**Importante:** en este entorno no hay un ejecutable de Godot para abrir el proyecto y comprobar la ejecución. Se han efectuado comprobaciones de integridad del paquete, presencia de recursos, transparencia de los sprites y recorridos previstos. Eso **no sustituye** una prueba desde el editor; si Godot da un error concreto, compárteme el texto y lo corregimos sobre estos archivos.

## Dirección artística

- Referencia: documento de concepto *Inferno: El Descenso*, primera zona «Paganos virtuosos; sin combate, exploración y puzzles tranquilos».
- Atmósfera: grabado en gris frío, jardines y ruinas simétricas, estatuas, estanques, almas melancólicas y efectos sobrios.
- El personaje conserva una capa roja oscura como rasgo identificador de Dante, mientras las **reglas cromáticas de cada círculo** se administran de forma independiente.
- La ilustración del escenario es una base artística integrada en un Sprite2D, no un TileMap editable losa por losa. Los marcadores, colisiones, UI, jugador y sistemas sí son editables como escenas/scripts. Esta separación permite reemplazar el arte del suelo por un TileMap más adelante sin reprogramar las mecánicas.
"# Inferno_Videojuego2D" 
