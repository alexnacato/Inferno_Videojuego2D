# Plan de pruebas en Godot 4 — Proyecto unificado

**Prioridad 1: importación y compilación.** Importa `project.godot` en Godot 4.3+, deja terminar la importación, abre la pestaña **Errores** y comprueba que no aparezcan errores de parser GDScript ni dependencias faltantes. Si aparece alguno, registra el **archivo y número de línea**: no hay que ocultarlo ni ignorarlo.

**Prioridad 2: Limbo.** Inicia partida nueva; mueve a Dante con WASD y flechas; verifica escala de sprite, esquiva, colisiones de estanques/estatuas, interacción con Virgilio, lectura de la inscripción, orden de tres santuarios, decisiones de Elio y Livia, cuadros de pergamino, retratos, minimapa, pausa y guardado. Antes del desbloqueo, la puerta debe permanecer cerrada.

**Prioridad 3: transición.** Tras tres santuarios y dos decisiones, habla con la puerta del norte. Debe aparecer **Del silencio al vendaval**, mostrando Redención y Rigor. Pulsa **Continuar a Lujuria**; debe iniciar el círculo II sin cerrar la aplicación. Regresa al menú con Escape y usa **Continuar**: se debe restaurar el capítulo II, no el I.

**Prioridad 4: Dante y HUD.** Comprueba lado a lado que su tamaño en ambos capítulos sea equivalente; el dibujo de Dante se obtiene del mismo spritesheet y a la misma escala. Revisa que en Lujuria cambien título, minimapa y objetivos, pero no el marco ni retratos de la interfaz del Limbo. Prueba especialmente diálogos con Paolo y Francesca, dos botones y selección con teclado.

**Prioridad 5: Lujuria.** Prueba viento sobre Dante y enemigos, esquiva, ataque J, proyectil K, colisión del abismo, oleadas de diablillo, carcelero, espectro y furia, daño y regreso al checkpoint, tres sellos en orden, dos almas y la invocación de Minos. Valida sus dos fases y que aparezca y desaparezca su barra de vida. La puerta debe estar bloqueada hasta vencerlo.

**Prioridad 6: persistencia moral.** Anota Redención y Rigor al terminar el Limbo. Haz una elección compasiva y otra rigurosa en Lujuria y comprueba que se sumen al total previo. Cierra y reabre Godot; **Continuar** debe recuperar sellos, almas, derrotas y checkpoint sin duplicar puntos ni regenerar enemigos derrotados.

**Prioridad 7: cierre.** Al derrotar Minos, interactúa con la puerta norte. Debe verse la pantalla **Lujuria completada** con los valores acumulados. No se debe cargar Gula, porque aún no existe.

### Verificación automatizada realizada al empaquetar

- Todos los recursos `res://` constantes de escenas/scripts están presentes.
- Los spritesheets de Dante coinciden en dimensiones y escala entre capítulos.
- Hay 25 hojas PNG de enemigos (5 personajes × 5 acciones).
- La geometría de paseo de Lujuria conecta el punto de inicio con los siete objetivos.
- El error de inferencia del viento en enemigos está corregido declarando `Vector2`.
- La integridad del ZIP y sus archivos se valida antes de la entrega.

Estas pruebas estáticas **no equivalen** a una ejecución real de Godot ni garantizan ausencia total de bugs.
