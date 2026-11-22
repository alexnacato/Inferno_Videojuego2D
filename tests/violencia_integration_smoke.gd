extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var game: Node = root.get_node("Game")
    game.save_path = "res://.godot/violencia_integration_test_save.json"
    game.call("new_game")
    game.progress["gula_completed"] = true
    game.progress["circle"] = "gula"
    _check(game.next_scene() == "res://scenes/FinGula.tscn", "La partida no llega al cierre de Gula")
    var ending: Control = load("res://scenes/FinGula.tscn").instantiate()
    root.add_child(ending)
    await process_frame
    _check(_has_button(ending, "CONTINUAR A VIOLENCIA · CÍRCULO VII"), "Falta la transición de Gula a Violencia")
    for button in ending.find_children("*", "Button", true, false):
        _check(button.get_global_rect().end.y <= 720.0, "Un botón de Gula sale de la pantalla")
    ending.queue_free()
    await process_frame
    var level: Node2D = load("res://scenes/Violencia.tscn").instantiate()
    root.add_child(level)
    await process_frame
    _check(game.next_scene() == "res://scenes/Violencia.tscn", "Continuar partida no abre Violencia")
    _check(level.hud.current_circle == "violencia" and level.hud.minimap.mode == "violencia", "HUD o minimapa incorrecto")
    _check(level.can_walk(level.hero.global_position, 14.0), "Dante aparece fuera del suelo")
    _check(not level.can_walk(Vector2(500, 1130), 14.0), "El río es transitable fuera del puente")
    _check(not level.can_walk(Vector2(865, 282), 14.0), "La columna superior es transitable")
    _check(not level.can_occupy_hero(level.markers["virgilio"].position), "Dante atraviesa a Virgilio")
    _check(level.hud.dialogue_open and not level.hero.control_enabled, "La introducción no pausa a Dante")
    level.hud._select(0)
    _check(level.game_active and level.hero.control_enabled, "El diálogo no habilita el movimiento")
    level._activate_seal("tregua")
    _check(level.data["seals"].is_empty(), "Se puede activar un voto fuera de orden")
    for seal in ["contencion", "memoria", "tregua"]:
        level._activate_seal(seal)
        for guardian in level.foes.get_children():
            if guardian.uid == "guardian_" + seal and not guardian.dead:
                guardian.take_damage(100)
        level._activate_seal(seal)
        if level.hud.dialogue_open:
            level.hud._select(0)
    _check(level.data["seals"].size() == 3, "No se activan los tres votos")
    level._use_marker("guardia")
    level.hud._select(0)
    level._use_marker("testigo")
    level.hud._select(1)
    _check(level.data["decisions"].size() == 2, "Faltan las decisiones de las almas")
    _check(game.progress["redencion"] == 1 and game.progress["rigor"] == 1, "No se suman las decisiones morales")
    _check(level._ritual_complete(), "El ritual no se completa")
    level.hero.position = Vector2(1152, 450)
    level._begin_boss()
    if level.hud.dialogue_open:
        level.hud._select(0)
    await process_frame
    var boss: Node2D = level.boss_actor
    _check(is_instance_valid(boss) and boss.hp == 48, "No aparece el Minotauro")
    _check(level.boss_fighting and not level.can_walk(Vector2(1152, 610), 14.0), "La arena no se cierra")
    _check(boss.art.sprite_frames.has_animation("walk_left") and boss.art.sprite_frames.has_animation("walk_right"), "Faltan animaciones del Minotauro")
    boss.take_damage(100)
    _check(level.data["boss_down"] and game.progress["dash_extended"], "La victoria no otorga la mejora de esquiva")
    _check(level.hero.dash_duration > 0.18 and level.hero.dash_cooldown_duration < 0.85, "La mejora no se aplica a Dante")
    level._save()
    game.load_progress()
    _check(game.next_scene() == "res://scenes/Violencia.tscn", "Continuar antes de salir del nivel es incorrecto")
    level.data["completed"] = true
    level._save()
    game.load_progress()
    _check(game.next_scene() == "res://scenes/FinViolencia.tscn", "El final de Violencia no se restaura")
    level.queue_free()
    await process_frame
    await create_timer(0.1).timeout
    var finale: Control = load("res://scenes/FinViolencia.tscn").instantiate()
    root.add_child(finale)
    await process_frame
    _check(_has_button(finale, "CONTINUAR A TRAICIÓN · CÍRCULO IX"), "Falta la transición de Violencia a Traición")
    for button in finale.find_children("*", "Button", true, false):
        _check(button.get_global_rect().end.y <= 720.0, "Un botón de Violencia sale de la pantalla")
    finale.queue_free()
    await process_frame
    if failures.is_empty():
        print("Violencia integrada: todas las comprobaciones pasaron")
        quit(0)
    else:
        for failure in failures:
            push_error(failure)
        quit(1)

func _has_button(screen: Node, caption: String) -> bool:
    for child in screen.find_children("*", "Button", true, false):
        if child.text == caption:
            return true
    return false

func _check(ok: bool, message: String) -> void:
    if not ok and message not in failures:
        failures.append(message)
