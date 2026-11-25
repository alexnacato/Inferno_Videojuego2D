extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    root.get_node("Game").save_path = "res://.godot/navigation_test_save.json"
    var movement: Script = load("res://scripts/walk_solver.gd")
    var floor_check: Callable = func(p: Vector2) -> bool: return p.y >= 0.0
    _check(movement.step(Vector2.ZERO, Vector2.UP * 7.0, floor_check) == Vector2.ZERO, "Movimiento: pulsar contra un muro produce deriva lateral")
    _check(movement.step(Vector2.ZERO, Vector2(5, -5), floor_check).x > 0.0, "Movimiento: no se desliza junto a un borde")
    _check(movement.step(Vector2(0, 2), Vector2(0, -7), floor_check).y < 2.0, "Movimiento: se pierde el avance antes de tocar el borde")
    var limbo: Node2D = load("res://scenes/Limbo.tscn").instantiate()
    root.add_child(limbo)
    await process_frame
    _check(not limbo.can_walk(Vector2(285, 565), 14.0), "Limbo: el lago izquierdo es transitable")
    _check(not limbo.can_walk(Vector2(1253, 565), 14.0), "Limbo: el lago derecho es transitable")
    _check(not limbo.can_walk(Vector2(770, 505), 14.0), "Limbo: se atraviesa la escultura")
    _check(not limbo.can_walk(Vector2(-2, 700), 14.0), "Limbo: se sale del mapa")
    limbo.player.global_position = Vector2(285, 700)
    limbo.player.input_locked = false
    limbo.player.last_motion = Vector2.UP
    limbo.player.dash_time_left = 0.2
    limbo.player._physics_process(0.5)
    _check(limbo.player.global_position.y > 650.0 and limbo.can_walk(limbo.player.global_position, 10.0), "Limbo: la esquiva atraviesa el lago")
    _check(limbo.lake_jump_target(Vector2(285, 450), Vector2.DOWN) == Vector2(285, 675), "Limbo: no hay aterrizaje válido al otro lado del lago")
    limbo.player.global_position = Vector2(285, 450)
    limbo.player.dash_cooldown_left = 0.0
    limbo.player.dash_time_left = 0.0
    limbo.player.last_motion = Vector2.DOWN
    Input.action_press("dash")
    limbo.player._physics_process(0.016)
    Input.action_release("dash")
    _check(limbo.player.lake_jump_elapsed > 0.0, "Limbo: Espacio no inicia el salto contextual")
    limbo.player._physics_process(0.16)
    limbo._save_at_position()
    var saved: Dictionary = root.get_node("Game").progress
    _check(Vector2(saved["pos_x"], saved["pos_y"]) == Vector2(285, 450), "Limbo: guardar durante el salto debe conservar la orilla de salida")
    for i in range(30):
        limbo.player._physics_process(0.016)
    _check(limbo.player.global_position.distance_to(Vector2(285, 675)) < 1.0, "Limbo: el salto no aterriza sobre el camino")
    var limbo_reached: Dictionary = _flood(limbo, Vector2(769, 834), 12, 10.0, Rect2i(0, 0, 129, 82))
    for point in limbo.POINTS:
        _check(_reachable_near(limbo_reached, point["pos"], float(point["radius"]), 12), "Limbo: no se alcanza " + str(point["id"]))
    limbo.queue_free()
    await process_frame

    var lujuria: Node2D = load("res://scenes/Lujuria.tscn").instantiate()
    root.add_child(lujuria)
    await process_frame
    _check(not lujuria.can_walk(Vector2(100, 200), 14.0), "Lujuria: se camina por el abismo")
    _check(not lujuria.can_walk(Vector2(727, 503), 14.0), "Lujuria: se atraviesa la estatua")
    _check(not lujuria.can_walk(Vector2(1450, 600), 14.0), "Lujuria: se sale del mapa")
    _check(lujuria.can_walk(Vector2(716, 317), 36.0), "Lujuria: Minos aparece fuera del suelo")
    _check(lujuria.can_walk(Vector2(720, 790), 14.0), "Lujuria: primer punto de control fuera del suelo")
    _check(lujuria.can_walk(Vector2(544, 390), 14.0), "Lujuria: último punto de control fuera del suelo")
    lujuria.hud.set_boss_health(38, 38)
    await process_frame
    var boss_panel: Rect2 = lujuria.hud.boss_frame.get_global_rect()
    var chapter_panel: Rect2 = lujuria.hud.title_frame.get_global_rect()
    _check(boss_panel.end.y < 85.0 and boss_panel.size.x <= 320.0, "Lujuria: la barra del jefe ocupa demasiado mapa")
    _check(root.get_visible_rect().encloses(chapter_panel) and chapter_panel.position.x > root.size.x * 0.5 and chapter_panel.size.y <= 32.0 and not boss_panel.intersects(chapter_panel), "Lujuria: el título tapa la barra o el minimapa")
    lujuria.hero.global_position = Vector2(716, 317)
    var boss: CharacterBody2D = lujuria._spawn_enemy("minos", "prueba_tamano", Vector2(716, 317))
    _check(boss.art.scale.x * 176.0 > 205.0 and boss.art.scale.x * 176.0 < 250.0, "Lujuria: tamaño de Minos desproporcionado")
    _check(boss.global_position.distance_to(lujuria.hero.global_position) >= boss.body_radius + 10.0, "Lujuria: Minos aparece encima de Dante")
    boss.queue_free()
    await process_frame
    for wave in lujuria.SPAWNS.values():
        for spec in wave:
            _check(lujuria.can_walk(spec["pos"], 24.0), "Lujuria: enemigo aparece fuera del suelo: " + str(spec["id"]))
    lujuria.hero.global_position = Vector2(180, 500)
    lujuria.hero.control_enabled = true
    lujuria.hero.facing = Vector2.LEFT
    lujuria.hero.dash_time = 0.4
    lujuria.hero._physics_process(0.2)
    _check(lujuria.can_walk(lujuria.hero.global_position, 10.0), "Lujuria: la esquiva sale de la plataforma")
    lujuria.hero.global_position = Vector2(190, 500)
    lujuria.hero.dash_time = 0.0
    lujuria.hero._physics_process(0.1)
    _check(lujuria.hero.global_position.distance_to(Vector2(190, 500)) < 0.1, "Lujuria: el viento arrastra a Dante sin pulsar movimiento")
    _check(lujuria.can_walk(Vector2(190, 600), 10.0) and lujuria.can_walk(Vector2(1258, 600), 10.0), "Lujuria: las plazas laterales no se pueden recorrer")
    _check(not lujuria.can_walk(Vector2(347, 616), 10.0) and not lujuria.can_walk(Vector2(1101, 616), 10.0), "Lujuria: se puede caminar por los huecos de los balcones")
    var lujuria_reached: Dictionary = _flood(lujuria, Vector2(723, 977), 12, 10.0, Rect2i(0, 0, 121, 91))
    for marker in lujuria.markers.get_children():
        _check(_reachable_near(lujuria_reached, marker.global_position, 95.0, 12), "Lujuria: no se alcanza " + str(marker.uid))
        if str(marker.kind) in ["paolo", "francesca", "virgilio"]:
            _check(marker.art.visible and marker.art.texture != null and marker.art.scale.y * 1536.0 > 115.0, "Lujuria: personaje sin figura detallada: " + str(marker.uid))
            _check(marker.art.texture.resource_path.ends_with("_statue.png"), "Lujuria: el personaje no usa el diseño de estatua: " + str(marker.uid))
            _check(not lujuria.can_walk(marker.global_position, 5.0), "Lujuria: enemigos y proyectiles atraviesan a " + str(marker.uid))
            _check(not lujuria.can_occupy_hero(marker.global_position), "Lujuria: Dante atraviesa a " + str(marker.uid))
    for speaker in ["VIRGILIO · GUÍA DE DANTE", "PAOLO · ALMA DE LA LUJURIA", "FRANCESCA · ALMA DE LA LUJURIA"]:
        lujuria.hud.show_dialogue(speaker, "", ["Continuar"])
        _check(lujuria.hud.dialogue_portrait.texture is AtlasTexture, "Lujuria: el diálogo no usa el retrato de " + speaker)
    var path: PackedVector2Array = lujuria.route_to(Vector2(720, 800), Vector2(720, 317), 17.0)
    _check(path.size() > 4, "Lujuria: no hay ruta alrededor de la estatua")
    for p in path:
        _check(lujuria.can_walk(p, 14.0), "Lujuria: una ruta sale del suelo")
    var walk_position: Vector2 = Vector2(720, 800)
    var can_enter: Callable = Callable(lujuria, "can_occupy_hero").bind(false)
    for waypoint in path:
        for i in range(220):
            if walk_position.distance_to(waypoint) < 5.0:
                break
            walk_position = movement.step(walk_position, (waypoint - walk_position).limit_length(4.0), can_enter)
        _check(walk_position.distance_to(waypoint) < 9.0, "Lujuria: Dante se atasca en una conexión entre plataformas")
    _check(walk_position.distance_to(Vector2(720, 317)) < 35.0, "Lujuria: Dante no alcanza la plataforma del jefe")
    lujuria.hero.global_position = Vector2(716, 317)
    lujuria.hero.control_enabled = false
    lujuria.game_active = true
    var foe: CharacterBody2D = lujuria._spawn_enemy("diablillo", "prueba_ruta", Vector2(720, 800))
    _check(lujuria.can_occupy_hero(foe.global_position), "Lujuria: un enemigo crea un muro móvil que atasca a Dante")
    for i in range(120):
        await physics_frame
        _check(lujuria.can_walk(foe.global_position, foe.body_radius), "Lujuria: el enemigo salió de la plataforma")
    _check(foe.global_position.y < 760.0, "Lujuria: el enemigo no persigue alrededor de la estatua")
    lujuria.queue_free()
    await process_frame
    await create_timer(0.1).timeout
    if failures.is_empty():
        print("Navegación: todas las comprobaciones pasaron")
        quit(0)
    else:
        for failure in failures:
            push_error(failure)
        quit(1)

func _check(ok: bool, message: String) -> void:
    if not ok and not message in failures:
        failures.append(message)

func _flood(level: Node2D, origin: Vector2, cell: int, radius: float, bounds: Rect2i) -> Dictionary:
    var start: Vector2i = Vector2i(floori(origin.x / cell), floori(origin.y / cell))
    var visited: Dictionary = {start: true}
    var pending: Array[Vector2i] = [start]
    var head: int = 0
    while head < pending.size():
        var current: Vector2i = pending[head]
        head += 1
        for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
            var next: Vector2i = current + direction
            if visited.has(next) or not bounds.has_point(next):
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

