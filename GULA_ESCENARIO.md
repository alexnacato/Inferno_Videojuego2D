# Escenario III: Gula

## Qué se construyó

El tercer círculo continúa después de la pantalla «Lujuria completada». Dante entra por el sur en un banquete arruinado bajo la lluvia. Dos rampas bordean un estanque de lodo y llevan a patios laterales; ambas se reúnen en la arena de Cerbero y la puerta del norte.

La regla propia de Gula es el **lodo**: al pisar los charcos marcados, Dante se mueve y esquiva más lentamente. En los patios hay dos ofrendas que se hunden al interactuar. Daria y Olmo plantean decisiones de Redención o Rigor. Tras hundir ambas ofrendas y decidir sobre las dos almas, aparece Cerbero. Vencerlo libera la puerta y abre la pantalla final del círculo.

## Enemigos de Gula

Hay seis apariciones repartidas en tres oleadas: la plaza sur, el patio oeste y el patio este. Cada tipo tiene escena propia heredada de `GulaEnemigo.tscn`, `CharacterBody2D`, colisión circular y `AnimatedSprite2D`. Como en Lujuria, se cargan hojas de seis fotogramas para `idle`, `walk`, `attack`, `hurt` y `death`. Su IA patrulla cerca del origen, persigue solo cuando ve a Dante, busca con A* su última posición conocida si lo pierde, avisa antes de atacar y se recupera entre ataques. La aceleración, el paso y la animación responden al desplazamiento real; el lodo modifica la velocidad según el tipo de criatura. Se guardan las oleadas activadas y los enemigos derrotados.

La vista [gula_colocacion_enemigos.png](assets/gula/world/gula_colocacion_enemigos.png) muestra los sprites con su escala real en las posiciones iniciales, a Dante en la entrada como referencia y a Cerbero en el punto donde aparece al completar los objetivos. Los cuadros pequeños señalan el punto de apoyo de cada personaje: naranja = Penitente, azul = Rastrero, violeta = Escanciador, amarillo = Cerbero, verde claro = Daria y Olmo, blanco = Dante. Se regenera con `tests/gula_placement_preview.gd`.

La vista [gula_recorridos_ia.png](assets/gula/world/gula_recorridos_ia.png) traza posiciones reales de la simulación sobre el mapa: amarillo claro en las dos rampas, amarillo fuerte en la arena y los colores de cada arquetipo en sus zonas. Se regenera con `tests/gula_ai_navigation_smoke.gd`, que también comprueba que cada actor permanezca en el suelo transitable.

| Enemigo | Escena | Conducta |
| --- | --- | --- |
| Penitente voraz | `scenes/GulaPenitente.tscn` | Persigue con peso, da un golpe con aviso y entra en furia al perder media vida. |
| Rastrero del lodo | `scenes/GulaRastrero.tscn` | Se acelera en el lodo y salta hacia una posición anticipada de Dante. |
| Escanciador corrupto | `scenes/GulaEscanciador.tscn` | Retrocede o se mueve de lado para mantener distancia y dispara bilis anticipando el movimiento de Dante. |

Cerbero conserva su escena `GulaCerbero.tscn`, ahora con `CharacterBody2D`, colisión y siete animaciones de seis fotogramas: `idle`, `walk`, `bite`, `howl`, `claw`, `hurt` y `death`. Custodia la arena, se acerca a Dante sin salir de ella y alterna mordida frontal, aullido con proyectiles y zarpazo circular. Cada ataque tiene animación y señal distintas. Al llegar a media vida acorta sus tiempos y el aullido pasa de tres a cinco proyectiles. Aparece tras completar las ofrendas y decisiones y despejar las oleadas normales.

Daria y Olmo tienen figuras pintadas de cuerpo entero y fondo transparente en los patios. Sus pies coinciden con su punto de interacción, tienen sombra discreta, no se pueden atravesar y su imagen aparece también en el retrato del diálogo. Daria lleva una cesta vacía; Olmo, su cuenco y cucharón de cocinero. Tras decidir sobre ellos permanecen visibles con un tono más tenue. Los avisos de ataque y barras de los enemigos normales usan colores distintos para reconocer cada criatura a escala jugable.

## Cómo se construyó en Godot

La ilustración de fondo, los cuatro enemigos, sus hojas de animación y las dos almas se generaron con la herramienta de imágenes de OpenAI. Lujuria se usó como **referencia de estructura de animación**. Los PNG se importaron al proyecto; `tests/gula_build_sprites.gd` normaliza las hojas originales a fotogramas de tamaño fijo y conserva los originales bajo `sheets/`. La imagen de fondo se muestra con un nodo **Sprite2D**.

La escena jugable se montó en **Godot 4.7.2**. Los nodos **Polygon2D** bajo `Suelo` y `Lodo` delimitan zonas transitables y zonas lentas. Los polígonos de ambas rampas y patios se ajustaron a la piedra visible; la navegación A* usa celdas de 20 píxeles para conservar la continuidad en las curvas estrechas. Sus vértices pueden ajustarse en la vista 2D del editor; un script los muestra con colores de guía en el editor y los oculta durante el juego. Los marcadores, el jugador, el jefe y la interfaz son nodos separados. Por tanto, es correcto decir que el nivel se **integró y delimitó con herramientas 2D de Godot**. La ilustración no se dibujó con TileMapLayer ni se produjo dentro de Godot.

