extends SceneTree

const OUTPUT := "res://assets/lujuria/world/lujuria_colocacion_enemigos.png"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game: Node = root.get_node("Game")
	game.save_path = "res://.godot/lujuria_preview_test_save.json"
	game.call("new_game")
	game.progress["lujuria_intro_seen"] = true
	var level: Node2D = load("res://scenes/Lujuria.tscn").instantiate()
	root.add_child(level)
	await process_frame
	for wave_name in level.SPAWNS.keys():
		level._spawn_wave(wave_name)
	level._spawn_enemy("minos", "preview_minos", Vector2(716, 317))
	var canvas: Image = Image.load_from_file(ProjectSettings.globalize_path("res://assets/lujuria/world/lujuria_base.png"))
	if canvas == null or canvas.is_empty():
		push_error("No se pudo cargar el mapa de Lujuria")
		quit(1)
		return
	canvas.convert(Image.FORMAT_RGBA8)
	for enemy in level.foes.get_children():
		var sprite: AnimatedSprite2D = enemy.art
		var source: Image = Image.load_from_file(ProjectSettings.globalize_path("res://assets/lujuria/enemies/%s/idle.png" % enemy.archetype))
		source.convert(Image.FORMAT_RGBA8)
		var frame_size := Vector2i(176, 176) if enemy.archetype == "minos" else Vector2i(128, 144)
		source = source.get_region(Rect2i(Vector2i.ZERO, frame_size))
		source.resize(roundi(frame_size.x * sprite.scale.x), roundi(frame_size.y * sprite.scale.y), Image.INTERPOLATE_LANCZOS)
		var center: Vector2 = enemy.global_position + sprite.position
		var top_left := Vector2i(roundi(center.x - source.get_width() * 0.5), roundi(center.y - source.get_height() * 0.5))
		canvas.blend_rect(source, Rect2i(Vector2i.ZERO, source.get_size()), top_left)
		var foot := Vector2i(enemy.global_position)
		canvas.fill_rect(Rect2i(foot - Vector2i(4, 4), Vector2i(8, 8)), enemy.COLORS[enemy.archetype])
	var hero_sprite: AnimatedSprite2D = level.hero.art
	var hero_image: Image = Image.load_from_file(ProjectSettings.globalize_path("res://assets/dante/idle.png"))
	hero_image.convert(Image.FORMAT_RGBA8)
	hero_image = hero_image.get_region(Rect2i(0, 0, 80, 96))
	hero_image.resize(roundi(80.0 * hero_sprite.scale.x), roundi(96.0 * hero_sprite.scale.y), Image.INTERPOLATE_LANCZOS)
	var hero_center: Vector2 = level.hero.global_position + hero_sprite.position
	var hero_corner := Vector2i(roundi(hero_center.x - hero_image.get_width() * 0.5), roundi(hero_center.y - hero_image.get_height() * 0.5))
	canvas.blend_rect(hero_image, Rect2i(Vector2i.ZERO, hero_image.get_size()), hero_corner)
	var result: Error = canvas.save_png(ProjectSettings.globalize_path(OUTPUT))
	level.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	print("Vista de Lujuria: ", OUTPUT, " (", result, ")")
	quit(0 if result == OK else 1)
