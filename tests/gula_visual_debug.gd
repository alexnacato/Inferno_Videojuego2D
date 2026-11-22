extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    root.get_node("Game").save_path = "res://.godot/gula_visual_test_save.json"
    var level: Node2D = load("res://scenes/Gula.tscn").instantiate()
    root.add_child(level)
    await process_frame
    var original: Image = Image.load_from_file(ProjectSettings.globalize_path("res://assets/gula/world/gula_base.png"))
    original.convert(Image.FORMAT_RGBA8)
    var mask: Image = Image.create_empty(original.get_width(), original.get_height(), false, Image.FORMAT_RGBA8)
    mask.fill(Color.TRANSPARENT)
    for x in range(0, original.get_width(), 4):
        for y in range(0, original.get_height(), 4):
            if level.can_walk(Vector2(x + 2, y + 2), 10.0):
                mask.fill_rect(Rect2i(x, y, 4, 4), Color(0.22, 0.95, 0.18, 0.29))
    original.blend_rect(mask, Rect2i(Vector2i.ZERO, original.get_size()), Vector2i.ZERO)
    for marker in level.markers.get_children():
        var center: Vector2i = Vector2i(marker.position)
        original.fill_rect(Rect2i(center.x - 7, center.y - 7, 14, 14), Color("#fff4bc"))
    var destination := "res://assets/gula/world/gula_rutas.png"
    var result: Error = original.save_png(ProjectSettings.globalize_path(destination))
    print("Plano de rutas: ", destination, " (", result, ")")
    level.queue_free()
    await process_frame
    quit(0 if result == OK else 1)
