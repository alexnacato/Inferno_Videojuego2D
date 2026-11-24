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
    _check(level.movement_factor(Vector2(565, 683)) < level.movement_factor(Vector2(724, 850)), "El hielo fino no ralentiza")
    _check(level.hero.global_position.distance_to(Vector2(724, 1000)) < 1.0, "Dante no aparece en la entrada")
    var reached: Dictionary = _flood(level, Vector2(724, 1000), 14, 10.0)
    for marker in level.markers.get_children():
        _check(_reachable_near(reached, marker.global_position, 88.0, 14), "No se puede alcanzar " + str(marker.uid))
    level.hud._select(0)
    level._break_seal(level.markers.get_node("SelloOeste"))
    level.hud._select(0)
    level._break_seal(level.markers.get_node("SelloEste"))
    level.hud._select(0)
    for id in ["alma_ugolino", "alma_bocca"]:
        level._talk_soul(id)
        level.hud._select(0)
        level.hud._select(0)
    _check(level.seals.size() == 2 and level.decided.size() == 2, "No se guardan juramentos y decisiones")
    _check(is_instance_valid(level.boss) and level.boss_spawned, "Lucifer no aparece al cumplir objetivos")
    _check(level.boss.art.texture != null, "Lucifer no tiene sprite")
    level.hero.global_position = Vector2(724, 355)
    level.hero.invulnerable = 0.0
    var before: int = level.hero.health
    level.boss.pattern = 2
    level.boss._release_attack()
    _check(level.hero.health == before - 2, "El golpe de Lucifer no causa daño")
    level.boss.pattern = 0
    level.boss._release_attack()
    _check(level.bullets.get_child_count() == 5, "El aliento helado no crea cinco proyectiles")
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
