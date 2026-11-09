extends Control
## Vista superior simplificada, basada en coordenadas reales del mapa.
var player: Node2D
var altar_step: int = 0
var soul_count: int = 0
var door_open: bool = false
var mode: String = "limbo"

func _process(_delta: float) -> void:
    queue_redraw()

func _pos(world: Vector2) -> Vector2:
    return Vector2(12.0 + (world.x / 1540.0) * 167.0, 10.0 + (world.y / 980.0) * 119.0)

func _draw() -> void:
    if mode == "lujuria":
        _draw_lujuria()
        return
    draw_rect(Rect2(6, 4, 178, 133), Color("#161b23"), true)
    draw_rect(Rect2(8, 6, 174, 129), Color("#9aa0a6"), false, 1.0)
    draw_rect(Rect2(48, 15, 96, 109), Color("#65727b"), false, 1.5)
    draw_line(_pos(Vector2(770, 164)), _pos(Vector2(770, 913)), Color("#4a555e"), 11.0, true)
    draw_line(_pos(Vector2(250, 358)), _pos(Vector2(1290, 358)), Color("#55616b"), 7.0, true)
    for box in [Rect2(118, 403, 360, 148), Rect2(1065, 403, 349, 148)]:
        draw_rect(Rect2(_pos(box.position), (box.size / Vector2(1540, 980)) * Vector2(167, 119)), Color("#2a373f"), true)
    draw_circle(_pos(Vector2(770, 442)), 5.0, Color("#22282d"))
    var shrines: Array[Vector2] = [Vector2(280, 352), Vector2(1255, 352), Vector2(770, 634)]
    for i in range(shrines.size()):
        draw_circle(_pos(shrines[i]), 4.0, Color("#cfd8dc") if i < altar_step else Color("#71818b"))
    draw_circle(_pos(Vector2(770, 172)), 5.0, Color("#d0dce5") if door_open else Color("#7b8389"))
    if player != null and is_instance_valid(player):
        var here: Vector2 = _pos(player.global_position)
        draw_circle(here, 5.3, Color("#d1a09a"))
        draw_circle(here, 2.3, Color("#fbf8ee"))

func _draw_lujuria() -> void:
    var floor_tint: Color = Color("#7b3f9e")
    draw_rect(Rect2(6, 4, 178, 133), Color("#17131f"), true)
    draw_rect(Rect2(8, 6, 174, 129), Color("#9e8ca7"), false, 1.0)
    var path: PackedVector2Array = PackedVector2Array([
        Vector2(85, 130), Vector2(85, 108), Vector2(48, 92), Vector2(35, 62),
        Vector2(62, 43), Vector2(70, 25), Vector2(117, 25), Vector2(127, 43),
        Vector2(158, 62), Vector2(146, 92), Vector2(109, 108), Vector2(109, 130)
    ])
    draw_colored_polygon(path, Color("#38303e"))
    for i in range(path.size()):
        draw_line(path[i], path[(i + 1) % path.size()], floor_tint, 1.5)
    for i in range(3):
        var position_on_map: Vector2 = [Vector2(97, 99), Vector2(54, 65), Vector2(139, 65)][i]
        draw_circle(position_on_map, 4.0, Color("#dfcfed") if i < altar_step else Color("#796786"))
    draw_circle(Vector2(97, 26), 4.0, Color("#b9edcb") if door_open else Color("#9374a3"))
    if is_instance_valid(player):
        var here: Vector2 = Vector2(8.0 + player.global_position.x / 1448.0 * 174.0, 6.0 + player.global_position.y / 1086.0 * 129.0)
        draw_circle(here, 5.0, Color("#b35c56"))
        draw_circle(here, 2.2, Color("#fff1e4"))
