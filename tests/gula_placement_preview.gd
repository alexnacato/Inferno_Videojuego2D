extends SceneTree

## Rebuilds a review image from the actual level spawns and sprite transforms.
const OUTPUT := "res://assets/gula/world/gula_colocacion_enemigos.png"

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var game: Node = root.get_node("Game")
    game.save_path = "res://.godot/gula_preview_test_save.json"
    game.set("progress", game.call("default_progress"))
    var progress: Dictionary = game.get("progress")
    progress["gula_intro_seen"] = true
    var level: Node2D = load("res://scenes/Gula.tscn").instantiate()
    root.add_child(level)
    await process_frame
    level._spawn_wave("entrada")
    level._spawn_wave("oeste")
    level._spawn_wave("este")
    level._spawn_boss()
    var canvas: Image = Image.load_from_file(ProjectSettings.globalize_path("res://assets/gula/world/gula_base.png"))
    if canvas == null or canvas.is_empty():
        push_error("No se pudo cargar el mapa de Gula")
        quit(1)
        return
    canvas.convert(Image.FORMAT_RGBA8)
    for actor in level.foes.get_children():
        var sprite: AnimatedSprite2D = actor.art
        var kind: String = "cerbero" if actor == level.boss else actor.archetype
        var source: Image = Image.load_from_file(ProjectSettings.globalize_path("res://assets/gula/enemies/" + kind + "/idle.png"))
        source.convert(Image.FORMAT_RGBA8)
        var size: int = 384 if actor == level.boss else 192
        source = source.get_region(Rect2i(0, 0, size, size))
        var scaled_size := Vector2i(maxi(1, roundi(source.get_width() * sprite.scale.x)),
            maxi(1, roundi(source.get_height() * sprite.scale.y)))
        source.resize(scaled_size.x, scaled_size.y, Image.INTERPOLATE_LANCZOS)
        var center: Vector2 = actor.global_position + sprite.position
        var corner := Vector2i(roundi(center.x - source.get_width() * 0.5), roundi(center.y - source.get_height() * 0.5))
        canvas.blend_rect(source, Rect2i(Vector2i.ZERO, source.get_size()), corner)
        var tint := Color("ffdf6e") if actor == level.boss else Color("ff8e6c") if actor.archetype == "penitente" else Color("6fd5ff") if actor.archetype == "rastrero" else Color("d799ff")
        var foot := Vector2i(actor.global_position)
        canvas.fill_rect(Rect2i(foot - Vector2i(6, 6), Vector2i(12, 12)), Color(0.03, 0.04, 0.02))
        canvas.fill_rect(Rect2i(foot - Vector2i(4, 4), Vector2i(8, 8)), tint)
    for soul in level.soul_nodes:
        var soul_sprite: Sprite2D = soul.art
        var source: Image = Image.load_from_file(ProjectSettings.globalize_path(soul_sprite.texture.resource_path))
        source.convert(Image.FORMAT_RGBA8)
        source.resize(roundi(source.get_width() * soul_sprite.scale.x),
            roundi(source.get_height() * soul_sprite.scale.y), Image.INTERPOLATE_LANCZOS)
        var center: Vector2 = soul.global_position + soul_sprite.position
        var corner := Vector2i(roundi(center.x - source.get_width() * 0.5),
            roundi(center.y - source.get_height() * 0.5))
        canvas.blend_rect(source, Rect2i(Vector2i.ZERO, source.get_size()), corner)
        var foot := Vector2i(soul.global_position)
        canvas.fill_rect(Rect2i(foot - Vector2i(3, 3), Vector2i(6, 6)), Color("9edb8c"))
    # Dante sirve como referencia de escala en la entrada del mapa.
    var hero_sprite: AnimatedSprite2D = level.hero.art
    var hero_image: Image = Image.load_from_file(ProjectSettings.globalize_path("res://assets/dante/idle.png"))
    hero_image.convert(Image.FORMAT_RGBA8)
    hero_image = hero_image.get_region(Rect2i(0, 0, 80, 96))
    hero_image.resize(roundi(80.0 * hero_sprite.scale.x), roundi(96.0 * hero_sprite.scale.y), Image.INTERPOLATE_LANCZOS)
    var hero_center: Vector2 = level.hero.global_position + hero_sprite.position
    var hero_corner := Vector2i(roundi(hero_center.x - hero_image.get_width() * 0.5),
        roundi(hero_center.y - hero_image.get_height() * 0.5))
    canvas.blend_rect(hero_image, Rect2i(Vector2i.ZERO, hero_image.get_size()), hero_corner)
    var hero_foot := Vector2i(level.hero.global_position)
    canvas.fill_rect(Rect2i(hero_foot - Vector2i(4, 4), Vector2i(8, 8)), Color("f5f2d6"))
    var result: Error = canvas.save_png(ProjectSettings.globalize_path(OUTPUT))
    level.queue_free()
    await process_frame
    print("Vista de colocación: ", OUTPUT, " (", result, ")")
    quit(0 if result == OK else 1)
