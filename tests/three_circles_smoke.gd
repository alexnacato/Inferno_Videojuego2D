extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var game: Node = root.get_node("Game")
    game.save_path = "res://.godot/three_circles_test_save.json"
    change_scene_to_file("res://scenes/MenuPrincipal.tscn")
    await process_frame
    await process_frame
    _check_scene("MenuPrincipal")
    var replacing_save: bool = game.has_save()
    _press_button(current_scene, "Nueva partida")
    if replacing_save:
        _press_button(current_scene, "Iniciar nueva campaña")
    await process_frame
    await process_frame
    _check_scene("Limbo")
    if current_scene == null or current_scene.name != "Limbo":
        _finish()
        return

    var limbo: Node = current_scene
    limbo.hud._select(0)
    limbo._handle_door()
    _check(not game.gate_unlocked() and limbo.dialog_context == "blocked", "La puerta del Limbo se abre antes de completar sus objetivos")
    limbo.hud._select(0)
    for shrine in ["altar_memoria", "altar_saber", "altar_compasion"]:
        limbo._activate_shrine(shrine)
        limbo.hud._select(0)
    for soul in ["alma_elio", "alma_livia"]:
        limbo._talk_to_soul(soul)
        limbo.hud._select(0)
        limbo.hud._select(0)
    _check(game.gate_unlocked(), "El umbral del Limbo no se desbloquea")
    limbo._handle_door()
    limbo.hud._select(0)
    await create_timer(0.9).timeout
    _check_scene("Transicion")
    _check(bool(game.progress["limbo_completed"]), "No se conserva el progreso del Limbo")
    _press_button(current_scene, "CONTINUAR A LUJURIA")
    await create_timer(0.9).timeout
    _check_scene("Lujuria")
    if current_scene == null or current_scene.name != "Lujuria":
        _finish()
        return

    var lujuria: Node = current_scene
    lujuria.hud._select(0)
    var puerta_lujuria: Node = lujuria.markers.get_node("puerta")
    lujuria._use_marker(puerta_lujuria)
    _check(current_scene == lujuria and not lujuria.boss_defeated, "La puerta de Lujuria se abre antes de vencer a Minos")
    for seal in ["sello_inicio", "sello_izquierdo", "sello_derecho"]:
        lujuria._activate_seal(lujuria.markers.get_node(seal))
        if lujuria.hud.dialogue_open:
            lujuria.hud._select(0)
    for soul in ["paolo", "francesca"]:
        lujuria._soul_dialogue(soul)
        lujuria.hud._select(0)
        lujuria.hud._select(0)
    lujuria._back_to_menu()
    await process_frame
    await process_frame
    _press_button(current_scene, "Continuar partida anterior")
    await process_frame
    await process_frame
    _check_scene("Lujuria")
    if current_scene == null or current_scene.name != "Lujuria":
        _finish()
        return
    lujuria = current_scene
    puerta_lujuria = lujuria.markers.get_node("puerta")
    _check(lujuria.seals.size() == 3 and lujuria.decided.size() == 2, "Continuar partida pierde los objetivos de Lujuria")
    lujuria._spawn_wave("patio")
    for enemy in lujuria.foes.get_children():
        enemy.take_damage(100, Vector2.DOWN)
    lujuria._check_boss_spawn()
    _check(lujuria.boss_spawned and is_instance_valid(lujuria.enemy_boss), "Minos no aparece tras los objetivos de Lujuria")
    if is_instance_valid(lujuria.enemy_boss):
        lujuria.enemy_boss.take_damage(100, Vector2.DOWN)
    _check(lujuria.boss_defeated, "La derrota de Minos no libera la salida")
    lujuria._use_marker(puerta_lujuria)
    await create_timer(0.9).timeout
    _check_scene("FinLujuria")
    _check(game.next_scene() == "res://scenes/FinLujuria.tscn", "Continuar partida no lleva al final de Lujuria")
    _press_button(current_scene, "CONTINUAR A GULA")
    await create_timer(0.9).timeout
    _check_scene("Gula")
    if current_scene == null or current_scene.name != "Gula":
        _finish()
        return

    var gula: Node = current_scene
    gula.hud._select(0)
    var puerta_gula: Node = gula.markers.get_node("Puerta")
    gula._use_marker(puerta_gula)
    _check(current_scene == gula and not gula.boss_defeated, "La puerta de Gula se abre antes de vencer a Cerbero")
    for wave in ["entrada", "oeste", "este"]:
        gula._spawn_wave(wave)
    for offering in ["OfrendaOeste", "OfrendaEste"]:
        gula._sink_offering(gula.markers.get_node(offering))
        gula.hud._select(0)
    for soul in ["alma_daria", "alma_olmo"]:
        gula._talk_soul(soul)
        gula.hud._select(0)
        gula.hud._select(0)
    _check(not gula.boss_spawned, "Cerbero aparece antes de derrotar a sus guardianes")
    gula._back_to_menu()
    await process_frame
    await process_frame
    _press_button(current_scene, "Continuar partida anterior")
    await process_frame
    await process_frame
    _check_scene("Gula")
    if current_scene == null or current_scene.name != "Gula":
        _finish()
        return
    gula = current_scene
    puerta_gula = gula.markers.get_node("Puerta")
    _check(gula.offerings.size() == 2 and gula.decided.size() == 2 and gula.foes.get_child_count() == 6,
        "Continuar partida pierde los objetivos o enemigos de Gula")
    for enemy in gula.foes.get_children():
        enemy.take_damage(100, Vector2.DOWN)
    _check(gula.boss_spawned and is_instance_valid(gula.boss), "Cerbero no aparece tras los objetivos de Gula")
    if is_instance_valid(gula.boss):
        gula.boss.take_damage(100, Vector2.DOWN)
    _check(gula.boss_defeated, "La derrota de Cerbero no libera la salida")
    gula._use_marker(puerta_gula)
    await create_timer(0.9).timeout
    _check_scene("FinGula")
    _check(bool(game.progress["gula_completed"]), "El progreso de Gula no queda guardado")
    _check(game.next_scene() == "res://scenes/FinGula.tscn", "Continuar partida no lleva al final de Gula")
    _press_button(current_scene, "VOLVER AL MENÚ PRINCIPAL")
    await process_frame
    await process_frame
    _press_button(current_scene, "Continuar partida anterior")
    await process_frame
    await process_frame
    _check_scene("FinGula")
    _finish()

func _press_button(screen: Node, caption: String) -> void:
    if screen == null:
        failures.append("No hay pantalla para pulsar: " + caption)
        return
    for node in screen.find_children("*", "Button", true, false):
        var button: Button = node as Button
        if button.text == caption:
            button.pressed.emit()
            return
    failures.append("Falta el botón: " + caption)

func _check_scene(expected: String) -> void:
    _check(current_scene != null and current_scene.name == expected, "Se esperaba la escena " + expected)

func _check(ok: bool, message: String) -> void:
    if not ok and not message in failures:
        failures.append(message)

func _finish() -> void:
    if failures.is_empty():
        print("Limbo → Lujuria → Gula: recorrido completo correcto")
        quit(0)
    else:
        for failure in failures:
            push_error(failure)
        quit(1)
