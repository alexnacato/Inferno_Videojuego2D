extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game: Node = root.get_node("Game")
	game.save_path = "res://.godot/lujuria_enemy_test_save.json"
	game.call("new_game")
	game.progress["lujuria_intro_seen"] = true
	var level: Node2D = load("res://scenes/Lujuria.tscn").instantiate()
	root.add_child(level)
	await process_frame
	level.hero.invulnerable = 999.0
	level.hero.control_enabled = false
	for wave_name in level.SPAWNS.keys():
		level._spawn_wave(wave_name)
	var boss: CharacterBody2D = level._spawn_enemy("minos", "test_minos", Vector2(716, 317))
	var initial: Dictionary = {}
	var kinds: Dictionary = {}
	for enemy in level.foes.get_children():
		initial[enemy.spawn_id] = enemy.global_position
		kinds[enemy.archetype] = true
		_check(level.can_walk(enemy.global_position, enemy.body_radius), "Aparición fuera del suelo: " + enemy.spawn_id)
		_check(enemy.art.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS, "Filtrado incorrecto: " + enemy.spawn_id)
		_check(enemy.art.material is ShaderMaterial, "Falta contorno de lectura: " + enemy.spawn_id)
		for action in ["idle", "walk", "attack", "hurt", "death"]:
			_check(enemy.art.sprite_frames.has_animation(action) and enemy.art.sprite_frames.get_frame_count(action) >= 3,
				"Animación incompleta: " + enemy.spawn_id + "/" + action)
	_check(kinds.size() == 5, "Falta un arquetipo de Lujuria")
	for target in [Vector2(724, 790), Vector2(420, 510), Vector2(1030, 510), Vector2(716, 340)]:
		level.hero.global_position = target
		for i in range(105):
			await physics_frame
			for enemy in level.foes.get_children():
				if enemy.dead:
					continue
				_check(level.can_walk(enemy.global_position, enemy.body_radius), "Salió del mapa: " + enemy.spawn_id)
				if enemy.archetype == "minos":
					_check(Geometry2D.is_point_in_polygon(enemy.global_position, level.upper_court), "Minos abandonó su plataforma")
	var moved: Dictionary = {}
	for enemy in level.foes.get_children():
		if enemy.global_position.distance_to(initial[enemy.spawn_id]) > 5.0:
			moved[enemy.archetype] = true
	_check(moved.size() >= 3, "Los enemigos no patrullan ni persiguen")
	var projectile_count: int = level.bullets.get_child_count()
	for enemy in level.foes.get_children():
		if enemy.archetype == "espectro":
			enemy.attack_target = Vector2.RIGHT
			enemy._release_attack()
			break
	_check(level.bullets.get_child_count() > projectile_count, "El espectro no dispara")
	for bullet in level.bullets.get_children():
		bullet.queue_free()
	await process_frame
	boss.take_damage(20, Vector2.DOWN)
	boss.windup = 0.0
	boss.recovery = 1.0
	boss._physics_process(0.016)
	_check(boss.phase == 2, "Minos no cambia a la segunda fase")
	level.game_active = false
	for bullet in level.bullets.get_children():
		bullet.queue_free()
	await process_frame
	boss.attack_target = Vector2.DOWN
	boss._release_attack()
	_check(level.bullets.get_child_count() == 7, "Minos no lanza siete proyectiles en la segunda fase")
	level.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("Lujuria enemigos: todas las comprobaciones pasaron")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check(ok: bool, message: String) -> void:
	if not ok and message not in failures:
		failures.append(message)
