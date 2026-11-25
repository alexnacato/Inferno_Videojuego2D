extends RefCounted

static func spirit(sprite: Sprite2D, guide: bool) -> void:
    preload("res://scripts/enemy_contrast.gd").apply(sprite)
    sprite.material.set_shader_parameter("light_edge", Color("#ffe1a0") if guide else Color("#c8eeff"))
    sprite.material.set_shader_parameter("outline_width", maxf(1.6, 2.2 / maxf(sprite.scale.x, 0.04)))
    sprite.material.set_shader_parameter("dark_edge", Color(0.12, 0.22, 0.31, 0.41))

static func seen(marker: Node2D, offset: Vector2 = Vector2(19, -14)) -> void:
    marker.draw_circle(offset, 8.0, Color("#253631"))
    marker.draw_polyline(PackedVector2Array([offset + Vector2(-4, 0), offset + Vector2(-1, 3), offset + Vector2(4, -3)]), Color("#d0e9aa"), 2.0, true)

static func interaction_pin(marker: Node2D) -> void:
    var center := Vector2(0, -3)
    var points := PackedVector2Array([center + Vector2(0,-6), center + Vector2(6,0), center + Vector2(0,6), center + Vector2(-6,0), center + Vector2(0,-6)])
    marker.draw_polyline(points, Color("#ebc68b"), 2.0, true)

static func footprint(point: Vector2, marker: Node2D, clearance: float = 0.0) -> bool:
    return ((point - marker.global_position) / Vector2(14.0 + clearance, 10.0 + clearance)).length_squared() < 1.0

static func shadow(marker: Node2D) -> void:
    marker.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.34))
    marker.draw_circle(Vector2.ZERO, 23, Color(0.08, 0.055, 0.04, 0.50))
    marker.draw_set_transform(Vector2.ZERO)

static func guide_sprite(marker: Node2D) -> Sprite2D:
    var art := Sprite2D.new()
    art.texture = preload("res://scripts/sprite_library.gd").frame("res://assets/violencia/almas_virgilio.png", 1, 0, 2, 1, Vector2i(80, 128))
    art.scale = Vector2.ONE * 1.18
    art.position.y = -76.0
    marker.add_child(art)
    spirit(art, true)
    return art
