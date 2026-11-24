extends SceneTree
## Regenera recursos de animación normalizados para evitar procesar PNG al aparecer.
func _initialize() -> void:
    call_deferred("build")
func build() -> void:
    var script = load("res://scripts/violencia_guardian.gd")
    for type in ["centauro","mastin","ceniza"]:
        var enemy = script.new()
        enemy.archetype = type
        var frames: SpriteFrames = enemy.build_library()
        var error := ResourceSaver.save(frames,"res://assets/violencia/enemies/%s_frames.res" % type,ResourceSaver.FLAG_COMPRESS)
        print(type, ": ", error)
        enemy.free()
        if error != OK:
            quit(1)
            return
    call_deferred("quit")
