@tool
extends Node2D

@export var uid := ""
@export_enum("guia", "sello", "alma", "puerta") var kind := "sello"
@export var caption := ""
var completed := false
var near := false
var phase := 0.0

var art: Sprite2D

func _ready() -> void:
    if kind not in ["guia", "alma"]:
        return
    art = Sprite2D.new()
    art.texture = preload("res://scripts/sprite_library.gd").frame(
        "res://assets/violencia/almas_virgilio.png", 1 if kind == "guia" else 0, 0, 2, 1, Vector2i(80, 128))
    art.position.y = -56.0
    art.self_modulate = Color("#e9d9ba") if kind == "guia" else Color("#cce8ff")
    add_child(art)
    preload("res://scripts/enemy_contrast.gd").apply(art)

func _process(delta: float) -> void:
    phase += delta
    if is_instance_valid(art):
        art.position.y = -56.0 + sin(phase * 1.5) * (2.5 if kind == "alma" else 0.7)
    queue_redraw()

func set_done(value: bool) -> void:
    completed = value
    queue_redraw()

func _draw() -> void:
    if kind == "puerta":
        return
    if kind != "sello":
        if near:
            draw_line(Vector2(-12, 4), Vector2(12, 4), Color("#dff4ff"), 2.0, true)
        return
    var tint := Color("#8ca1b0") if completed else Color("#bcf6ff")
    var center := Vector2(0, -17) + Vector2.UP * sin(phase * 2.0) * 2.7
    var hull := PackedVector2Array([center + Vector2(0,-21), center + Vector2(16,0), center + Vector2(0,22), center + Vector2(-16,0)])
    draw_colored_polygon(hull, Color("#1b2e3d"))
    hull.append(hull[0])
    draw_polyline(hull, tint, 2.0, true)
    draw_polyline(PackedVector2Array([center + Vector2(6,-15), center + Vector2(-5,-2), center + Vector2(4,1), center + Vector2(-5,14)]), tint, 3.0 if near else 1.8, true)
    if not completed:
        for i in range(5):
            var rise := fposmod(phase * 0.42 + i * 0.2, 1.0)
            draw_circle(center + Vector2(sin(i * 4.0 + phase) * 15.0, -rise * 34.0), 1.7, Color(tint, sin(rise * PI)))
