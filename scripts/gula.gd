extends Node2D

## Círculo III: rutas de piedra, lodo que ralentiza y ofrendas que se hunden.
const BOSS_SCENE: PackedScene = preload("res://scenes/GulaCerbero.tscn")
const ENEMY_SCENES := {
    "penitente": preload("res://scenes/GulaPenitente.tscn"),
    "rastrero": preload("res://scenes/GulaRastrero.tscn"),
    "escanciador": preload("res://scenes/GulaEscanciador.tscn"),
}
const PROJECTILE_SCENE: PackedScene = preload("res://scenes/LujuriaProyectil.tscn")
const NAV_CELL := 20
const ENEMY_WAVES := {
    "entrada": [
        ["sur_penitente", "penitente", Vector2(640, 844)],
        ["sur_rastrero", "rastrero", Vector2(804, 841)],
    ],
    "oeste": [
        ["oeste_rastrero", "rastrero", Vector2(415, 573)],
        ["oeste_escanciador", "escanciador", Vector2(275, 470)],
    ],
    "este": [
        ["este_penitente", "penitente", Vector2(1033, 575)],
        ["este_escanciador", "escanciador", Vector2(1175, 470)],
    ],
}
const SPAWN := Vector2(724, 1015)
const SAMPLES := [Vector2.ZERO, Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN,
    Vector2(0.7071, 0.7071), Vector2(-0.7071, 0.7071), Vector2(0.7071, -0.7071), Vector2(-0.7071, -0.7071)]

@onready var hero: Variant = $Dante
@onready var hud: Variant = $HUD
@onready var floors: Node2D = $Suelo
@onready var mud: Node2D = $Lodo
@onready var markers: Node2D = $Marcadores
@onready var soul_nodes: Array[Node2D] = [$Marcadores/Daria, $Marcadores/Olmo]
@onready var foes: Node2D = $Enemigos
@onready var bullets: Node2D = $Proyectiles

var game_active := false
var paused := false
var offerings: Array[String] = []
var decided: Dictionary = {}
var boss_spawned := false
var boss_defeated := false
var intro_seen := false
var checkpoint := SPAWN
var dialogue_context := ""
var boss: Variant
var defeated_enemies: Dictionary = {}
var triggered_waves: Dictionary = {}
var navigation_grids: Dictionary = {}

var gate_art: Node2D
var pools: Array[Vector3] = []

func _ready() -> void:
    preload("res://scripts/foreground.gd").install($MapaPintado, hero, PackedVector2Array([Vector2(257,242),Vector2(258,226),Vector2(291,206),Vector2(316,207),Vector2(328,223),Vector2(317,246),Vector2(282,255)]), 249.0)
    gate_art = preload("res://scripts/gate_visual.gd").install(self, Rect2(669, 53, 109, 119), Color("e7e7a0"))
    Game.enter_gula()
    hero.world = self
    hero.health_changed.connect(_on_health_changed)
    hero.exhausted.connect(_on_exhausted)
    hud.configure_chapter("gula", hero)
    hud.option_selected.connect(_on_dialogue_selected)
    hud.pause_requested.connect(_toggle_pause)
    hud.exit_to_menu_requested.connect(_back_to_menu)
    _load_state()
    hero.restore(hero.max_health, checkpoint)
    hero.control_enabled = true
    _build_navigation()
    _restore_enemies()
    if boss_spawned and not boss_defeated:
        _spawn_boss()
    _refresh_hud()
    game_active = true
    if not intro_seen:
        _dialogue("intro", "VIRGILIO · CÍRCULO DE LA GULA",
            "La lluvia pudre el banquete y el lodo roba fuerza a tus pasos. Las ofrendas de ambos patios deben hundirse antes de enfrentar a Cerbero. Escucha también las voces que quedaron aquí.",
            ["Entrar en la Gula"])

func _process(delta: float) -> void:
    if game_active:
        _tick_residue(delta)
    hud.set_dash_fraction(1.0 - clampf(hero.dash_recharge / hero.dash_cooldown_duration, 0.0, 1.0))
    if not game_active or paused or hud.dialogue_open:
        hud.set_nearby("")
        return
    _trigger_encounters()
    var nearby: Variant = _nearest_marker()
    for marker in markers.get_children():
        marker.set("near", marker == nearby)
    hud.set_nearby(str(nearby.caption) if nearby != null else "")
    if Input.is_action_just_pressed("interact") and nearby != null:
        _use_marker(nearby)
    if Input.is_action_just_pressed("hint"):
        _show_hint()

