extends Node2D
## Lightweight stylized current glyphs; the actual force lives in lujuria.gd.
var world_ref
var time := 0.0

func _process(delta: float) -> void:
    time += delta
    queue_redraw()

func _draw() -> void:
    if world_ref == null:
        return
    for section in [
        {"rect": Rect2(149, 438, 402, 110), "dir": Vector2(1, 0.20), "id": "sello_izquierdo"},
        {"rect": Rect2(890, 440, 408, 108), "dir": Vector2(-1, 0.24), "id": "sello_derecho"},
        {"rect": Rect2(559, 283, 320, 85), "dir": Vector2(0.4, -0.9), "id": "sello_inicio"},
    ]:
        var rect: Rect2 = section["rect"]
        var dir: Vector2 = section["dir"]
        var done: bool = str(section["id"]) in world_ref.seals
        for i in range(12):
            var x: float = rect.position.x + fposmod(i * 68.0 + time * (23.0 if done else 72.0), rect.size.x)
            var y: float = rect.position.y + 17.0 + fposmod(float(i) * 28.7, rect.size.y - 28.0)
            var p := Vector2(x, y)
            var opacity := 0.20 if done else 0.52
            draw_arc(p, 8.0 + float(i % 3) * 2.0, 0.1, 2.65, 18, Color(0.72, 0.42, 0.91, opacity), 2.0)
            draw_line(p, p + dir * 22.0, Color(0.69, 0.42, 0.89, opacity), 1.7)
    if world_ref.pulse_left > 0.0:
        var r: float = 230.0 * (0.70 - world_ref.pulse_left) / 0.70
        draw_arc(world_ref.pulse_at, maxf(5.0, r), 0.0, TAU, 76, Color(0.78, 0.44, 0.94, world_ref.pulse_left), 4.0)
