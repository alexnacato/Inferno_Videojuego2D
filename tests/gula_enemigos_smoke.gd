extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var game: Node = root.get_node("Game")
    game.save_path = "res://.godot/gula_enemigos_test_save.json"
    game.call("new_game")
    var level: Node2D = load("res://scenes/Gula.tscn").instantiate()
    root.add_child(level)
    await process_frame
    level.hud._select(0)
    _check(level.foes.get_child_count() == 0, "Los enemigos aparecen antes de entrar en su zona")
    level.hero.global_position = Vector2(724, 900)
    level._trigger_encounters()
    _check(level.foes.get_child_count() == 2, "No se activa la oleada de entrada")
    level.hero.global_position = Vector2(400, 550)
    level._trigger_encounters()
    _check(level.foes.get_child_count() == 4, "No se activa la oleada oeste")
    level.hero.global_position = Vector2(1040, 550)
    level._trigger_encounters()
    _check(level.foes.get_child_count() == 6, "Deben aparecer seis enemigos normales")
    var dante_image: Image = Image.load_from_file(ProjectSettings.globalize_path("res://assets/dante/idle.png"))
    var dante_height: float = float(dante_image.get_region(Rect2i(0, 0, 80, 96)).get_used_rect().size.y) * level.hero.art.scale.y
    var types := {}
    for enemy in level.foes.get_children():
        types[enemy.archetype] = true
        _check(enemy.art.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS,
            "El sprite de %s no usa filtrado para escala de juego" % enemy.archetype)
        var sprite_image: Image = Image.load_from_file(ProjectSettings.globalize_path("res://assets/gula/enemies/%s/idle.png" % enemy.archetype))
        var visible: Rect2i = sprite_image.get_region(Rect2i(0, 0, 192, 192)).get_used_rect()
        var visible_height: float = float(visible.size.y) * enemy.art.scale.y
        var foot_y: float = enemy.art.position.y + (float(visible.end.y) - 96.0) * enemy.art.scale.y
        _check(visible_height >= dante_height * 0.85 and visible_height <= dante_height * 1.3,
            "La silueta de %s no guarda escala con Dante" % enemy.archetype)
        _check(absf(foot_y) < 20.0, "Los pies de %s no coinciden con el suelo" % enemy.archetype)
        _check(level.can_walk(enemy.global_position, enemy.body_radius), "Aparece fuera del suelo: " + enemy.spawn_id)
        for action in ["idle", "walk", "attack", "hurt", "death"]:
            _check(enemy.art.sprite_frames != null and enemy.art.sprite_frames.has_animation(action) and enemy.art.sprite_frames.get_frame_count(action) == 6 and enemy.art.sprite_frames.get_frame_texture(action, 0) != null, "Falta animación: " + enemy.spawn_id + "/" + action)
        _check(not level.route_to(enemy.global_position, enemy.global_position + Vector2(20, 0), enemy.body_radius).is_empty(), "No hay ruta para: " + enemy.spawn_id)
    _check(types.size() == 3, "Falta un arquetipo de Gula")
    for enemy in level.foes.get_children():
        enemy.active = false
    var penitent: Variant = level.foes.get_child(0)
    penitent.active = true
    level.hero.global_position = penitent.global_position + Vector2(0, 170)
    var before_move: Vector2 = penitent.global_position
    penitent.cooldown = 5.0
    penitent._physics_process(0.1)
    _check(penitent.global_position.distance_to(before_move) > 1.0, "El penitente no persigue")
    _check(level.can_walk(penitent.global_position, penitent.body_radius), "El penitente sale de la ruta")
    level.hero.global_position = penitent.global_position + Vector2(0, 75)
    level.hero.invulnerable = 0.0
    var health_before: int = level.hero.health
    penitent.cooldown = 0.0
    penitent._physics_process(0.02)
    _check(penitent.windup > 0.0, "El penitente no prepara su golpe")
    _check(penitent.art.animation != "attack", "El penitente muestra un aviso de ataque")
    penitent._physics_process(0.75)
    _check(penitent.art.animation == "attack", "El penitente no anima el golpe al ejecutarlo")
    _check(level.hero.health == health_before - 2, "El penitente no golpea")
    var penitent_hp: int = penitent.hp
    level.melee_hit(level.hero.global_position, Vector2.UP)
    _check(penitent.hp == penitent_hp - 2, "El golpe de Dante no alcanza al penitente")
    penitent.active = false
    var crawler: Variant = level.foes.get_child(1)
    crawler.active = true
    level.hero.global_position = crawler.global_position + Vector2(0, 76)
    level.hero.invulnerable = 0.0
    crawler.cooldown = 0.0
    crawler._physics_process(0.02)
    crawler._physics_process(0.5)
    _check(crawler.lunge_left > 0.0, "El rastrero no inicia el salto")
    var health_before_lunge: int = level.hero.health
    for i in range(7):
        crawler._physics_process(0.05)
    _check(level.hero.health == health_before_lunge - 1, "El salto del rastrero no causa daño")
    crawler.active = false
    var pourer: Variant = level.foes.get_child(3)
    pourer.active = true
    level.hero.global_position = pourer.global_position + Vector2(0, 155)
    pourer.cooldown = 0.0
    pourer._physics_process(0.02)
    pourer._physics_process(0.8)
    _check(level.bullets.get_child_count() == 1, "El escanciador no dispara")
    pourer.active = false
    level._spawn_boss()
    var boss_image: Image = Image.load_from_file(ProjectSettings.globalize_path("res://assets/gula/enemies/cerbero/idle.png"))
    var boss_visible: Rect2i = boss_image.get_region(Rect2i(0, 0, 384, 384)).get_used_rect()
    var boss_height: float = float(boss_visible.size.y) * level.boss.art.scale.y
    var boss_foot_y: float = level.boss.art.position.y + (float(boss_visible.end.y) - 192.0) * level.boss.art.scale.y
    _check(boss_height >= dante_height * 1.5 and boss_height <= dante_height * 2.0,
        "Cerbero no guarda escala con Dante y la arena: %.1f / %.1f" % [boss_height, dante_height])
    _check(absf(boss_foot_y) < 20.0, "Los pies de Cerbero no coinciden con el suelo")
    _check(level.boss.art.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS,
        "Cerbero no usa filtrado para escala de juego")
    _check(level.can_walk(level.boss.global_position, level.boss.body_radius), "Cerbero aparece fuera de la arena")
    for action in ["idle", "walk", "bite", "howl", "claw", "hurt", "death"]:
        _check(level.boss.art.sprite_frames.has_animation(action) and level.boss.art.sprite_frames.get_frame_count(action) == 6, "Falta animación de Cerbero: " + action)
    for action in ["idle", "walk"]:
        var image: Image = Image.load_from_file(ProjectSettings.globalize_path("res://assets/gula/enemies/cerbero/" + action + ".png"))
        _check(image.get_pixel(50, 100).a < 0.05, "Cerbero tiene fondo opaco en " + action)
    level.boss.take_damage(18, Vector2.DOWN)
    _check(level.boss.phase == 2, "Cerbero no entra en segunda fase")
    level.hero.global_position = level.boss.global_position + Vector2(0, 95)
    level.boss.hurt_left = 0.0
    level.boss.pattern = 1
    level.boss.cooldown = 0.0
    level.boss._physics_process(0.02)
    _check(level.boss.art.animation != "howl", "Cerbero muestra un aviso de aullido")
    level.boss._release_attack()
    _check(level.boss.art.animation == "howl", "Cerbero no anima el aullido al ejecutarlo")
    _check(level.bullets.get_child_count() == 6, "La segunda fase no dispara cinco proyectiles")
    var target: Variant = level.foes.get_child(0)
    var uid: String = target.spawn_id
    target.active = true
    target.take_damage(50, Vector2.DOWN)
    _check(level.defeated_enemies.has(uid), "La muerte no se guarda")
    level.queue_free()
    await process_frame
    var restored: Node2D = load("res://scenes/Gula.tscn").instantiate()
    root.add_child(restored)
    await process_frame
    _check(restored.foes.get_child_count() == 5, "Un enemigo vencido reaparece")
    restored.offerings.append("ofrenda_oeste")
    restored.offerings.append("ofrenda_este")
    restored.decided = {"alma_daria": 0, "alma_olmo": 0}
    restored._check_boss_spawn()
    _check(not restored.boss_spawned, "Cerbero aparece mientras quedan enemigos normales")
    for enemy in restored.foes.get_children():
        enemy.take_damage(100, Vector2.DOWN)
    _check(restored.boss_spawned and is_instance_valid(restored.boss), "Cerbero no aparece al despejar las oleadas")
    restored.queue_free()
    await process_frame
    if failures.is_empty():
        print("Gula enemigos: todas las comprobaciones pasaron")
        quit(0)
    else:
        for failure in failures:
            push_error(failure)
        quit(1)

func _check(ok: bool, message: String) -> void:
    if not ok and not message in failures:
        failures.append(message)
