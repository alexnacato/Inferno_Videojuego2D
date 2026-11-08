extends Node2D
## Sombra suave que fija los pies del sprite sobre el pavimento.
func _draw() -> void:
    draw_set_transform(Vector2(0, -3), 0.0, Vector2(1.0, 0.32))
    draw_circle(Vector2.ZERO, 25.0, Color(0.0, 0.0, 0.0, 0.25))
    draw_circle(Vector2.ZERO, 16.0, Color(0.0, 0.0, 0.0, 0.16))