func spawn_residue(point: Vector2) -> void:
    if can_walk(point, 8.0):
        pools.append(Vector3(point.x, point.y, 2.3))

func _tick_residue(delta: float) -> void:
    for i in range(pools.size() - 1, -1, -1):
        var pool := pools[i]
        pool.z -= delta
        if pool.z <= 0.0:
            pools.remove_at(i)
        else:
            pools[i] = pool
            if hero.global_position.distance_to(Vector2(pool.x, pool.y)) < 24.0:
                hero.take_damage(1)
                if not game_active:
                    return

func _draw() -> void:
    for pool in pools:
        var center := Vector2(pool.x, pool.y)
        draw_circle(center, 24.0, Color(0.32, 0.56, 0.10, minf(0.54, pool.z)))
        draw_arc(center, 23.0, 0.0, TAU, 26, Color(0.78, 0.89, 0.30, minf(0.65, pool.z)), 1.6)
    for area in mud.get_children():
        var polygon: PackedVector2Array = area.get("polygon")
        draw_colored_polygon(area.transform * polygon, Color(0.27, 0.35, 0.10, 0.20))

func can_walk(p: Vector2, radius: float = 10.0) -> bool:
    var guide := markers.get_node("Virgilio") as Node2D
    if preload("res://scripts/interaction_visual.gd").footprint(p, guide, radius):
        return false
    for offset in SAMPLES:
        var sample: Vector2 = p + offset * radius
        var found := false
        for area in floors.get_children():
            var polygon: PackedVector2Array = area.get("polygon")
            if Geometry2D.is_point_in_polygon(area.to_local(sample), polygon):
                found = true
                break
        if not found:
            return false
        for soul in soul_nodes:
            if ((sample - soul.global_position) / Vector2(11, 8)).length_squared() < 1.0:
                return false
    return true

func movement_factor(p: Vector2) -> float:
    for area in mud.get_children():
        var polygon: PackedVector2Array = area.get("polygon")
        if Geometry2D.is_point_in_polygon(area.to_local(p), polygon):
            return 0.56
    return 1.0

func can_occupy_hero(p: Vector2, _dodging: bool = false) -> bool:
    if not can_walk(p, 10.0):
        return false
    if is_instance_valid(boss) and not boss.dead and p.distance_to(boss.global_position) < 70.0:
        return false
    return true

func can_occupy_enemy(p: Vector2, moving_enemy: Node2D, radius: float) -> bool:
    if not can_walk(p, radius):
        return false
    if p.distance_to(hero.global_position) < radius + 10.0:
        return false
    if is_instance_valid(boss) and not boss.dead and p.distance_to(boss.global_position) < radius + boss.body_radius:
        return false
    for enemy in foes.get_children():
        if enemy != moving_enemy and enemy.active and not enemy.dead and p.distance_to(enemy.global_position) < radius + enemy.body_radius:
            return false
    return true

func has_clear_path(a: Vector2, b: Vector2, radius: float = 5.0) -> bool:
    var steps: int = maxi(1, ceili(a.distance_to(b) / 10.0))
    for i in range(1, steps):
        if not can_walk(a.lerp(b, float(i) / float(steps)), radius):
            return false
    return true

func _build_navigation() -> void:
    var map_size: Vector2 = $MapaPintado.texture.get_size()
    for clearance in [22, 29]:
        var grid := AStarGrid2D.new()
        grid.region = Rect2i(0, 0, ceili(map_size.x / float(NAV_CELL)), ceili(map_size.y / float(NAV_CELL)))
        grid.cell_size = Vector2(NAV_CELL, NAV_CELL)
        grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
        grid.update()
        for x in range(grid.region.size.x):
            for y in range(grid.region.size.y):
                var center: Vector2 = Vector2(x + 0.5, y + 0.5) * float(NAV_CELL)
                if not can_walk(center, float(clearance)):
                    grid.set_point_solid(Vector2i(x, y), true)
        navigation_grids[clearance] = grid

