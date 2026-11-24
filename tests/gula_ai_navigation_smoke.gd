extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var game: Node = root.get_node("Game")
    game.save_path = "res://.godot/gula_ai_test_save.json"
    game.call("new_game")
    var level: Node2D = load("res://scenes/Gula.tscn").instantiate()
    root.add_child(level)
    await process_frame
    level.hud._select(0)
    level._spawn_wave("entrada")
    level._spawn_wave("oeste")
    level._spawn_wave("este")
    var trace: Image = Image.load_from_file(ProjectSettings.globalize_path("res://assets/gula/world/gula_base.png"))
    trace.convert(Image.FORMAT_RGBA8)

    for point in [Vector2(95, 500), Vector2(380, 680), Vector2(1068, 680), Vector2(400, 700), Vector2(1048, 700)]:
        _check(not level.can_walk(point, 10.0), "La zona transitable invade el vacío en " + str(point))

    var destinations := {
        "sur": Vector2(724, 900),
        "oeste": Vector2(330, 570),
        "este": Vector2(1118, 570),
    }
    for enemy in level.foes.get_children():
        for other in level.foes.get_children():
            other.active = other == enemy
        var region: String = enemy.spawn_id.get_slice("_", 0)
        var target: Vector2 = destinations[region]
        _check(level.can_walk(target, 10.0), "Destino de prueba fuera del suelo: " + region)
        level.hero.global_position = target
        level.hero.invulnerable = 99.0
        enemy.cooldown = 5.0
        var start: Vector2 = enemy.global_position
        for frame in range(180):
            enemy._physics_process(1.0 / 60.0)
            if frame % 6 == 0:
                var tint := Color("ff9d68") if enemy.archetype == "penitente" else Color("6fd5ff") if enemy.archetype == "rastrero" else Color("c795ff")
                trace.fill_rect(Rect2i(Vector2i(enemy.global_position) - Vector2i(2, 2), Vector2i(4, 4)), tint)
            if not level.can_walk(enemy.global_position, enemy.body_radius):
                _check(false, "%s salió del suelo en fotograma %d" % [enemy.spawn_id, frame])
                break
        _check(enemy.global_position.distance_to(start) > 5.0,
            enemy.spawn_id + " no se desplaza hacia Dante ni maniobra")

    var ramp_targets := {"oeste_rastrero": Vector2(470, 410), "este_penitente": Vector2(978, 410)}
    for enemy in level.foes.get_children():
        if not ramp_targets.has(enemy.spawn_id):
            continue
        for other in level.foes.get_children():
            other.active = other == enemy
        var target: Vector2 = ramp_targets[enemy.spawn_id]
        _check(level.can_walk(target, 10.0), "Destino de rampa fuera del suelo: " + str(target))
        level.hero.global_position = target
        level.hero.invulnerable = 99.0
        enemy.last_seen = target
        enemy.alert_left = 8.0
        enemy.cooldown = 8.0
        var start_distance: float = enemy.global_position.distance_to(target)
        for frame in range(300):
            enemy._physics_process(1.0 / 60.0)
            if frame % 6 == 0:
                trace.fill_rect(Rect2i(Vector2i(enemy.global_position) - Vector2i(2, 2), Vector2i(4, 4)), Color("f7f0b2"))
            if not level.can_walk(enemy.global_position, enemy.body_radius):
                _check(false, enemy.spawn_id + " salió de la rampa")
                break
        _check(enemy.global_position.distance_to(target) < start_distance - 35.0,
            "%s no sigue la curva de la rampa: %s → %s; ruta %s" % [enemy.spawn_id, str(enemy.global_position), str(target), str(level.route_to(enemy.global_position, target, enemy.body_radius))])

    for enemy in level.foes.get_children():
        enemy.active = false
    level._spawn_boss()
    level.hero.global_position = Vector2(900, 280)
    level.hero.invulnerable = 99.0
    var boss_start: Vector2 = level.boss.global_position
    for frame in range(240):
        level.boss._physics_process(1.0 / 60.0)
        if frame % 6 == 0:
            trace.fill_rect(Rect2i(Vector2i(level.boss.global_position) - Vector2i(3, 3), Vector2i(6, 6)), Color("f2e65e"))
        if not level.can_walk(level.boss.global_position, level.boss.body_radius) or level.boss.global_position.y >= 315.0:
            _check(false, "Cerbero salió de la arena en fotograma %d" % frame)
            break
    _check(level.boss.global_position.distance_to(boss_start) > 5.0, "Cerbero no patrulla su arena")
    var result: Error = trace.save_png(ProjectSettings.globalize_path("res://assets/gula/world/gula_recorridos_ia.png"))
    _check(result == OK, "No se pudo guardar la revisión visual de recorridos")
    level.queue_free()
    await process_frame

    if failures.is_empty():
        print("Gula IA y rutas: todas las comprobaciones pasaron")
        quit(0)
    else:
        for failure in failures:
            push_error(failure)
        quit(1)

func _check(ok: bool, message: String) -> void:
    if not ok and not message in failures:
        failures.append(message)
