# Plan de pruebas en Godot 4 — Proyecto unificado

**Prioridad 1: importación y compilación.** Importa `project.godot` en Godot 4.7.2, deja terminar la importación, abre la pestaña **Errores** y comprueba que no aparezcan errores de parser GDScript ni dependencias faltantes. Si aparece alguno, registra el **archivo y número de línea**: no hay que ocultarlo ni ignorarlo.

**Prioridad 2: Limbo.** Inicia partida nueva; mueve a Dante con WASD y flechas; verifica escala de sprite, esquiva, colisiones de estanques/estatuas, interacción con Virgilio, lectura de la inscripción, orden de tres santuarios, decisiones de Elio y Livia, cuadros de pergamino, retratos, minimapa, pausa y guardado. Prueba Espacio junto a ambas orillas de los lagos: debe saltar y aterrizar en el camino opuesto; al caminar o esquivar, el agua debe bloquear el paso. Antes del desbloqueo, la puerta debe permanecer cerrada.

**Prioridad 3: transición.** Tras tres santuarios y dos decisiones, habla con la puerta del norte. Debe aparecer **Del silencio al vendaval**, mostrando Redención y Rigor. Pulsa **Continuar a Lujuria**; debe iniciar el círculo II sin cerrar la aplicación. Regresa al menú con Escape y usa **Continuar**: se debe restaurar el capítulo II, no el I.

**Prioridad 4: Dante y HUD.** Comprueba lado a lado que su tamaño en ambos capítulos sea equivalente; el dibujo de Dante se obtiene del mismo spritesheet y a la misma escala. Revisa que en Lujuria cambien título, minimapa y objetivos, pero no el marco ni retratos de la interfaz del Limbo. Prueba especialmente diálogos con Paolo y Francesca, dos botones y selección con teclado.

**Prioridad 5: Lujuria.** Prueba viento sobre Dante y enemigos, esquiva, ataque J, proyectil K, colisión del abismo, oleadas de diablillo, carcelero, espectro y furia, daño y regreso al checkpoint, tres sellos en orden, dos almas y la invocación de Minos. Recorre ambas plazas laterales y verifica que se pueda caminar por su suelo pero no por los huecos bajo los balcones. Comprueba las esculturas y retratos de Virgilio, Paolo y Francesca; Dante y los enemigos deben rodearlas. Dante no debe desplazarse solo por el viento ni quedar atrapado contra un enemigo. Valida que los enemigos rodeen la estatua sin atravesarla, no se superpongan ni golpeen a través de ella, y que sus animaciones de marcha se detengan cuando dejan de moverse. Revisa en la vista de colocación la escala de los cinco tipos; durante la partida, comprueba sus contornos sutiles sobre la piedra clara y los avisos de ataque diferentes. Minos debe permanecer en su plataforma durante ambas fases; su barra compacta debe quedar arriba sin tapar el combate y el título «II · LUJURIA» no debe invadir el minimapa. La puerta debe estar bloqueada hasta vencerlo.

**Prioridad 6: persistencia moral.** Anota Redención y Rigor al terminar el Limbo. Haz una elección compasiva y otra rigurosa en Lujuria y comprueba que se sumen al total previo. Cierra y reabre Godot; **Continuar** debe recuperar sellos, almas, derrotas y checkpoint sin duplicar puntos ni regenerar enemigos derrotados.

**Prioridad 7: transición a Gula.** Al derrotar Minos, interactúa con la puerta norte. Debe verse **Lujuria completada** con los valores acumulados. Pulsa **Continuar a Gula** y comprueba que abre el círculo III sin cerrar el juego.

**Prioridad 8: Gula.** Recorre la entrada sur, ambos patios laterales y la arena superior. Verifica que Dante no camina por el estanque central ni el abismo; los charcos deben ralentizar movimiento y esquiva. Entra en la plaza y en cada patio para activar las tres oleadas: Penitente, Rastrero y Escanciador. Comprueba que sus figuras no se salgan de las rampas, que caminen con paso distinto, que sus avisos de ataque se distingan por color y que sus animaciones cambien al atacar, recibir daño y morir. Interactúa con ambas ofrendas y confirma que se hunden. Localiza las figuras completas de Daria y Olmo en suelo libre de los patios, acércate sin atravesarlas y comprueba que sus retratos aparezcan al hablar. Toma decisiones y comprueba que Redención o Rigor se acumulan. Cerbero debe aparecer tras los cuatro objetivos y después de derrotar a los enemigos normales; revisa su barra de salud, mordida, aullido, zarpazo, animaciones y segunda fase. Derrotarlo debe liberar la puerta norte y abrir **Gula completada**. Vuelve al menú y elige **Continuar** para comprobar que no reaparecen los enemigos derrotados ni se pierden las decisiones.

