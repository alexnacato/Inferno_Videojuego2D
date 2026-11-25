extends RefCounted

const SOURCES := {
    "lujuria": ["res://assets/lujuria/enemies/minos/death.png", Vector2i(176, 176), 1.24],
    "gula": ["res://assets/gula/enemies/cerbero/death.png", Vector2i(384, 384), 0.57],
    "violencia": ["res://assets/violencia/minotauro_frente_espalda_limpio.png", Vector2i(190, 210), 1.0],
    "traicion": ["res://assets/traicion/enemies/lucifer.png", Vector2i.ZERO, 0.21],
}

static func fall(actor: Node2D, art: Node2D, circle: String) -> void:
    var p := actor.global_position
    Game.progress["remains"][circle] = [p.x, p.y]
    var motion := actor.create_tween().set_parallel()
    motion.tween_property(art, "rotation", 1.45, 0.65)
    motion.tween_property(art, "position:y", -15.0, 0.65)
    motion.tween_property(art, "modulate", Color("#655b56"), 0.65)

static func restore(level: Node, circle: String) -> void:
    var p: Variant = Game.progress.get("remains", {}).get(circle)
    var spec: Variant = SOURCES.get(circle)
    if not p is Array or p.size() != 2 or spec == null:
        return
    var source: Texture2D = load(spec[0])
    var art := Sprite2D.new()
    art.name = "RestosDelJefe"
    art.texture = source
    var dimensions: Vector2i = spec[1]
    if dimensions != Vector2i.ZERO:
        art.region_enabled = true
        art.region_rect = Rect2(Vector2.ZERO, Vector2(dimensions))
    art.scale = Vector2.ONE * float(spec[2])
    art.position = Vector2(float(p[0]), float(p[1]) - 15.0)
    art.rotation = 1.45
    art.modulate = Color("#655b56")
    art.z_index = 2
    level.add_child.call_deferred(art)
