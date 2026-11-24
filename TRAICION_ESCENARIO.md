# Traición · Círculo IX · Cocito

Escenario final para el proyecto Godot 4 de **INFERNO: EL DESCENSO**.

## Contenido

- Mapa cenital `assets/traicion/world/cocito.png` (1448 × 1086 px), con ruinas, hielo, patios laterales y arena central.
- Escena jugable `scenes/Traicion.tscn`, con suelo y zonas de hielo fino editables como polígonos en Godot.
- Dos juramentos en los patios, dos almas con decisiones persistentes y combate contra Lucifer. Los ataques del jefe tienen avisos visibles y pueden esquivarse.
- HUD, minimapa, diálogos, guardado y final integrado en el proyecto.

## Abrir en Godot

1. Descomprime `INFERNO_TRAICION_GODOT.zip` en una carpeta nueva, o usa directamente esta carpeta.
2. En Godot 4, selecciona **Importar**, señala `project.godot` y espera la importación de las imágenes.
3. Ejecuta con **F5** y elige **Jugar Traición · Círculo IX**. También puedes abrir `scenes/Traicion.tscn` y usar **F6**.

**Controles:** WASD o flechas para moverse, Espacio para esquivar, E para interactuar, Q para una pista, J para atacar, K para lanzar un verso, 1/2 o clic para las decisiones y Esc para pausar.

La ruta natural desde Gula ofrece un acceso directo al final. Los círculos IV–VIII no están construidos en este proyecto.

## Comprobación

`node tests/traicion_geometry.cjs` verifica dimensiones de imágenes, suelo, abismo y rutas a los seis marcadores. Con Godot instalado: `godot --headless --path . --script res://tests/traicion_smoke.gd` comprueba carga, combate, decisiones y persistencia. La prueba de Godot crea una partida nueva; úsala con una carpeta de datos de usuario aislada si deseas conservar un guardado local.
