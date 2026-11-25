extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var game: Node = root.get_node("Game")
    game.call("new_game")
    var level: Node2D = load("res://scenes/Traicion.tscn").instantiate()
    root.add_child(level)
    await process_frame
    _check(level.can_walk(Vector2(724, 1000), 10.0), "La entrada está fuera del suelo")
    _check(level.can_walk(Vector2(724, 355), 58.0), "Lucifer está fuera de la arena")
    _check(not level.can_walk(Vector2(50, 200), 10.0), "Se puede caminar por el abismo")
    _check(level.movement_factor(Vector2(575, 615)) < level.movement_factor(Vector2(724, 850)), "El hielo fino no ralentiza")
    _check(level.hero.global_position.distance_to(Vector2(724, 1000)) < 1.0, "Dante no aparece en la entrada")
    var reached: Dictionary = _flood(level, Vector2(724, 1000), 14, 10.0)
    for marker in level.markers.get_children():
        _check(_reachable_near(reached, marker.global_position, 88.0, 14), "No se puede alcanzar " + str(marker.uid))
    level.hud._select(0)
    var start := Vector2(356, 525)
    var finish := Vector2(223, 625)
    var route: PackedVector2Array = level.route_to(start, finish, 25.0)
    _check(not level.has_clear_path(start, finish, 25.0) and route.size() > 4, "La IA no encuentra un rodeo al monumento")
    for waypoint in route:
        _check(level.has_clear_path(start, waypoint, 25.0), "Un tramo de la IA atraviesa un obstáculo")
        start = waypoint
    _check(level.foes.get_child_count() == 0, "Hay guardianes en la entrada")
    Input.action_press("verse")
    level.hero._physics_process(0.016)
    Input.action_release("verse")
    _check(level.bullets.get_child_count() == 1, "El primer verso no comienza con un solo proyectil")
    Input.action_press("verse")
    level.hero._physics_process(0.45)
    Input.action_release("verse")
    level.hero._physics_process(0.07)
    _check(level.bullets.get_child_count() == 3 and level.hero.verse_chain == 2, "El segundo verso no aumenta la ráfaga")
    level.hero._physics_process(1.2)
    _check(level.hero.verse_chain == 0, "La cadena de versos no se reinicia")
    for shot in level.bullets.get_children():
        shot.queue_free()
    await process_frame
    for entry in level.ENCOUNTERS.values():
        level._spawn_enemies(entry[1])
    var knight: Node = level.foes.get_child(0)
    level.hero.global_position = knight.global_position + Vector2.RIGHT * 64.0
    knight.cooldown = 0.0
    level.hero.invulnerable = 0.0
    for frame in range(45):
        await physics_frame
    _check(level.hero.health <= 4 and knight.state in ["attack", "recover"], "El custodio no prepara y ejecuta el golpe")
    var hound: Node = level.foes.get_child(1)
    hound.attack_direction = Vector2.RIGHT
    hound._release_attack()
    _check(hound.lunge_left > 0.0, "El sabueso no inicia la embestida")
    var wraith: Node = level.foes.get_child(3)
    wraith.attack_direction = Vector2.LEFT
    var shot_count: int = level.bullets.get_child_count()
    wraith._release_attack()
    _check(level.bullets.get_child_count() == shot_count + 1, "El espectro no dispara")
    for shot in level.bullets.get_children():
        shot.queue_free()
    await process_frame
    level._break_seal(level.markers.get_node("SelloOeste"))
    level.hud._select(0)
    level._break_seal(level.markers.get_node("SelloEste"))
    level.hud._select(0)
    for id in ["alma_ugolino", "alma_bocca"]:
        level._talk_soul(id)
        level.hud._select(0)
        level.hud._select(0)
    _check(level.seals.size() == 2 and level.decided.size() == 2, "No se guardan juramentos y decisiones")
    _check(not level.boss_spawned, "Lucifer aparece antes de vencer a los guardianes")
    _check(not level.can_walk(Vector2(250, 545), 10), "Dante atraviesa el monumento del oeste")
    _check(not level.has_clear_path(Vector2(225, 599), Vector2(220, 473)), "Una trayectoria atraviesa el monumento del oeste")
    var rest: Node2D = level.markers.get_node("Brasero")
    level.hero.global_position = rest.global_position + Vector2.DOWN * 38.0
    level.hero.health = 2
    _check(level._nearest_marker() == rest, "No se puede seleccionar el brasero desde el suelo")
    level._use_marker(rest)
    _check(rest.completed and level.hero.health == level.hero.max_health, "El brasero no cura o no guarda el punto")
    var enemies: Array[Node] = level.foes.get_children()
    _check(enemies.size() == level.ENCOUNTERS.size(), "No aparecen todos los guardianes")
    for enemy in enemies:
        _check(level.can_walk(enemy.global_position, enemy.body_radius), "Guardián fuera de suelo: " + enemy.spawn_id)
        _check(enemy.uses_ice_art and enemy.art.sprite_frames.get_frame_count("attack") == 6, "Guardián sin su sprite de Cocito")
        enemy.take_damage(100, Vector2.DOWN)
    _check(is_instance_valid(level.boss) and level.boss_spawned, "Lucifer no aparece al cumplir objetivos")
    if not is_instance_valid(level.boss):
        for failure in failures:
            push_error(failure)
        quit(1)
        return
    _check(level.boss.art.texture != null, "Lucifer no tiene sprite")
    var origin: Vector2 = level.boss.global_position
    level.hero.global_position = Vector2(724, 480)
    for frame in range(24):
        await physics_frame
    _check(level.boss.global_position.distance_to(origin) > 8.0 and level.can_walk(level.boss.global_position, level.boss.body_radius),
        "Lucifer no se desplaza dentro de la arena")
    level.hero.global_position = Vector2(724, 355)
    level.hero.invulnerable = 0.0
    var before: int = level.hero.health
    level.boss.pattern = 2
    level.boss._release_attack()
    _check(level.hero.health == before - 2, "El golpe de Lucifer no causa daño")
    level.boss.pattern = 0
    level.boss._release_attack()
    _check(level.bullets.get_child_count() == 5, "El aliento helado no crea cinco proyectiles")
    for shot in level.bullets.get_children():
        _check(shot.global_position == level.boss.global_position, "Un proyectil nace adelantado y puede saltarse un borde")
    level.boss.take_damage(24, Vector2.DOWN)
    _check(level.boss.phase == 2, "Lucifer no entra a la segunda fase")
    level.boss._release_attack()
    _check(level.bullets.get_child_count() == 12, "El aliento de fase II no amplía el patrón")
    level.hero.invulnerable = 0.0
    level.hero.global_position = Vector2(575, 615)
    level._process(2.3)
    _check(level.hero.health == 0 and level.ice_break_time > 0.0, "El hielo fino no provoca fractura y caída")
    level._toggle_pause()
    _check(not level.paused and not level.game_active and not level.hero.control_enabled, "Pausar durante la caída reactiva el combate")
    await create_timer(1.2).timeout
    _check(level.hud.dialogue_open, "Falta el aviso de derrota")
    level.hud._select(0)
    _check(level.game_active and level.hero.health == level.hero.max_health and level.hero.global_position == level.checkpoint,
        "Dante no reaparece con salud completa en el punto de control")
    _check(level.bullets.get_child_count() == 0, "Quedan proyectiles del combate tras reaparecer")
    _check(level.boss.phase == 1 and level.boss.hp == level.boss.max_hp, "Lucifer no reinicia el duelo tras la caída")
    for i in range(24):
        level.boss.take_damage(2, Vector2.DOWN)
    _check(level.boss_defeated and bool(game.get("progress")["traicion_boss_defeated"]), "La salida no se libera")
    level.queue_free()
    await process_frame
    var restored: Node2D = load("res://scenes/Traicion.tscn").instantiate()
    root.add_child(restored)
    await process_frame
    _check(restored.seals.size() == 2 and restored.decided.size() == 2 and restored.boss_defeated,
        "La partida no restaura Traición")
    _check(not is_instance_valid(restored.boss), "Lucifer reaparece tras ser vencido")
    _check(restored.has_node("RestosDelJefe"), "El cuerpo de Lucifer no permanece al continuar")
    _check(restored.foes.get_child_count() == 0 and restored.defeated_enemies.size() == 5, "Los guardianes reaparecen tras cargar")
    _check(restored.markers.get_node("Brasero").completed, "El brasero no persiste")
    restored.queue_free()
    await process_frame
    var ending: Control = load("res://scenes/FinTraicion.tscn").instantiate()
    root.add_child(ending)
    await process_frame
    for node in ending.find_children("*", "Button", true, false):
        _check((node as Button).get_global_rect().end.y <= 720.0, "El botón final sale de la pantalla")
    ending.queue_free()
    await process_frame
    if failures.is_empty():
        print("Traición: todas las comprobaciones pasaron")
        quit(0)
    else:
        for failure in failures:
            push_error(failure)
        quit(1)

func _check(ok: bool, message: String) -> void:
    if not ok and not message in failures:
        failures.append(message)

func _flood(level: Node2D, origin: Vector2, cell: int, radius: float) -> Dictionary:
    var start := Vector2i(floori(origin.x / cell), floori(origin.y / cell))
    var visited: Dictionary = {start: true}
    var pending: Array[Vector2i] = [start]
    var head := 0
    while head < pending.size():
        var current: Vector2i = pending[head]
        head += 1
        for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
            var next: Vector2i = current + direction
            if visited.has(next) or next.x < 0 or next.y < 0 or next.x > 103 or next.y > 77:
                continue
            var center: Vector2 = Vector2(next.x + 0.5, next.y + 0.5) * float(cell)
            if level.can_walk(center, radius):
                visited[next] = true
                pending.append(next)
    return visited

func _reachable_near(visited: Dictionary, target: Vector2, radius: float, cell: int) -> bool:
    for id in visited:
        var center: Vector2 = Vector2(id.x + 0.5, id.y + 0.5) * float(cell)
        if center.distance_to(target) <= radius:
            return true
    return false
