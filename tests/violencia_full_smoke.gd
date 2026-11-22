extends SceneTree
var failures := 0
var checks := 0
var game
func _initialize() -> void:
    call_deferred("run_checks")
func check(ok: bool, label: String) -> void:
    checks += 1
    print(("PASS " if ok else "FAIL ")+label)
    if not ok:
        failures += 1
func close_dialogue(level) -> void:
    if level.hud.dialogue_open:
        level.hud._select(0)
func run_checks() -> void:
    game = root.get_node("Game")
    game.save_path = "res://.godot/violencia_full_test_save.json"
    game.new_game()
    var g = load("res://scripts/violencia_geometry.gd").new()
    check(g.can_walk(g.SPAWN,14),"Aparicion sobre piedra")
    check(not g.can_walk(Vector2(500,1130),14),"Rio fuera del puente bloqueado")
    check(g.can_walk(Vector2(1152,1130),14),"Puente abierto")
    check(g.can_walk(Vector2(1152,1000),14),"Escalera inferior abierta")
    check(g.can_walk(Vector2(1152,610),14),"Escalera superior abierta")
    check(not g.can_walk(Vector2(865,282),14),"Columna superior bloqueada")
    check(not g.can_walk(Vector2(585,790),14),"Obelisco bloqueado")
    check(not g.can_walk(Vector2(120,800),14),"Bosque decorativo fuera del camino")
    var reached := {Vector2i(58,70):true}
    var cells: Array[Vector2i] = [Vector2i(58,70)]
    var cursor := 0
    while cursor < cells.size():
        var cell := cells[cursor]
        cursor += 1
        for offset in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
            var next: Vector2i = cell+offset
            if reached.has(next):
                continue
            var target := Vector2(next)*20
            if g.can_walk(target,14) and g.move_on_ground(Vector2(cell)*20,Vector2(offset)*20,14).distance_to(target) < 0.1:
                reached[next] = true
                cells.append(next)
    var Level = load("res://scripts/violencia.gd")
    for point in Level.POINTS:
        var nearest := INF
        for cell in cells:
            nearest = minf(nearest,(Vector2(cell)*20).distance_to(point["p"]))
        check(nearest < 91,"Acceso a "+str(point["id"]))
    var slide: Vector2 = g.move_on_ground(Vector2(1152,1090),Vector2(-900,0),14)
    check(slide.x > 930,"Barrido largo no cruza al rio")
    var level = load("res://scenes/Violencia.tscn").instantiate()
    root.add_child(level)
    await process_frame
    check(level.hud.current_circle == "violencia","HUD del circulo VII")
    check(level.hud.minimap.mode == "violencia","Minimapa del nuevo mundo")
    check(not level.game_active and not level.hero.control_enabled,"Dialogo inicial bloquea movimiento")
    close_dialogue(level)
    check(level.game_active and level.data["intro"],"Cerrar intro habilita el juego")
    level._activate_seal("tregua")
    check(level.data["seals"].is_empty(),"Orden incorrecto no avanza ritual")
    for seal in ["contencion","memoria","tregua"]:
        level._activate_seal(seal)
        for guardian in level.foes.get_children():
            if guardian.uid == "guardian_"+seal and not guardian.dead:
                guardian.take_damage(100)
        level._activate_seal(seal)
        close_dialogue(level)
    check(level.data["seals"].size() == 3,"Tres votos se activan en orden")
    level._use_marker("guardia")
    level.hud._select(0)
    level._use_marker("testigo")
    level.hud._select(1)
    check(game.progress["redencion"] == 1 and game.progress["rigor"] == 1,"Ambas rutas morales modifican contadores")
    check(level._ritual_complete(),"Ambas rutas permiten llegar al jefe")
    level._use_marker("guardia")
    close_dialogue(level)
    check(game.progress["redencion"] == 1,"Una decision no suma dos veces")
    var before: Vector2 = level.hero.position
    level._toggle_pause()
    var time_before: float = level.heat_clock
    level._process(1.0)
    check(not level.game_active and level.heat_clock == time_before,"Pausa detiene calor y combate")
    level._toggle_pause()
    level.heat_clock = 2.8
    check(not level.heat_active(),"Aviso termico no causa dano")
    level.heat_clock = 4.0
    check(level.heat_active(),"Pulso termico activo")
    check(not level._on_hot_sand(Vector2(1152,400)),"Piedra central segura")
    check(level._on_hot_sand(Vector2(500,400)),"Arena lateral expuesta al calor")
    var bullet_count: int = level.bullets.get_child_count()
    level.spawn_projectile(Vector2(1152,1400),Vector2.UP,false,2)
    check(level.bullets.get_child_count() == bullet_count+1,"Verso se instancia")
    var frames = level.hero.art.sprite_frames
    var valid_frames := true
    for animation in frames.get_animation_names():
        if animation == "default":
            continue
        for i in range(frames.get_frame_count(animation)):
            var bounds: Rect2i = frames.get_frame_texture(animation,i).get_image().get_used_rect()
            valid_frames = valid_frames and bounds.position.x > 0 and bounds.position.y > 0 and bounds.end.x < 80 and bounds.end.y < 96
    check(valid_frames,"Dante: todos los fotogramas tienen margen sin cortes")
    check(level.markers["virgilio"].art.texture.get_size() == Vector2(80,128),"Virgilio: ilustracion reconstruida del recurso original")
    level.hero.position = Vector2(1152,450)
    level._begin_boss()
    close_dialogue(level)
    await process_frame
    var boss = level.boss_actor
    check(boss.art.sprite_frames.has_animation("walk_left") and boss.art.sprite_frames.has_animation("walk_right") and boss.art.sprite_frames.has_animation("walk_up") and boss.art.sprite_frames.has_animation("walk_down"),"Minotauro: cuatro angulos animados")
    check(level.boss_fighting and boss.hp == 48,"Comienza combate con Minotauro")
    check(not level.can_walk(Vector2(1152,610),14),"Arena se cierra durante el combate")
    boss.position = Vector2(1152,320)
    level.hero.position = Vector2(1152,440)
    boss.begin_charge()
    var aimed: Vector2 = boss.charge_direction
    level.hero.position = Vector2(1300,430)
    boss._boss_tick(0.1)
    check(boss.charge_direction == aimed,"Carga fija direccion y permite esquiva lateral")
    boss.state = "charge"
    boss.timer = 1.2
    boss.position = Vector2(1152,475)
    boss.charge_direction = Vector2.DOWN
    boss._boss_tick(0.1)
    check(boss.state == "stunned","Chocar contra muro aturde al jefe")
    var hp_before: int = boss.hp
    boss.take_damage(2)
    check(boss.hp == hp_before-4,"Aturdido recibe doble dano")
    boss.hp = 24
    boss._boss_tick(0.01)
    check(boss.phase == 2,"Segunda fase al llegar a media salud")
    level.hero.health = 1
    level.hero.invulnerable = 0
    level.hero.take_damage(1)
    check(level.hud.dialogue_open and not level.game_active,"Derrota muestra reintento")
    close_dialogue(level)
    await process_frame
    check(level.hero.health == 6 and level.hero.position == g.SPAWN,"Reintento restaura salud en entrada")
    check(level.data["seals"].size() == 3 and level.data["decisions"].size() == 2,"Derrota conserva ritual y moralidad")
    level.hero.position = Vector2(1152,450)
    level._begin_boss()
    close_dialogue(level)
    await process_frame
    boss = level.boss_actor
    boss.take_damage(100)
    check(level.data["boss_down"] and not level.boss_fighting,"Victoria abre la arena")
    check(game.progress["dash_extended"] and level.hero.dash_duration > 0.18 and level.hero.dash_invulnerability > 0.28 and level.hero.dash_cooldown_duration < 0.85,"Premio mejora distancia, proteccion y recarga")
    close_dialogue(level)
    level._save()
    var decision_copy: Dictionary = level.data["decisions"].duplicate()
    game.load_progress()
    check(game.progress["violencia"]["boss_down"] and game.progress["dash_extended"],"Victoria y mejora persisten al recargar")
    check(game.next_scene() == "res://scenes/Violencia.tscn","Continuar selecciona Violencia")
    level.ambient.stop()
    for sound in level.sounds.values():
        sound.stop()
    await create_timer(0.2).timeout
    level.queue_free()
    await process_frame
    var reopened = load("res://scenes/Violencia.tscn").instantiate()
    root.add_child(reopened)
    await process_frame
    check(reopened.data["decisions"] == decision_copy and reopened.hero.dash_duration > 0.18,"Volver conserva decisiones y esquiva")
    check(not reopened.boss_fighting,"Jefe vencido no reaparece")
    reopened.data["completed"] = true
    reopened._save()
    check(game.next_scene() == "res://scenes/FinViolencia.tscn","Continuar tras completar abre desenlace")
    reopened.ambient.stop()
    await create_timer(0.2).timeout
    reopened.queue_free()
    await process_frame
    print("RESULTADO VIOLENCIA: %d comprobaciones, %d fallos" % [checks,failures])
    g = null
    call_deferred("quit",1 if failures else 0)
