# INFERNO: EL DESCENSO — Limbo + Lujuria + Gula + Violencia + Traición (Godot 4)

## Recorrido actual

El recorrido principal es **Limbo → Lujuria → Gula → Violencia → Traición**. Violencia, el círculo VII, procede de `C:\Users\alexa\Proyecto`: incluye el río de sangre, los votos, dos almas, tres guardianes, el Minotauro y la mejora permanente de esquiva. Traición, el círculo IX, continúa después de su pantalla final. Los círculos IV–VI y VIII no están implementados.

Abre el `project.godot` de esta carpeta en Godot 4.7.2 y pulsa F5. El ZIP anterior de Traición no incluye esta integración.

La geometría del mapa se puede revisar con `node tests/traicion_geometry.cjs`. En una instalación de Godot, la prueba jugable se ejecuta con `godot --headless --path . --script res://tests/traicion_smoke.gd`.

Los cinco escenarios comparten interfaz, decisiones morales y un archivo de guardado. La opción **Continuar la partida** recupera el círculo activo o su pantalla de cierre.

## Abrir y jugar

En esta carpeta puedes abrir `JUGAR_RECORRIDO.bat` para iniciar el juego con el Godot 4.7.2 situado junto al proyecto. En el menú elige **Comenzar un nuevo viaje**.

1. En **Godot 4.7.2**, selecciona **Importar**, elige el `project.godot` de esta carpeta y espera la importación de imágenes/audio.
2. Pulsa **F5**. El menú principal permite comenzar, continuar o jugar directamente Traición.
3. En el **Limbo**, resuelve Memoria → Saber → Compasión, escucha a Elio y Livia, y abre la puerta norte.
4. Aparece una pantalla de transición. Pulsa **Continuar a Lujuria** y Dante llegará al segundo círculo.
5. En **Lujuria**, activa Memoria → Aliento → Juicio, escucha a Paolo y Francesca, derrota a los demonios y a Minos, y abre la puerta norte.
6. En **Lujuria completada**, pulsa **Continuar a Gula**.
7. En **Gula**, atraviesa el lodo, hunde las dos ofrendas, escucha a Daria y Olmo, derrota a Cerbero y abre la puerta norte.
8. En **Gula completada**, pulsa **Continuar a Violencia**. Cruza el Flegetonte, enciende Contención → Memoria → Tregua, escucha al guardia y al testigo y derrota al Minotauro.
9. En **Violencia completada**, pulsa **Continuar a Traición**. Rompe los dos juramentos, escucha a Ugolino y Bocca, vence a Lucifer y cruza la salida.

### Controles

| Teclas | Acción | Limbo | Lujuria | Gula | Violencia | Traición |
|---|---|---|---|---|---|---|
| WASD / flechas | Movimiento en ocho direcciones | Sí | Sí | Sí | Sí | Sí |
| ESPACIO | Esquiva; salto contextual entre orillas en Limbo | Sí | Sí | Sí | Sí | Sí |
| E | Interacción / hablar | Sí | Sí | Sí | Sí | Sí |
| Q | Pista de Virgilio | Sí | Sí | Sí | Sí | Sí |
| 1 / 2 o clic | Elegir diálogo | Sí | Sí | Sí | Sí | Sí |
| J | Ataque cercano | No | Sí | Sí | Sí | Sí |
| K | Verso de luz | No | Sí | Sí | Sí | Sí |
| ESC | Pausar / reanudar | Sí | Sí | Sí | Sí | Sí |

## Unificación realizada

