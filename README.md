# INFERNO: EL DESCENSO — Limbo + Lujuria (Godot 4)

Este proyecto une **los dos ZIP proporcionados** en un solo `project.godot`. Conserva el Limbo como base visual y reutiliza en Lujuria **su interfaz, sus retratos y su sistema de diálogo con decisiones**. Los círculos aparecen uno tras otro sin cerrar el juego. El arte y las mecánicas originales se mantienen, salvo los cambios necesarios para unificar capítulos, controles y guardado.

## Abrir y jugar

1. Descomprime `INFERNO_EL_DESCENSO_LIMBO_LUJURIA_UNIFICADO.zip` en una carpeta nueva, **sin mezclarlo con tus dos proyectos anteriores**.
2. En **Godot 4.3 o superior**, selecciona **Importar**, elige el `project.godot` de esta carpeta y espera la importación de imágenes/audio.
3. Pulsa **F5**. El menú principal tiene **Comenzar un nuevo viaje** y **Continuar la partida**.
4. En el **Limbo**, resuelve Memoria → Saber → Compasión, escucha a Elio y Livia, y abre la puerta norte.
5. Aparece una pantalla de transición. Pulsa **Continuar a Lujuria** y Dante llegará al segundo círculo.
6. En **Lujuria**, activa Memoria → Aliento → Juicio, escucha a Paolo y Francesca, derrota a los demonios y a Minos, y abre la puerta norte.
7. Verás la pantalla de **Lujuria completada**. Gula no se ha creado todavía.

### Controles

| Teclas | Acción | Limbo | Lujuria |
|---|---|---|---|
| WASD / flechas | Movimiento en ocho direcciones | Sí | Sí |
| ESPACIO | Esquiva | Sí | Sí |
| E | Interacción / hablar | Sí | Sí |
| Q | Pista de Virgilio | Sí | Sí |
| 1 / 2 o clic | Elegir diálogo | Sí | Sí |
| J | Ataque cercano | No, deliberadamente | Sí |
| K | Verso de luz | No, deliberadamente | Sí |
| ESC | Pausar / reanudar | Sí | Sí |

## Unificación realizada

- **Interfaz:** la escena `scenes/HUD.tscn` y el script `scripts/hud.gd` provienen de Limbo. Los retratos de **Virgilio**, **alma**, y el estilo pergamino se reutilizan en ambos capítulos; el HUD cambia de título, objetivos y minimapa automáticamente.
- **Dante:** Lujuria usa el mismo archivo de sprites de Limbo (`assets/dante/`), con **celdas 80×96**, la **misma escala 1.24**, desplazamiento visual `(0,-58)` y zoom de cámara **0.96**. Su script separado conserva las mecánicas de combate, viento y daño. Se mantienen dos scripts de controlador para no alterar el Limbo sin combate.
- **Progreso:** `scripts/game_state.gd` es un autoload llamado `Game`. Usa **un solo archivo** `user://inferno_save_v2.json`; Redención y Rigor se acumulan a través de los círculos. Los progresos del Limbo y Lujuria tienen claves separadas para evitar sobreescrituras.
- **Transición:** el final del Limbo lleva a `Transicion.tscn` y después a `Lujuria.tscn`. Volver al menú y elegir **Continuar** lleva al capítulo actual.
- **Lujuria:** se preservaron el mapa, el viento, los sellos, las almas, las oleadas enemigas, Minos y los proyectiles. Sus recursos están en `assets/lujuria/` y sus scripts empiezan con `lujuria_` para evitar conflictos.
- **Corrección aplicada:** en `scripts/lujuria_enemigo.gd` se tipó explícitamente `wind` como `Vector2` para corregir el error de inferencia comunicado anteriormente.

## Archivos importantes

```text
project.godot
scenes/
  MenuPrincipal.tscn       # menú general
  Limbo.tscn               # capítulo I
  Transicion.tscn          # capítulo I → II
  Lujuria.tscn             # capítulo II
  FinLujuria.tscn          # cierre del contenido actual
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
assets/
  dante/                  # arte idéntico para ambos círculos
  ui/                     # retratos y estilo de Limbo
  world/                  # mapa original del Limbo
  lujuria/                # arte, audio, NPC y enemigos del segundo círculo
```

## Guardado y compatibilidad

El proyecto nuevo guarda el progreso en una carpeta de usuario correspondiente a su propio nombre. Los guardados de las **dos aplicaciones originales**, que tienen nombres de proyecto diferentes, **no se importan automáticamente**. Para comprobar la unión, inicia una **partida nueva** en este proyecto; no sobrescribe los ZIP originales.

Si quieres probar Lujuria directamente sin completar el Limbo, abre `scenes/Lujuria.tscn` en el editor y ejecútala con **F6**; esto es solo un atajo para desarrollo.

## Estado de calidad

Se realizó una validación **estática**: estructura de archivos, referencias de recursos, tamaños de sprites, transición, claves de guardado, corrección `Vector2` y una simulación de accesibilidad de los siete puntos interactivos de Lujuria. **No fue posible iniciar el motor Godot en este entorno**, por lo que las pruebas reales de scripts, audio, colisiones, rendimiento y flujo de combate deben completarse en el editor. Consulta `PRUEBAS.md` antes de considerar la versión libre de errores.
