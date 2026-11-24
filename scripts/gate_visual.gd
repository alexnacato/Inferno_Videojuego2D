extends Node2D
## El portal se dibuja dentro de la abertura pintada, en coordenadas del escenario.
@export var aperture := Rect2(703, 48, 134, 172)
@export var tint := Color("#e9c787")
var lift := 0.0
var clock := 0.0
var animation: Tween
var open := false:
    set(value):
        if value == open:
            return
        open = value
        if not is_inside_tree():
            lift = 1.0 if value else 0.0
            return
        if animation != null:
            animation.kill()
        animation = create_tween()
        animation.tween_property(self, "lift", 1.0 if value else 0.0, 0.85).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
        if value:
            _sound()

static func install(level: Node2D, opening: Rect2, light: Color) -> Node2D:
    var portal := new()
    portal.aperture = opening
    portal.tint = light
    portal.z_index = -2
    level.add_child(portal)
    return portal

func _sound() -> void:
    var source := AudioStreamPlayer2D.new()
    source.position = Vector2(aperture.get_center().x, aperture.end.y)
    source.stream = preload("res://assets/audio/umbral.wav")
    source.volume_db = -13.0
    source.max_distance = 850.0
    add_child(source)
    source.finished.connect(source.queue_free)
    source.play()

func _process(delta: float) -> void:
    if open or lift > 0.0:
        clock += delta
        queue_redraw()
    elif clock > 0.0:
        clock = 0.0
        queue_redraw()

func _draw() -> void:
    if lift <= 0.0:
        return
    var half := aperture.size.x / 2.0
    var center := Vector2(aperture.get_center().x, aperture.position.y + half)
    var arch := PackedVector2Array([Vector2(aperture.position.x, aperture.end.y)])
    for i in range(25):
        var heading := Vector2.from_angle(PI + PI * float(i) / 24.0)
        arch.append(center + heading * half)
    arch.append(aperture.end)
    draw_colored_polygon(arch, Color(0.06, 0.05, 0.075, 0.98))
    var cut := lerpf(aperture.end.y, aperture.position.y, lift)
    for i in range(1, 9):
        var x := lerpf(aperture.position.x, aperture.end.x, float(i) / 9.0)
        var top := center.y - sqrt(maxf(0.0, half * half - pow(x - center.x, 2.0)))
        if cut > top:
            draw_line(Vector2(x, top), Vector2(x, cut), Color("#393038"), 7.0, true)
            draw_line(Vector2(x - 1, top), Vector2(x - 1, cut), Color("#9a7e62"), 2.0, true)
    var breath := 0.50 + sin(clock * 2.1) * 0.13
    draw_polyline(arch, Color(tint, lift * breath), 3.0, true)
    for i in range(19):
        var travel := fposmod(clock * (0.31 + (i % 4) * 0.03) + float(i) / 19.0, 1.0)
        var x := center.x + sin(i * 7.61 + clock * 0.8) * half * 0.79
        var y := lerpf(aperture.end.y - 3, center.y + 5, travel)
        draw_circle(Vector2(x, y), 1.3 + float(i % 3) * 0.65, Color(tint, sin(travel * PI) * breath * lift))
