@tool
extends Node2D

@export var uid := ""
@export_enum("guia", "ofrenda", "alma", "puerta") var kind := "ofrenda"
@export var caption := ""
var completed := false
var near := false
var sink := 0.0
var elapsed := 0.0
var base_art_y := 0.0

@onready var art: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D

func _ready() -> void:
    if art != null:
        base_art_y = art.position.y
        art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
        preload("res://scripts/enemy_contrast.gd").apply(art)

func _process(delta: float) -> void:
    elapsed += delta
    if completed and kind == "ofrenda":
        sink = minf(sink + delta * 1.2, 1.0)
    if kind == "alma" and art != null:
        art.position.y = base_art_y + sin(elapsed * 1.5) * 0.7
        art.modulate = Color(0.94, 0.96, 0.91, 0.78 if completed else 1.0)
    queue_redraw()

func set_done(value: bool) -> void:
    completed = value
    sink = 1.0 if value else 0.0
    queue_redraw()

func _draw() -> void:
    if kind == "alma":
        draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.34))
        draw_circle(Vector2.ZERO, 19.0, Color(0.02, 0.025, 0.02, 0.38))
        draw_set_transform(Vector2.ZERO)
        if near:
            draw_arc(Vector2.ZERO, 27.0, 0.0, TAU, 36, Color(0.88, 0.96, 0.75, 0.82), 1.8)
        return
    var tint := Color("#98c66a") if completed else Color("#b7e26c")
    if kind == "puerta":
        tint = Color("#d4e7a1") if completed else Color("#9eac8a")
    elif kind == "guia":
        tint = Color("#e0dec9")
    var opacity := 1.0 - sink * 0.75 if kind == "ofrenda" else 1.0
    draw_circle(Vector2(0, 5), 22.0, Color(0.01, 0.025, 0.01, 0.35 * opacity))
    draw_circle(Vector2(0, sink * 14.0), 11.0, Color(tint.r, tint.g, tint.b, 0.52 * opacity))
    draw_arc(Vector2(0, sink * 14.0), 18.0, 0.0, TAU, 32, Color(tint.r, tint.g, tint.b, 0.85 * opacity), 2.5)
    if near:
        draw_arc(Vector2.ZERO, 28.0, 0.0, TAU, 36, Color("#ffffff"), 2.0)
