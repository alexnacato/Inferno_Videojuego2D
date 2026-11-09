extends Node2D
## Oscurece la reja del concepto cuando el puzzle está completado.
var open: bool = false
var tick: float = 0.0
func _process(delta: float) -> void:
    tick += delta
    queue_redraw()
func _draw() -> void:
    if not open:
        return
    # Interior del arco del portal. Los ornamentos permanecen en el fondo.
    var fog: Color = Color(0.050, 0.063, 0.083, 0.94)
    draw_circle(Vector2(770, 116), 52.0, fog)
    draw_rect(Rect2(718, 116, 104, 72), fog, true)
    var glow: float = 0.34 + 0.18 * (sin(tick * 2.0) * 0.5 + 0.5)
    draw_arc(Vector2(770, 116), 52.0, PI, TAU, 36, Color(0.72, 0.82, 0.87, glow), 2.0, true)
    for i in range(6):
        var p: Vector2 = Vector2(740.0 + i * 13.0, 139.0 + sin(tick * 1.2 + i) * 18.0)
        draw_circle(p, 2.0 + sin(tick * 0.5 + i), Color(0.75, 0.82, 0.85, glow * 0.55))
