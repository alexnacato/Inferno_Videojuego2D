# Pruebas en Godot 4 — Primer nivel: Limbo

Esta lista se ejecuta **en el editor de Godot**. Las comprobaciones automáticas de Python verifican archivos, PNG y alcanzabilidad, pero no prueban la ejecución del motor.

1. **Abrir:** importar `project.godot` y pulsar F5. Debe aparecer el menú inicial, con opción de nueva partida.
2. **Iniciar:** pulsar «Comenzar un nuevo viaje». Debe abrirse un diálogo introductorio de Virgilio; continuar con clic o tecla 1.
3. **Movimiento:** usar WASD y flechas. Dante debe mirar arriba, abajo, izquierda y derecha, desplazarse en diagonal y colisionar con las ruinas.
4. **Esquiva:** pulsar Espacio caminando y sin moverse. La esquiva debe durar una fracción de segundo y mostrar enfriamiento en el HUD.
5. **Restricción del Limbo:** probar J y K. Debe aparecer el mensaje de que este círculo no utiliza combate.
6. **Pistas:** pulsar Q sin diálogo activo. Debe indicar el siguiente santuario pendiente.
7. **Orden incorrecto:** activar «Saber» antes de «Memoria»; debe aparecer aviso, sin bloquear la progresión permanentemente.
8. **Acertijo:** activar Memoria, Saber, Compasión. El progreso debe pasar de 0/3 a 3/3. Probar que las estatuas y los estanques no se pueden atravesar.
9. **Elecciones:** hablar con Elio y Livia. Elegir opciones opuestas y comprobar las barras de Redención y Rigor. Las decisiones no deben repetirse.
10. **Puerta cerrada:** intentar usar la salida antes de completar todo; debe explicar qué falta.
11. **Puerta abierta:** completar ambos requisitos, subir al norte, interactuar con la puerta. Debe cargar `FinLimbo.tscn`.
12. **Guardado y menú:** iniciar otra partida, activar un santuario, pulsar Escape, guardar y volver al menú. Continuar y verificar que el santuario sigue activado y Dante aparece cerca de su posición guardada.
13. **Pantalla:** ejecutar a 1280 × 720 y maximizada; comprobar que textos y botones no se solapan.
14. **Salida:** cerrar desde el menú, sin mensajes rojos en el depurador.

## Notas

- La imagen de fondo es una composición 2D cenital inspirada directamente en las referencias compartidas; no es un TileMap editable celda a celda. Puedes sustituirla conservando los nodos de colisiones y la lógica del nivel.
- El nivel está diseñado sin combate, siguiendo la regla propia del Limbo; los ataques de los siguientes círculos serán un sistema adicional.
- El arte y los scripts son editables, pero se requiere probarlo en una instalación real de Godot 4.3+ antes de poder garantizar ausencia de errores de ejecución.