**Prioridad 9: Violencia.** Desde **Gula completada**, pulsa **Continuar a Violencia** y confirma que abre el círculo VII. Cruza solo el puente del Flegetonte, localiza a Virgilio, al guardia y al testigo, y activa los votos Contención → Memoria → Tregua tras derrotar a sus guardianes. Comprueba que centauro, mastín y ceniza aparecen en suelo válido, no se duplican al volver al pilar y usan sus ataques y animaciones de cuatro direcciones. La arena caliente debe avisar antes de causar daño; la piedra central debe ser segura. Minotauro debe cargar en la dirección anunciada, quedar aturdido al chocar, cambiar de fase y abrir la salida al caer. Guarda y continúa la partida para comprobar votos, decisiones, enemigos vencidos y mejora de esquiva.

**Prioridad 10: Traición después de Violencia.** En **Violencia completada**, pulsa **Continuar a Traición**. Comprueba que aparece Cocito, que Redención y Rigor no se reinician y que la esquiva mejorada conserva duración, protección y recarga tras cerrar y continuar la partida.

**Prioridad 11.** En Traición, activa F3 para comparar las colisiones con el mapa. Rodea los monumentos y las columnas. Combate contra el custodio, el sabueso y el espectro, rompe ambos juramentos y toma las decisiones de Ugolino y Bocca. Lee la inscripción y enciende el brasero. Comprueba el hielo fino, las dos fases de Lucifer y la ventana de daño marcada por su anillo dorado. Deja que Dante caiga y verifica que vuelve al último punto de descanso sin proyectiles pendientes. Guarda y continúa para comprobar que los guardianes vencidos no reaparecen. Vence a Lucifer, usa la salida y verifica que **Continuar** conserva la pantalla final.

### Verificación automatizada

`godot --headless --path . --script res://tests/menu_flow_smoke.gd`

La prueba de menús necesita un `APPDATA` temporal sin campaña previa. Comprueba botones con eventos de teclado y ratón, configuración, selección de niveles, pausa y cierres. Para generar capturas, ejecuta el mismo comando sin `--headless` y define `INFERNO_UI_CAPTURES` con la ruta de una carpeta de salida existente.

`godot --headless --path . --script res://tests/navigation_smoke.gd`

`godot --headless --path . --script res://tests/gula_smoke.gd`

`godot --headless --path . --script res://tests/gula_enemigos_smoke.gd`

`godot --headless --path . --script res://tests/lujuria_enemigos_smoke.gd`

`godot --headless --path . --script res://tests/gula_ai_navigation_smoke.gd`

`godot --headless --path . --script res://tests/three_circles_smoke.gd`

`godot --headless --path . --script res://tests/violencia_full_smoke.gd`

`godot --headless --path . --script res://tests/violencia_guardians_smoke.gd`

`godot --headless --path . --script res://tests/violencia_integration_smoke.gd`

`godot --headless --path . --script res://tests/five_circles_smoke.gd`

`godot --headless --path . --script res://tests/traicion_smoke.gd`

`navigation_smoke.gd` comprueba las rutas de Limbo y Lujuria; `lujuria_enemigos_smoke.gd` simula sus cinco tipos enemigos. Las pruebas de Gula revisan objetivos, enemigos y navegación. Las pruebas de Violencia cubren 50 comprobaciones del nivel, 57 de guardianes y la integración con guardado, HUD y recompensa; `five_circles_smoke.gd` recorre los cinco escenarios. Las pruebas que pasan por el menú y `traicion_smoke.gd` usan el guardado de usuario. En Windows, ejecútalas con `APPDATA` apuntando a una carpeta temporal para aislarlas de tu campaña. La revisión visual y de audio sigue requiriendo una partida manual.