Archivos principales:

| Archivo | Función |
| --- | --- |
| [gula_base.png](assets/gula/world/gula_base.png) | Mapa ilustrado que ve el jugador. |
| [gula_rutas.png](assets/gula/world/gula_rutas.png) | Vista de revisión: verde = suelo transitable; cuadrados claros = interacciones. |
| [Gula.tscn](scenes/Gula.tscn) | Escena 2D con mapa, polígonos, Dante, marcadores, enemigos e interfaz. |
| [gula.gd](scripts/gula.gd) | Rutas, lodo, objetivos, decisiones, guardado y salida. |
| [cerbero/idle.png](assets/gula/enemies/cerbero/idle.png) | Primera de las siete hojas animadas de Cerbero. |
| [daria.png](assets/gula/npcs/daria.png) y [olmo.png](assets/gula/npcs/olmo.png) | Figuras de las almas y origen de los retratos de diálogo. |
| [gula_cerbero.gd](scripts/gula_cerbero.gd) | Combate de Cerbero: mordida, aullido y zarpazo. |
| [gula_enemigo.gd](scripts/gula_enemigo.gd) | IA compartida de los tres enemigos normales. |
| [GulaEnemigo.tscn](scenes/GulaEnemigo.tscn) | Escena base con colisión y `AnimatedSprite2D`; las tres escenas individuales la heredan. |

## Abrir y mostrar al docente

1. Importar `project.godot` en Godot 4.7.2 y esperar la importación de imágenes.
2. Abrir `scenes/Gula.tscn` en el editor 2D. Mostrar el nodo `MapaPintado` y los polígonos bajo `Suelo` y `Lodo`.
3. Abrir `assets/gula/world/gula_rutas.png` para explicar entrada, patios, lodo, arena y salida.
4. Para jugar de forma directa, seleccionar `Gula.tscn` y pulsar **F6**. Para probar el flujo completo, terminar Lujuria y pulsar **Continuar a Gula**. La ejecución directa con F6 también actualiza el guardado del proyecto; usar una partida de prueba si se quiere conservar el progreso anterior.
5. Mostrar las oleadas de la plaza y los patios, un charco que ralentiza, una ofrenda que se hunde, una decisión de alma, la aparición de Cerbero al despejar los enemigos y la puerta norte tras vencerlo.

## Relación con el documento de concepto y la rúbrica

- **Coherencia:** mantiene el género 2D cenital, la ruta de descenso, la guía de Virgilio, las decisiones morales y la regla especial del tercer círculo: lodo que ralentiza y objetos que se hunden.
- **Visual:** piedra gris y sombras profundas con verde enfermizo como acento; la entrada, los patios laterales y la arena tienen siluetas distintas para orientar al jugador.
- **Objetos:** banquete arruinado, estatuas, arcos, lodo, ofrendas, Daria, Olmo, Cerbero y puerta norte.
- **Interacción:** dos rutas alrededor del estanque, dos patios explorables, charcos lentos, dos ofrendas, dos diálogos con elección, combate y salida condicionada.
- **Presentación grupal:** asignar a Gabriel, Alexander y Leidy solo los aportes que realmente hicieron; cada uno debe explicar una decisión visual o jugable y mostrarla en el mapa.

## Verificación

Se ejecutó `tests/gula_smoke.gd` con Godot 4.7.2. Comprueba la entrada, las zonas bloqueadas, el efecto del lodo, la accesibilidad de los seis puntos interactivos, las dos ofrendas, las dos decisiones, la aparición y derrota de Cerbero, el guardado y las pantallas de transición. Terminó con «Gula: todas las comprobaciones pasaron». La prueba anterior de navegación de Limbo y Lujuria también pasó después de integrar Gula.

La prueba `tests/gula_enemigos_smoke.gd` verifica que cada oleada se activa en su zona, los seis enemigos aparecen en suelo válido con cinco animaciones de seis fotogramas, que persiguen y atacan, que Cerbero tiene sus siete animaciones y cambia de fase, que un enemigo vencido no reaparece al reconstruir el nivel y que el jefe espera hasta despejar las oleadas. Se ejecuta con `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/gula_enemigos_smoke.gd`.

La revisión visual de rutas se generó con `tests/gula_visual_debug.gd`. `tests/gula_smoke.gd` comprueba que Daria y Olmo sean visibles, tengan alfa transparente, mantengan una escala adecuada, bloqueen el paso por su figura y muestren su retrato al hablar. Antes de publicar, hay que jugar una partida completa en una ventana de Godot para revisar a ojo animación, legibilidad del HUD, sonido y dificultad del combate.

## Texto breve para la exposición

«Gula es el tercer círculo de *Inferno: El Descenso*. El mapa conserva el estilo arquitectónico de los niveles anteriores, pero usa gris y verde enfermizo para mostrar un banquete en descomposición. La entrada está al sur y la salida al norte. Dos rutas rodean un estanque de lodo y llevan a patios donde el jugador hunde ofrendas y escucha a dos almas. El lodo ralentiza a Dante. Al completar los objetivos, Cerbero aparece en la arena superior y bloquea el descenso. La ilustración se generó como arte 2D y el escenario jugable se montó en Godot con Sprite2D, Polygon2D, marcadores y scripts».