func route_to(from: Vector2, destination: Vector2, radius: float) -> PackedVector2Array:
    var grid: AStarGrid2D = navigation_grids[29 if radius > 22.0 else 22]
    var start: Vector2i = _nearest_nav_cell(grid, from)
    var finish: Vector2i = _nearest_nav_cell(grid, destination)
    var result := PackedVector2Array()
    if start.x < 0 or finish.x < 0:
        return result
    for id in grid.get_id_path(start, finish):
        result.append(Vector2(id.x + 0.5, id.y + 0.5) * float(NAV_CELL))
    return result

func _nearest_nav_cell(grid: AStarGrid2D, p: Vector2) -> Vector2i:
    var base := Vector2i(floori(p.x / NAV_CELL), floori(p.y / NAV_CELL))
    for ring in range(5):
        for x in range(base.x - ring, base.x + ring + 1):
            for y in range(base.y - ring, base.y + ring + 1):
                var cell := Vector2i(x, y)
                if grid.is_in_boundsv(cell) and not grid.is_point_solid(cell):
                    return cell
    return Vector2i(-1, -1)

func wind_at(_p: Vector2) -> Vector2:
    return Vector2.ZERO

func melee_hit(origin: Vector2, facing: Vector2) -> void:
    for enemy in foes.get_children():
        if not enemy.dead and enemy.active:
            var toward: Vector2 = enemy.global_position - origin
            var reach: float = 126.0 if enemy == boss else 91.0
            if toward.length() < reach and toward.normalized().dot(facing) > 0.2 and has_clear_path(origin, enemy.global_position):
                enemy.take_damage(2, facing)

func spawn_projectile(start: Vector2, direction: Vector2, hostile: bool, hit_damage: int) -> void:
    var shot: Variant = PROJECTILE_SCENE.instantiate()
    shot.position = start
    shot.direction = direction.normalized()
    shot.enemy_owned = hostile
    shot.damage = hit_damage
    shot.speed = 245.0 if hostile else 620.0
    shot.world = self
    bullets.add_child(shot)

func _nearest_marker() -> Variant:
    var best: Variant
    var best_distance := 96.0
    for marker in markers.get_children():
        var marker_node: Node2D = marker as Node2D
        var distance: float = hero.global_position.distance_to(marker_node.global_position)
        if distance < best_distance and (marker.kind not in ["alma", "guia"] or distance <= 65.0):
            best = marker
            best_distance = distance
    return best

func _use_marker(marker: Variant) -> void:
    match str(marker.uid):
        "virgilio":
            _show_hint()
        "ofrenda_oeste", "ofrenda_este":
            _sink_offering(marker)
        "alma_daria", "alma_olmo":
            _talk_soul(str(marker.uid))
        "puerta":
            if boss_defeated:
                _complete_level()
            else:
                _toast("Cerbero custodia el umbral. Hunda las ofrendas y escuche a las almas.")

func _sink_offering(marker: Variant) -> void:
    var uid: String = str(marker.uid)
    if uid in offerings:
        _toast("La ofrenda ya se hundió en el lodo.")
        return
    offerings.append(uid)
    hero.heal(1)
    marker.set_done(true)
    _save_state()
    _refresh_hud()
    _dialogue("ofrenda", "OFRENDA HUNDIDA",
        "La ofrenda se hunde lentamente y el lodo se traga sus restos. %d de 2 ofrendas han desaparecido." % offerings.size(),
        ["Continuar"])
    _check_boss_spawn()

func _talk_soul(uid: String) -> void:
    if decided.has(uid):
        _dialogue("short", uid.to_upper(), "Tu decisión permanece conmigo.", ["Continuar"])
    elif uid == "alma_daria":
        _dialogue(uid, "DARIA · ALMA DE LA GULA",
            "Acumulé comida mientras mis vecinos pasaban hambre. Ahora solo veo banquetes podridos. ¿Puedo compartir lo que me queda, aunque sea tarde?",
            ["Permitirle reparar su falta", "Recordarle el daño que causó"])
    else:
        _dialogue(uid, "OLMO · ALMA DE LA GULA",
            "Fui cocinero y desperdicié cuanto otros necesitaban. Aquí la mesa se hunde conmigo. ¿Merece mi oficio una segunda oportunidad?",
            ["Animarlo a alimentar a otros", "Juzgar su derroche"])

func _dialogue(context: String, title: String, message: String, options: Array) -> void:
    dialogue_context = context
    game_active = false
    hero.control_enabled = false
    hud.show_dialogue(title, message, options)

