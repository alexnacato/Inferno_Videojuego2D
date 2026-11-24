extends Node2D
## Destello de contacto o barrido. Nunca interviene en el cálculo de daño.
var reach := 0.0
var angle := 0.0
var radial := false
var color := Color.WHITE
var phase := 0.0

static func burst(source: Node2D, origin: Vector2, direction: Vector2, radius: float, tint: Color) -> void:
    var fx := new()
    fx.reach = radius
    fx.angle = direction.angle()
    fx.radial = direction.is_zero_approx()
    fx.color = tint
    fx.z_index = 14
    source.add_child(fx)
    fx.top_level = true
    fx.global_position = origin
    var animation := fx.create_tween()
    animation.tween_method(fx._advance, 0.0, 1.0, 0.24)
    animation.tween_callback(fx.queue_free)

func _advance(value: float) -> void:
    phase = value
    queue_redraw()

func _draw() -> void:
    var fade := pow(1.0 - phase, 1.7)
    var radius := reach * lerpf(0.44, 1.0, phase)
    var start := 0.0 if radial else angle - 0.85 + phase * 0.45
    var finish := TAU if radial else start + 1.25
    draw_arc(Vector2.ZERO, radius, start, finish, 44, Color(0.09, 0.05, 0.10, fade * 0.83), 12.0 * fade + 1.0, true)
    draw_arc(Vector2.ZERO, radius, start, finish, 44, Color(color, fade), 7.0 * fade + 1.0, true)
    for i in range(11):
        var heading := Vector2.from_angle(lerpf(start, finish, float(i) / 11.0))
        var tip := heading * radius * (1.03 + float(i % 3) * phase * 0.26)
        draw_line(tip - heading * (8.0 + float(i % 4) * 3.0), tip, Color(color, fade), 2.0, true)
