extends RefCounted

static func spirit(sprite: Sprite2D, guide: bool) -> void:
    preload("res://scripts/enemy_contrast.gd").apply(sprite)
    sprite.material.set_shader_parameter("light_edge", Color("#ffe1a0") if guide else Color("#c8eeff"))
    sprite.material.set_shader_parameter("outline_width", maxf(1.6, 2.2 / maxf(sprite.scale.x, 0.04)))
    sprite.material.set_shader_parameter("dark_edge", Color(0.12, 0.22, 0.31, 0.41))

static func seen(marker: Node2D, offset: Vector2 = Vector2(19, -14)) -> void:
    marker.draw_circle(offset, 8.0, Color("#253631"))
    marker.draw_polyline(PackedVector2Array([offset + Vector2(-4, 0), offset + Vector2(-1, 3), offset + Vector2(4, -3)]), Color("#d0e9aa"), 2.0, true)

static func guide_sprite(marker: Node2D) -> Sprite2D:
    var art := Sprite2D.new()
    art.texture = preload("res://scripts/sprite_library.gd").frame("res://assets/violencia/almas_virgilio.png", 1, 0, 2, 1, Vector2i(80, 128))
    art.scale = Vector2.ONE * 1.18
    art.position.y = -76.0
    marker.add_child(art)
    spirit(art, true)
    return art
