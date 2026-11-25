extends Polygon2D

var actor: Node2D
var foot_y: float

static func install(map: Sprite2D, hero: Node2D, silhouette: PackedVector2Array, foot: float) -> void:
    var overlay := new()
    overlay.actor = hero
    overlay.z_index = hero.z_index + 1
    overlay.texture = map.texture
    var rect := map.get_rect()
    var uv := PackedVector2Array()
    var points := PackedVector2Array()
    var parent := hero.get_parent() as Node2D
    for point in silhouette:
        uv.append(point * map.texture.get_width() / 560.0)
        points.append(parent.to_local(map.to_global(rect.position + point * rect.size.x / 560.0)))
    overlay.uv = uv
    overlay.polygon = points
    overlay.foot_y = map.to_global(rect.position + Vector2(0, foot * rect.size.x / 560.0)).y
    parent.add_child(overlay)

func _process(_delta: float) -> void:
    visible = is_instance_valid(actor) and actor.global_position.y < foot_y