func _on_dialogue_selected(choice: int) -> void:
    if dialogue_context == "death":
        if is_instance_valid(boss) and not boss.dead:
            boss.reset_encounter()
        hero.restore(hero.max_health, SPAWN)
    elif dialogue_context == "intro":
        intro_seen = true
    elif dialogue_context == "alma_daria" or dialogue_context == "alma_olmo":
        if not decided.has(dialogue_context):
            decided[dialogue_context] = choice
            Game.decide(dialogue_context, choice == 0)
            for marker in markers.get_children():
                if str(marker.get("uid")) == dialogue_context:
                    marker.call("set_done", true)
            _save_state()
            _refresh_hud()
            _dialogue("short", "ECO DE LA GULA",
                "Tu respuesta permanecerá con esta alma.", ["Continuar"])
            _check_boss_spawn()
            return
    dialogue_context = ""
    _save_state()
    _refresh_hud()
    game_active = true
    hero.control_enabled = true

func _show_hint() -> void:
    if offerings.size() < 2:
        _toast("VIRGILIO: Busca las dos ofrendas en los patios laterales.", 5.0)
    elif decided.size() < 2:
        _toast("VIRGILIO: Escucha a Daria y Olmo antes de subir.", 5.0)
    elif not boss_spawned and not boss_defeated:
        _toast("VIRGILIO: Derrota a las criaturas que aún custodian el círculo.", 5.0)
    elif not boss_defeated:
        _toast("VIRGILIO: Cerbero espera en la arena superior. Esquiva su aullido.", 5.0)
    else:
        _toast("VIRGILIO: La puerta del norte está libre.", 5.0)

func _check_boss_spawn() -> void:
    if boss_spawned or boss_defeated or offerings.size() < 2 or decided.size() < 2:
        return
    for enemy in foes.get_children():
        if enemy != boss and not enemy.dead and enemy.active:
            return
    boss_spawned = true
    _spawn_boss()
    _save_state()
    _toast("¡Cerbero ha despertado en la arena superior!", 5.0)

func _spawn_boss() -> void:
    boss = BOSS_SCENE.instantiate()
    boss.position = Vector2(724, 310)
    boss.world = self
    boss.hero = hero
    boss.hp_changed.connect(hud.set_boss_health)
    boss.defeated.connect(_on_boss_defeated)
    foes.add_child(boss)
    hud.boss_text.text = "CERBERO"
    hud.set_boss_health(boss.hp, boss.max_hp)

func _trigger_encounters() -> void:
    if boss_defeated:
        return
    var p: Vector2 = hero.global_position
    if not triggered_waves.has("entrada") and p.y < 930.0:
        _spawn_wave("entrada")
    if not triggered_waves.has("oeste") and p.x < 480.0 and p.y > 390.0 and p.y < 670.0:
        _spawn_wave("oeste")
    if not triggered_waves.has("este") and p.x > 968.0 and p.y > 390.0 and p.y < 670.0:
        _spawn_wave("este")

func _spawn_wave(key: String) -> void:
    if triggered_waves.has(key) or not ENEMY_WAVES.has(key) or boss_defeated:
        return
    triggered_waves[key] = true
    for entry in ENEMY_WAVES[key]:
        if not defeated_enemies.has(str(entry[0])):
            _spawn_enemy(entry)
    _save_state()

func _restore_enemies() -> void:
    if boss_defeated:
        return
    for key in ENEMY_WAVES.keys():
        if not triggered_waves.has(key):
            continue
        for entry in ENEMY_WAVES[key]:
            if not defeated_enemies.has(str(entry[0])):
                _spawn_enemy(entry)

func _spawn_enemy(entry: Array) -> void:
    var uid: String = str(entry[0])
    var enemy: Variant = ENEMY_SCENES[str(entry[1])].instantiate()
    enemy.spawn_id = uid
    enemy.position = entry[2]
    enemy.world = self
    enemy.hero = hero
    enemy.died.connect(_on_enemy_died)
    foes.add_child(enemy)
    if not can_walk(enemy.global_position, enemy.body_radius):
        push_error("Punto de aparición fuera del suelo: " + uid)

func _on_enemy_died(uid: String) -> void:
    defeated_enemies[uid] = true
    _save_state()
    _check_boss_spawn()

