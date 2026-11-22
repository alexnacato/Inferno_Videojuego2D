@tool
extends Node2D

@export var uid := ""
@export_enum("guia", "sello", "alma", "puerta") var kind := "sello"
@export var caption := ""
var completed := false
var near := false
var phase := 0.0

func _process(delta: float) -> void:
    phase += delta
    queue_redraw()

func set_done(value: bool) -> void:
    completed = value
    queue_redraw()

func _draw() -> void:
    var color := Color("#79d9ef") if completed else Color("#b5ebf7")
    if kind == "alma":
        color = Color("#d6e4f1")
    elif kind == "guia":
        color = Color("#e8ddc7")
    elif kind == "puerta":
        color = Color("#b9f5fa") if completed else Color("#607d89")
    draw_set_transform(Vector2(0, 7), 0.0, Vector2(1.0, 0.4))
    draw_circle(Vector2.ZERO, 20.0, Color(0.0, 0.05, 0.08, 0.45))
    draw_set_transform(Vector2.ZERO)
    var pulse := 1.0 + sin(phase * 2.4) * 0.08
    draw_circle(Vector2.ZERO, 10.0 * pulse, Color(color.r, color.g, color.b, 0.23))
    draw_arc(Vector2.ZERO, 18.0, 0.0, TAU, 32, color, 2.0)
    if kind == "sello":
        draw_line(Vector2(-8, 0), Vector2(8, 0), color, 2.5)
        draw_line(Vector2(0, -8), Vector2(0, 8), color, 2.5)
    if near:
        draw_arc(Vector2.ZERO, 27.0, 0.0, TAU, 36, Color.WHITE, 2.0)