- **Interfaz:** la escena `scenes/HUD.tscn` y el script `scripts/hud.gd` se comparten entre los cinco capítulos. El HUD cambia de título, objetivos y minimapa automáticamente.
- **Dante:** Lujuria usa el mismo archivo de sprites de Limbo (`assets/dante/`), con **celdas 80×96**, la **misma escala 1.24**, desplazamiento visual `(0,-58)` y zoom de cámara **0.96**. Su script separado conserva las mecánicas de combate, viento y daño. Se mantienen dos scripts de controlador para no alterar el Limbo sin combate.
- **Progreso:** `scripts/game_state.gd` es un autoload llamado `Game`. Usa **un solo archivo** `user://inferno_save_v2.json`; Redención y Rigor se acumulan a través de los círculos. Violencia guarda sus votos, decisiones, guardianes y jefe en una sección propia.
- **Transición:** el final del Limbo lleva a `Transicion.tscn` y después a `Lujuria.tscn`. Volver al menú y elegir **Continuar** lleva al capítulo actual.
- **Lujuria:** se preservaron el mapa, el viento, los sellos, las almas, las oleadas enemigas, Minos y los proyectiles. Sus recursos están en `assets/lujuria/` y sus scripts empiezan con `lujuria_` para evitar conflictos.
- **Gula:** un mapa ilustrado nuevo se montó en Godot como `Sprite2D`; polígonos `Polygon2D` editables delimitan suelo y lodo. Incluye dos ofrendas que se hunden, dos decisiones morales y Cerbero con tres ataques. Consulta [GULA_ESCENARIO.md](GULA_ESCENARIO.md) para la explicación de diseño y la procedencia del arte.
- **Violencia:** el mapa y sus recursos se copiaron desde `C:\Users\alexa\Proyecto` a `assets/violencia/`; `scenes/Violencia.tscn` usa el Dante y el HUD de este proyecto. La pantalla final de Gula abre Violencia y la de Violencia abre Traición. La victoria ante el Minotauro mejora la esquiva y conserva la mejora en Traición.
- **Movimiento y colisiones:** Dante recorre el suelo visible con una zona de apoyo ajustada a sus pies. Al tocar un borde conserva el avance hasta él y se desliza por las curvas sin atravesarlas. En Limbo no puede caminar sobre los lagos; Espacio salta entre orillas cuando hay un aterrizaje seguro. En Lujuria se pueden recorrer las plazas laterales y se bloquean los huecos bajo sus balcones; el viento no arrastra a Dante en reposo y los enemigos no crean muros móviles.
- **Enemigos:** patrullan, buscan la última posición conocida de Dante y siguen rutas alrededor de la estatua; su animación de marcha responde al desplazamiento real. Los diablillos intentan flanquear, los espectros conservan distancia y Minos permanece en su plataforma. Cada tipo tiene un tono y contorno discretos, sombra, barra y aviso de ataque propios para distinguirlo de la piedra clara del mapa. La [vista de colocación](assets/lujuria/world/lujuria_colocacion_enemigos.png) muestra su escala y posición inicial respecto a Dante.
- **Interfaz:** la barra de Minos ocupa una franja compacta arriba, junto al rótulo «II · LUJURIA». El centro de la pantalla queda libre durante el combate.
- **Personajes de Lujuria:** Virgilio, Paolo y Francesca son esculturas de piedra de cuerpo completo inspiradas directamente en el diseño del Limbo. Su tamaño es comparable al de las figuras del mapa, conservan la misma posición durante la interacción y sus rostros aparecen en los diálogos. Los recursos y sus instrucciones de generación están en `assets/lujuria/npcs/`.

## Archivos importantes

```text
project.godot
scenes/
  MenuPrincipal.tscn       # menú general
  Limbo.tscn               # capítulo I
  Transicion.tscn          # capítulo I → II
  Lujuria.tscn             # capítulo II
  FinLujuria.tscn          # transición II → III
  Gula.tscn                # capítulo III
  GulaCerbero.tscn         # guardián de Gula
  FinGula.tscn             # transición III → VII
  Violencia.tscn           # capítulo VII
  FinViolencia.tscn        # transición VII → IX
  Traicion.tscn            # capítulo IX
  Dante.tscn               # personaje del Limbo
  DanteLujuria.tscn        # mismo aspecto/escala, combate activo
  HUD.tscn                 # interfaz única reutilizada
  LujuriaEnemigo.tscn      # IA enemiga reutilizable
scripts/
  game_state.gd            # progreso moral de todo el viaje
  hud.gd                   # interfaz, retratos, dialogo de almas
  limbo.gd                 # lógica Limbo
  lujuria.gd               # lógica Lujuria y encuentros
  lujuria_enemigo.gd       # IA, Minos y efectos de viento
  lujuria_dante.gd         # movimiento/combate en Lujuria
  gula.gd                  # suelo, lodo, objetivos y progreso de Gula
  gula_cerbero.gd          # comportamiento de Cerbero
  violencia.gd             # votos, combate y progreso de Violencia
  violencia_guardian.gd    # guardianes de los tres pilares
assets/
  dante/                  # arte idéntico para ambos círculos
  ui/                     # retratos y estilo de Limbo
  world/                  # mapa original del Limbo
  lujuria/                # arte, audio, NPC y enemigos del segundo círculo
  gula/                   # mapa, plano de rutas y cuatro enemigos animados del tercer círculo
  violencia/              # mapa, audio, almas, guardianes y Minotauro
```

## Guardado y compatibilidad

El proyecto nuevo guarda el progreso en una carpeta de usuario correspondiente a su propio nombre. Los guardados de las **dos aplicaciones originales**, que tienen nombres de proyecto diferentes, **no se importan automáticamente**. Para comprobar la unión, inicia una **partida nueva** en este proyecto; no sobrescribe los ZIP originales.

Para probar un círculo directamente, abre su escena en el editor y ejecútala con **F6**. Es un atajo de desarrollo que también actualiza el guardado; usa una partida de prueba si deseas conservar tu progreso.

## Comprobación

La importación y las pruebas automáticas se ejecutaron con **Godot 4.7.2**. `violencia_full_smoke.gd` pasó 50 comprobaciones y `violencia_guardians_smoke.gd` pasó 52; `five_circles_smoke.gd` recorrió Limbo → Lujuria → Gula → Violencia → Traición.

Para repetir las pruebas desde la carpeta del proyecto, usa los comandos de [PRUEBAS.md](PRUEBAS.md). La revisión visual y de audio sigue requiriendo una partida manual en una ventana de Godot.