func _on_boss_defeated() -> void:
    boss_defeated = true
    for enemy in foes.get_children():
        if enemy != boss:
            enemy.queue_free()
    hud.hide_boss()
    for marker in markers.get_children():
        if str(marker.get("uid")) == "puerta":
            marker.call("set_done", true)
    _save_state()
    _refresh_hud()
    _toast("Cerbero ha caído. El umbral del norte está abierto.", 5.0)

func _load_state() -> void:
    var data: Dictionary = Game.progress
    var saved_offerings: Variant = data.get("gula_offerings", [])
    offerings.clear()
    if saved_offerings is Array:
        for value in saved_offerings:
            var uid: String = str(value)
            if uid in ["ofrenda_oeste", "ofrenda_este"] and not uid in offerings:
                offerings.append(uid)
    var saved_decisions: Variant = data.get("gula_decisions", {})
    decided = saved_decisions.duplicate(true) if saved_decisions is Dictionary else {}
    intro_seen = bool(data.get("gula_intro_seen", false))
    boss_spawned = bool(data.get("gula_boss_spawned", false))
    boss_defeated = bool(data.get("gula_boss_defeated", false))
    var saved_enemies: Variant = data.get("gula_defeated_enemies", {})
    defeated_enemies = saved_enemies.duplicate(true) if saved_enemies is Dictionary else {}
    var saved_waves: Variant = data.get("gula_triggered_waves", {})
    triggered_waves = saved_waves.duplicate(true) if saved_waves is Dictionary else {}
    checkpoint = Vector2(float(data.get("gula_checkpoint_x", SPAWN.x)), float(data.get("gula_checkpoint_y", SPAWN.y)))
    if not can_walk(checkpoint, 10.0):
        checkpoint = SPAWN
    for marker in markers.get_children():
        var marker_id: String = str(marker.get("uid"))
        marker.call("set_done", marker_id in offerings or marker_id in decided or marker_id == "puerta" and boss_defeated)

func _save_state() -> void:
    Game.progress["circle"] = "gula"
    Game.progress["gula_started"] = true
    Game.progress["gula_offerings"] = offerings.duplicate()
    Game.progress["gula_decisions"] = decided.duplicate(true)
    Game.progress["gula_intro_seen"] = intro_seen
    Game.progress["gula_boss_spawned"] = boss_spawned
    Game.progress["gula_boss_defeated"] = boss_defeated
    Game.progress["gula_defeated_enemies"] = defeated_enemies.duplicate(true)
    Game.progress["gula_triggered_waves"] = triggered_waves.duplicate(true)
    Game.progress["gula_checkpoint_x"] = checkpoint.x
    Game.progress["gula_checkpoint_y"] = checkpoint.y
    Game.save_progress()

func _refresh_hud() -> void:
    gate_art.set("open", boss_defeated)
    hud.set_gula_state(Game.progress, offerings.size(), decided.size(), boss_defeated)
    hud.set_health(hero.health, hero.max_health)

func _on_health_changed(current: int, maximum: int) -> void:
    hud.set_health(current, maximum)

func _on_exhausted() -> void:
    game_active = false
    for shot in bullets.get_children():
        shot.queue_free()
    _save_state()
    pools.clear()
    _toast("Dante ha caído. Regresa al inicio del círculo con su progreso guardado.", 4.5)
    await get_tree().create_timer(1.1).timeout
    if not is_inside_tree():
        return
    _dialogue("death", "VIRGILIO", ("Cerbero te ha derribado. Recobra el aliento, Dante. Al oír su aullido, gana distancia." if is_instance_valid(boss) and not boss.dead else "El lodo y sus guardianes te han abatido, Dante. Busca la piedra firme antes de volver a atacar.") + " Volverás a la entrada con tus ofrendas y decisiones guardadas.", ["Volver al inicio"])

func _complete_level() -> void:
    game_active = false
    hero.control_enabled = false
    Game.progress["gula_completed"] = true
    _save_state()
    Game.cross_threshold("res://scenes/FinGula.tscn")

func _toggle_pause() -> void:
    if hud.dialogue_open or (not game_active and not paused):
        return
    paused = not paused
    game_active = not paused
    hero.control_enabled = not paused
    hud.set_pause(paused)

func _back_to_menu() -> void:
    _save_state()
    get_tree().change_scene_to_file("res://scenes/MenuPrincipal.tscn")

func _toast(message: String, duration: float = 3.5) -> void:
    hud.toast(message, duration)
