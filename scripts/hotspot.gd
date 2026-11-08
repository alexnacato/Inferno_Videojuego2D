extends Node2D
## Marcador discreto, con el gris frío del Limbo. En otros círculos cambia el acento.
var kind: String = "altar"
var completed: bool = false
var hovered: bool = false
var t: float = 0.0
var accent: Color = Color("#9aa0a6")

func _process(delta: float) -> void:
    t += delta
    queue_redraw()

func _draw() -> void:
    var pulse: float = sin(t * 2.1) * 0.5 + 0.5
    var col: Color = accent.lightened(0.14)
    if kind == "soul":
        col = Color("#d8dfeb")
    if kind == "guide":
        col = Color("#dedbd1")
    var transparency: float = 0.30 if completed else 0.74
    draw_circle(Vector2(0, 0), 19.0 + pulse * 3.0, Color(col.r, col.g, col.b, transparency * 0.11))
    draw_arc(Vector2.ZERO, 14.0 + pulse * 2.0, 0.0, TAU, 30, Color(col.r, col.g, col.b, transparency * (0.65 if hovered else 0.42)), 1.6, true)
    if hovered:
        draw_arc(Vector2.ZERO, 23.0, 0.0, TAU, 40, Color(col.r, col.g, col.b, 0.82), 1.5, true)
    if kind == "altar":
        var poly: PackedVector2Array = PackedVector2Array([Vector2(0, -7), Vector2(7, 0), Vector2(0, 7), Vector2(-7, 0)])
        draw_colored_polygon(poly, Color(0.10, 0.15, 0.18, 0.62))
        for i in range(4):
            draw_line(poly[i], poly[(i + 1) % 4], col, 1.3, true)
    elif kind == "gate":
        draw_line(Vector2(-7, 6), Vector2(0, -8), col, 2.0, true)
        draw_line(Vector2(0, -8), Vector2(7, 6), col, 2.0, true)
    else:
        draw_circle(Vector2.ZERO, 3.0, Color(col.r, col.g, col.b, 0.96))
