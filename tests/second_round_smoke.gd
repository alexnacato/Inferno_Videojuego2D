extends SceneTree


var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var game = root.get_node("Game")
    var relic_script: Script = load("res://scripts/chapter_relic.gd")
    game.new_game()
    for title in ["Limbo", "Lujuria", "Gula", "Violencia", "Traicion"]:
        var circle: String = title.to_lower()
        var level = load("res://scenes/%s.tscn" % title).instantiate()
        root.add_child(level)
        await process_frame
        var actor = level.player if circle == "limbo" else level.hero
        if level.hud.dialogue_open:
            level.hud._select(0)
        var collection: Array = level.markers.values() if level.markers is Dictionary else level.markers.get_children()
        for marker in collection:
            if marker.kind not in ["guide", "guia", "virgilio", "soul", "alma", "paolo", "francesca"]:
                continue
            var valid: Callable = level.can_walk.bind(10.0) if circle == "limbo" else level.can_occupy_hero
            _check(not valid.call(marker.global_position), "Dante atraviesa un NPC de " + title + " " + marker.name)
        var point: Vector2 = relic_script.RELICS[circle][0]
        _check(level.can_walk(point, 10.0), "Reliquia fuera de suelo en " + title)
        actor.global_position = point
        for frame in range(4):
            await process_frame
        _check(game.has_relic(circle), "La reliquia no se recoge en " + title)
        _check(level.hud.relic_status.text.contains("encontrada"), "La reliquia no se refleja en el HUD")
        level.queue_free()
        await process_frame
    game.load_progress()
    _check(game.progress["relics"].size() == 5, "Se perdieron reliquias al cargar")
    for state in [[6, 4, "luz"], [5, 0, "ceniza"], [7, 6, "ceniza"]]:
        game.progress = game.default_progress()
        game.progress["traicion_completed"] = true
        game.progress["redencion"] = state[0]
        game.progress["rigor"] = state[1]
        _check(game.record_ending() == state[2], "Resultado incorrecto para %d / %d" % [state[0], state[1]])
        game.load_progress()
        _check(game.progress["ending"] == state[2], "El desenlace no se guardó")
    for path in ["npcs/judas", "npcs/hitler", "world/final_luz", "world/final_ceniza"]:
        _check(ResourceLoader.exists("res://assets/traicion/" + path + ".png"), "Falta importar " + path)
    for failure in failures:
        push_error(failure)
    if failures.is_empty():
        print("Ronda dos: reliquias, colisiones, grabados y ambos finales verificados.")
    quit(0 if failures.is_empty() else 1)

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
