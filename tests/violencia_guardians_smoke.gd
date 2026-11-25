extends SceneTree
var failures := 0
var checks := 0
func _initialize() -> void:
    call_deferred("run")
func check(ok: bool, label: String) -> void:
    checks += 1
    print(("PASS " if ok else "FAIL ")+label)
    if not ok:
        failures += 1
func stop_audio(node: Node) -> void:
    if node is AudioStreamPlayer:
        node.stop()
    for child in node.get_children():
        stop_audio(child)
func run() -> void:
    var game = root.get_node("Game")
    game.save_path = "res://.godot/violencia_guardians_test_save.json"
    game.new_game()
    var level = load("res://scenes/Violencia.tscn").instantiate()
    root.add_child(level)
    await process_frame
    level.hud._select(0)
    level.set_process(false)
    check(level.foes.get_child_count()==0,"No aparecen al cargar sin acercarse")
    var maps := {"contencion":"centauro","memoria":"mastin","tregua":"ceniza"}
    for seal in level.SEAL_ORDER:
        var point: Vector2 = level.markers[seal].position
        level.hero.position = point+Vector2(0,200)
        level._encounters()
        check(not ("pilar_"+seal in level.data["waves"]),"Fuera de radio: "+seal)
        level.hero.position = point+Vector2(45,20)
        level._encounters()
        var enemy
        for child in level.foes.get_children():
            if child.uid == "guardian_"+seal:
                enemy = child
        check(is_instance_valid(enemy),"Aparicion por proximidad: "+seal)
        enemy.set_physics_process(false)
        check(enemy.archetype == maps[seal],"Tipo exclusivo correcto: "+seal)
        check(level.geometry.can_walk(enemy.position,enemy.body_radius),"Aparece sobre suelo valido: "+seal)
        check(enemy.art.sprite_frames.has_animation("death_up") and enemy.art.sprite_frames.has_animation("walk_left") and enemy.art.sprite_frames.has_animation("attack_right"),"Animaciones con cuatro orientaciones: "+seal)
        var count: int = level.foes.get_child_count()
        level._encounters()
        level._encounters()
        check(level.foes.get_child_count()==count,"No duplica al permanecer cerca: "+seal)
        var step: int = level.data["seals"].size()
        level._activate_seal(seal)
        check(level.data["seals"].size()==step,"Guardián vivo impide activar: "+seal)
        if seal == "contencion":
            enemy.charge_direction = Vector2.UP
            enemy.attack_kind = "arrows"
            var shots: int = level.bullets.get_child_count()
            enemy._release_guardian_attack()
            check(level.bullets.get_child_count()==shots+3,"Centauro dispara abanico de flechas")
            check(enemy.choose_attack(65)=="spear","Centauro usa lanza cerca")
            enemy.attack_kind = "charge"
            enemy._release_guardian_attack()
            check(enemy.state=="dash","Centauro tiene embestida")
        elif seal == "memoria":
            check(enemy.choose_attack(60)=="bite","Mastin elige mordida")
            check(enemy.choose_attack(180)=="leap","Mastin elige salto")
            enemy.attack_kind = "leap"
            enemy.charge_direction = Vector2.RIGHT
            enemy._release_guardian_attack()
            var old: Vector2 = enemy.position
            enemy._common_tick(0.08)
            check(enemy.position.distance_to(old)>1,"Salto desplaza al mastin por suelo")
        else:
            enemy.attack_kind = "fire"
            var shots: int = level.bullets.get_child_count()
            enemy._release_guardian_attack()
            check(level.bullets.get_child_count()==shots+3,"Ceniza lanza fuego en abanico")
            enemy.attack_kind = "ash"
            shots = level.bullets.get_child_count()
            enemy._release_guardian_attack()
            check(level.bullets.get_child_count()>=shots+6,"Ceniza crea descarga y ceniza persistente")
            check(enemy.choose_attack(70)=="sweep","Ceniza usa espada cerca")
        # Un golpe cercano debe dañar al frente y fallar si Dante se aparta.
        level.hero.invulnerable = 0
        level.hero.health = 6
        enemy.attack_kind = "bite" if seal == "memoria" else "spear" if seal == "contencion" else "sweep"
        var blocked_target: Vector2 = enemy.position + Vector2.DOWN * 40.0
        if not level.has_clear_path(enemy.position, blocked_target):
            level.hero.position = blocked_target
            enemy.charge_direction = Vector2.DOWN
            enemy._release_guardian_attack()
            check(level.hero.health == 6, "El ataque no atraviesa el borde: " + seal)
        var clear_direction := Vector2.ZERO
        for direction in [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT]:
            if level.has_clear_path(enemy.position, enemy.position + direction * 40.0):
                clear_direction = direction
                break
        check(clear_direction != Vector2.ZERO, "Hay suelo para probar el ataque: " + seal)
        level.hero.position = enemy.position + clear_direction * 40.0
        enemy.charge_direction = clear_direction
        enemy._release_guardian_attack()
        check(level.hero.health==5,"Ataque cercano aplica daño: "+seal)
        level.hero.invulnerable = 0
        level.hero.position = enemy.position - clear_direction * 150.0
        enemy._release_guardian_attack()
        check(level.hero.health==5,"Apartarse evita el golpe: "+seal)
        enemy.take_damage(100)
        check("guardian_"+seal in level.data["defeated"],"Derrota se registra: "+seal)
        level._activate_seal(seal)
        if level.hud.dialogue_open:
            level.hud._select(0)
        check(seal in level.data["seals"],"Voto disponible tras derrotarlo: "+seal)
        level._encounters()
        check(level.foes.get_child_count()==count,"No reaparece tras morir: "+seal)
        for shot in level.bullets.get_children():
            shot.queue_free()
        await process_frame
    level._save()
    game.load_progress()
    check(game.progress["violencia"]["waves"].size()==3,"Se guardan tres encuentros")
    check(game.progress["violencia"]["defeated"].size()==3,"Se guardan tres derrotas")
    var migrated: Dictionary = level._validated_state({"waves":["rio","bosque"],"seals":["contencion"],"decisions":{"guardia":"rigor"}})
    check(migrated["waves"].is_empty() and migrated["seals"].size()==1 and migrated["decisions"].size()==1,"Migra oleadas antiguas sin perder votos ni decisiones")
    # Reintento con guardián vivo: no omitirlo por objetos que esperan queue_free.
    level.data["defeated"].erase("guardian_memoria")
    level._spawn_wave("pilar_memoria")
    level._respawn()
    await process_frame
    var alive := 0
    for enemy in level.foes.get_children():
        if enemy.uid=="guardian_memoria" and not enemy.dead:
            alive += 1
    check(alive==1,"Reintento restaura una sola copia del guardián vivo")
    level.data["waves"].erase("pilar_contencion")
    level.data["defeated"].erase("guardian_contencion")
    level.hero.position = level.markers["contencion"].position
    level.boss_fighting = true
    level._encounters()
    check(not "pilar_contencion" in level.data["waves"],"Durante duelo no aparecen guardianes de pilares")
    level.boss_fighting = false
    level.data["boss_down"] = true
    level._encounters()
    check("pilar_contencion" in level.data["waves"],"Partida antigua con jefe vencido puede ver guardianes nuevos")
    stop_audio(level)
    await create_timer(0.2).timeout
    level.queue_free()
    await process_frame
    print("RESULTADO GUARDIANES: %d comprobaciones, %d fallos" % [checks,failures])
    call_deferred("quit",1 if failures else 0)
