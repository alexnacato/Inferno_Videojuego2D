extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    for chapter in ["Limbo", "Lujuria"]:
        var level: Node2D = load("res://scenes/%s.tscn" % chapter).instantiate()
        root.add_child(level)
        await process_frame
        var map_path: String = "res://assets/world/limbo_master.png" if chapter == "Limbo" else "res://assets/lujuria/world/lujuria_base.png"
        var original: Image = Image.load_from_file(ProjectSettings.globalize_path(map_path))
        original.convert(Image.FORMAT_RGBA8)
        var mask: Image = Image.create_empty(original.get_width(), original.get_height(), false, Image.FORMAT_RGBA8)
        mask.fill(Color.TRANSPARENT)
        for x in range(0, original.get_width(), 4):
            for y in range(0, original.get_height(), 4):
                if level.can_walk(Vector2(x + 2, y + 2), 10.0):
                    mask.fill_rect(Rect2i(x, y, 4, 4), Color(0.12, 0.95, 0.20, 0.39))
        var preview: Image = original.duplicate()
        preview.blend_rect(mask, Rect2i(Vector2i.ZERO, original.get_size()), Vector2i.ZERO)
        var output: String = OS.get_environment("TEMP") + "/inferno_%s_walk_2.png" % chapter.to_lower()
        print(output, " -> ", preview.save_png(output))
        if chapter == "Lujuria":
            for marker in level.markers.get_children():
                if not str(marker.kind) in ["paolo", "francesca", "virgilio"]:
                    continue
                var source: Image = Image.load_from_file(ProjectSettings.globalize_path("res://assets/lujuria/npcs/%s_statue.png" % marker.kind))
                source.convert(Image.FORMAT_RGBA8)
                var size: Vector2i = Vector2i(roundi(source.get_width() * marker.art.scale.x), roundi(source.get_height() * marker.art.scale.y))
                source.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
                var pos: Vector2i = Vector2i(roundi(marker.position.x - size.x / 2.0), roundi(marker.position.y - size.y))
                original.blend_rect(source, Rect2i(Vector2i.ZERO, source.get_size()), pos)
            var npc_path: String = OS.get_environment("TEMP") + "/inferno_npcs_preview.png"
            print(npc_path, " -> ", original.save_png(npc_path))
        level.queue_free()
        await process_frame
    quit()
