extends Node2D
var uid := ""
var caption := ""
var kind := "seal"
var complete := false
var near := false
var clock := 0.0
var art: Sprite2D
func _ready() -> void:
    if kind == "guide" or kind == "soul":
        art = Sprite2D.new()
        art.texture = preload("res://scripts/sprite_library.gd").frame("res://assets/violencia/almas_virgilio.png", 1 if kind == "guide" else 0, 0, 2, 1, Vector2i(80,128))
        art.position.y = -61
        art.scale = Vector2(1.0, 1.0)
        if kind == "soul":
            art.modulate = Color(0.88, 0.88, 0.87, 0.78)
        add_child(art)
        preload("res://scripts/enemy_contrast.gd").apply(art)
func _process(delta: float) -> void:
    clock += delta
    if art != null and kind == "soul":
        art.position.y = -61 + sin(clock*1.6)*3
    queue_redraw()
func _draw() -> void:
    var col := Color("bcb4a9") if complete else Color("d7958e")
    if kind == "seal":
        # Glifos desgastados sobre piedra: sin numeración ni medallón.
        var ink := Color(0.72,0.65,0.55,0.55 if complete else 0.24)
        if uid == "contencion":
            draw_polyline(PackedVector2Array([Vector2(-7,-4),Vector2(-3,3),Vector2(3,3),Vector2(7,-4)]),ink,1.2,true)
        elif uid == "memoria":
            draw_polyline(PackedVector2Array([Vector2(-6,4),Vector2(0,-5),Vector2(6,4),Vector2(0,1),Vector2(-6,4)]),ink,1.2,true)
        else:
            draw_line(Vector2(-6,3),Vector2(6,-3),ink,1.2,true)
            draw_line(Vector2(-6,-3),Vector2(6,3),ink,1.2,true)
        if complete:
            draw_circle(Vector2(0,-2),1.5,Color(0.85,0.68,0.44,0.35))
    if kind == "gate" and complete:
        # Luz muy tenue en el umbral ya dibujado; ninguna circunferencia.
        for i in range(7):
            var width := 8.0+float(i)*2
            draw_line(Vector2(-width,-float(i)*2),Vector2(width,-float(i)*2),Color(0.75,0.68,0.54,0.10-float(i)*0.01),2,true)
    if near:
        draw_string(ThemeDB.fallback_font,Vector2(-6,-86),"E",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color(0.94,0.89,0.8,0.85))
