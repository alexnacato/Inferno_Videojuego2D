@tool
extends Node2D

@export var uid := ""
@export_enum("guia", "sello", "alma", "puerta", "inscripcion", "brasero") var kind := "sello"
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
    var custom := load_soul(uid)
    if kind == "alma" and custom != null:
        art.texture = custom
    art.position.y = -69.0
    art.scale = Vector2.ONE * (1.19 if kind == "guia" else 1.06)
    if kind == "alma" and custom != null:
        art.scale = Vector2.ONE * (138.0 / art.texture.get_height())
    art.self_modulate = Color("#e9d9ba") if kind == "guia" else Color("#cce8ff")
    add_child(art)
    preload("res://scripts/interaction_visual.gd").spirit(art, kind == "guia")

static func load_soul(id: String) -> Texture2D:
    if id == "alma_ugolino":
        return preload("res://assets/traicion/npcs/judas.png")
    if id == "alma_bocca":
        return preload("res://assets/traicion/npcs/hitler.png")
    return null

static func portrait_for(id: String) -> Texture2D:
    var source := load_soul(id)
    if source == null:
        return preload("res://assets/ui/retrato_alma.png")
    var portrait := AtlasTexture.new()
    portrait.atlas = source
    var size := source.get_size()
    var side := minf(size.x, size.y * 0.34)
    portrait.region = Rect2((size.x - side) * 0.5, 0.0, side, side)
    return portrait

func _process(delta: float) -> void:
    phase += delta
    if is_instance_valid(art):
        art.position.y = -76.0 if kind == "guia" else -69.0 + sin(phase * 1.5) * 5.0
        art.modulate.a = 0.68 if completed else 1.0
    queue_redraw()

func set_done(value: bool) -> void:
    completed = value
    queue_redraw()

func _draw() -> void:
    if near:
        preload("res://scripts/interaction_visual.gd").interaction_pin(self)
    if kind == "guia":
        preload("res://scripts/interaction_visual.gd").shadow(self)
    if completed and kind in ["sello", "alma"]:
        preload("res://scripts/interaction_visual.gd").seen(self)
    if kind == "puerta":
        return
    if kind == "inscripcion":
        draw_rect(Rect2(-12, -30, 24, 31), Color("#243851"))
        draw_rect(Rect2(-12, -30, 24, 31), Color("#bddef2"), false, 2.0)
        for y in [-23.0, -16.0, -9.0]:
            draw_line(Vector2(-6.0, y), Vector2(6.0, y), Color("#9ec7e2"), 2.0)
        return
    if kind == "brasero":
        var glow := Color("#fac18a") if completed else Color("#83c6eb")
        draw_circle(Vector2.ZERO, 11.0, Color(0.03, 0.07, 0.12, 0.65))
        draw_colored_polygon(PackedVector2Array([Vector2(-15, -16), Vector2(15, -16), Vector2(7, 0), Vector2(-7, 0)]), Color("#32445c"))
        draw_line(Vector2(-15, -16), Vector2(15, -16), glow, 3.0, true)
        draw_circle(Vector2(0, -24), 14.0, Color(glow, 0.22 if completed else 0.12))
        if completed:
            draw_circle(Vector2(0, -23), 6.0 + sin(phase * 8.0) * 1.7, glow)
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
