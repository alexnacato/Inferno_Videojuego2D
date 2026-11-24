extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var game: Node = root.get_node("Game")
    game.save_path = "res://.godot/gula_smoke_test_save.json"
    game.call("new_game")
    var level: Node2D = load("res://scenes/Gula.tscn").instantiate()
    root.add_child(level)
    await process_frame
    _check(level.can_walk(Vector2(724, 1015), 10.0), "La entrada está fuera del suelo")
    _check(level.can_walk(Vector2(724, 257), 62.0), "Cerbero está fuera de la arena")
    _check(not level.can_walk(Vector2(724, 525), 10.0), "Dante puede caminar por el estanque central")
    _check(not level.can_walk(Vector2(100, 100), 10.0), "Dante puede caminar por el abismo")
    _check(level.movement_factor(Vector2(724, 850)) < 0.7, "El lodo no ralentiza")
    _check(level.movement_factor(Vector2(724, 945)) == 1.0, "El suelo seco ralentiza")
    _check(level.hero.global_position.distance_to(Vector2(724, 1015)) < 1.0, "Dante no aparece en la entrada")
    for soul in level.soul_nodes:
        _check(soul.art != null and soul.art.texture != null, "Falta la figura visible de " + soul.name)
        _check(soul.art.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS,
            "La figura de " + soul.name + " no usa filtrado para escala de juego")
        _check(soul.art.scale.y * 1536.0 >= 75.0 and soul.art.scale.y * 1536.0 <= 95.0,
            "La figura de " + soul.name + " no guarda escala con Dante")
        _check(not level.can_walk(soul.global_position, 10.0), "Dante atraviesa a " + soul.name)
        var inward: Vector2 = Vector2.RIGHT if soul.name == "Daria" else Vector2.LEFT
        _check(level.can_walk(soul.global_position + inward * 42.0, 10.0),
            "No hay espacio de interacción junto a " + soul.name)
        var image: Image = Image.load_from_file(ProjectSettings.globalize_path(soul.art.texture.resource_path))
        _check(image != null and not image.is_empty() and image.get_pixel(0, 0).a < 0.05,
            "La figura de " + soul.name + " no tiene transparencia")
    var reached: Dictionary = _flood(level, Vector2(724, 1015), 14, 10.0)
    for marker in level.markers.get_children():
        _check(_reachable_near(reached, marker.global_position, 95.0, 14), "No se puede alcanzar " + str(marker.get("uid")))
    _check(_reachable_near(reached, Vector2(724, 257), 130.0, 14), "No se llega a la arena de Cerbero")
    level.hud._select(0) # Introducción.
    for id in ["OfrendaOeste", "OfrendaEste"]:
        level._sink_offering(level.markers.get_node(id))
        level.hud._select(0)
    _check(level.offerings.size() == 2, "No se guardan ambas ofrendas")
    for id in ["alma_daria", "alma_olmo"]:
        level._talk_soul(id)
        var portrait: AtlasTexture = level.hud.dialogue_portrait.texture as AtlasTexture
        _check(portrait != null and portrait.atlas.resource_path.ends_with("daria.png" if id == "alma_daria" else "olmo.png"),
            "El diálogo no muestra el rostro de " + id)
        level.hud._select(0)
        level.hud._select(0)
    _check(level.decided.size() == 2, "No se guardan ambas decisiones")
    var progress: Dictionary = game.get("progress")
    _check(int(progress["redencion"]) == 2, "Las decisiones no suman Redención")
    _check(is_instance_valid(level.boss) and level.boss_spawned, "Cerbero no aparece tras cumplir los objetivos")
    _check(level.boss.art.sprite_frames != null and level.boss.art.sprite_frames.has_animation("idle") and level.boss.art.sprite_frames.get_frame_count("idle") == 6, "Cerbero no tiene animación")
    level.hero.global_position = Vector2(724, 355)
    level.hero.invulnerable = 0.0
    var health_before: int = level.hero.health
    level.boss.pattern = 0
    level.boss._release_attack()
    _check(level.hero.health == health_before - 2, "La mordida de Cerbero no causa daño")
    level.hero.invulnerable = 0.0
    level.boss.pattern = 1
    level.boss._release_attack()
    _check(level.bullets.get_child_count() == 3, "El aullido de Cerbero no lanza tres proyectiles")
    for shot in level.bullets.get_children():
        shot.queue_free()
    level.hero.invulnerable = 0.0
    level.boss.pattern = 2
    level.boss._release_attack()
    _check(level.hero.health == health_before - 4, "El zarpazo de Cerbero no causa daño")
    for i in range(18):
        level.boss.take_damage(2, Vector2.DOWN)
    progress = game.get("progress")
    _check(level.boss_defeated and bool(progress["gula_boss_defeated"]), "Cerbero no libera la salida")
    level.queue_free()
    await process_frame
    var restored: Node2D = load("res://scenes/Gula.tscn").instantiate()
    root.add_child(restored)
    await process_frame
    _check(restored.offerings.size() == 2 and restored.decided.size() == 2 and restored.boss_defeated,
        "La partida no restaura el progreso de Gula")
    _check(not is_instance_valid(restored.boss), "Cerbero reaparece tras ser vencido")
    restored.queue_free()
    await process_frame
    var transition: Control = load("res://scenes/FinLujuria.tscn").instantiate()
    root.add_child(transition)
    await process_frame
    var continue_found := false
    for node in transition.find_children("*", "Button", true, false):
        var button: Button = node as Button
        if button.text == "CONTINUAR A GULA":
            continue_found = true
        _check(button.get_global_rect().end.y <= 720.0, "Los botones de transición salen de la pantalla")
    _check(continue_found, "Falta el botón para continuar de Lujuria a Gula")
    transition.queue_free()
    await process_frame
    var ending: Control = load("res://scenes/FinGula.tscn").instantiate()
    root.add_child(ending)
    await process_frame
    for node in ending.find_children("*", "Button", true, false):
        var button: Button = node as Button
        _check(button.get_global_rect().end.y <= 720.0, "El botón final de Gula sale de la pantalla")
    ending.queue_free()
    await process_frame
    if failures.is_empty():
        print("Gula: todas las comprobaciones pasaron")
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
