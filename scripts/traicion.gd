extends Node2D

## Círculo IX: Cocito, juramentos rotos y el guardián del hielo.
const BOSS_SCENE: PackedScene = preload("res://scenes/TraicionLucifer.tscn")
const PROJECTILE_SCENE: PackedScene = preload("res://scenes/LujuriaProyectil.tscn")
const FOE_SCENE := preload("res://scenes/GulaEnemigo.tscn")
const ICE_FOE := preload("res://scripts/traicion_enemigo.gd")
const WALK_SOLVER := preload("res://scripts/walk_solver.gd")
const SPAWN := Vector2(724, 1000)
const NAV_CELL := 16
const ENCOUNTERS := {
    "custodio_oeste": ["penitente", Vector2(340, 602)],
    "sabueso_oeste": ["rastrero", Vector2(224, 659)],
    "sabueso_este": ["rastrero", Vector2(1216, 656)],
    "espectro_este": ["escanciador", Vector2(1083, 618)],
    "espectro_centro": ["escanciador", Vector2(724, 519)],
}
const SAMPLES := [Vector2.ZERO, Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN,
    Vector2(0.7071, 0.7071), Vector2(-0.7071, 0.7071), Vector2(0.7071, -0.7071), Vector2(-0.7071, -0.7071)]

@onready var hero: Variant = $Dante
@onready var hud: Variant = $HUD
@onready var floors: Node2D = $Suelo
@onready var thin_ice: Node2D = $HieloFino
@onready var markers: Node2D = $Marcadores
@onready var foes: Node2D = $Enemigos
@onready var bullets: Node2D = $Proyectiles

var game_active := false
var paused := false
var seals: Array[String] = []
var decided: Dictionary = {}
var boss_spawned := false
var boss_defeated := false
var intro_seen := false
var checkpoint := SPAWN
var dialogue_context := ""
var boss: Variant
var frost_time := 0.0
var defeated_enemies: Array[String] = []
var encountered: Dictionary = {}
var ice_break_point := Vector2.ZERO
var ice_break_time := 0.0
var navigation: Dictionary = {}
var nav_dimensions := Vector2i.ZERO
var debug_collision := false
var solid_markers: Array[Node2D] = []
var floor_shapes: Array[PackedVector2Array] = []
var obstacle_shapes: Array[PackedVector2Array] = []

var gate_art: Node2D

func _ready() -> void:
    preload("res://scripts/foreground.gd").install($Cocito, hero, PackedVector2Array([Vector2(240,62),Vector2(251,46),Vector2(266,22),Vector2(280,9),Vector2(299,32),Vector2(315,64),Vector2(302,72),Vector2(251,72)]), 70.0)
    gate_art = preload("res://scripts/gate_visual.gd").install(self, Rect2(677, 76, 91, 104), Color("a8eaff"))
    Game.enter_traicion()
    hero.world = self
    hero.health_changed.connect(_on_health_changed)
    hero.exhausted.connect(_on_exhausted)
    hud.configure_chapter("traicion", hero)
    hud.option_selected.connect(_on_dialogue_selected)
    hud.pause_requested.connect(_toggle_pause)
    hud.exit_to_menu_requested.connect(_back_to_menu)
    for area in floors.get_children():
        floor_shapes.append(area.global_transform * area.polygon)
    for area in $Obstaculos.get_children():
        obstacle_shapes.append(area.global_transform * area.polygon)
    for marker in markers.get_children():
        if marker.kind in ["guia", "alma", "brasero", "inscripcion"]:
            solid_markers.append(marker)
    _load_state()
    if not boss_spawned and not boss_defeated:
        _build_navigation()
    hero.restore(hero.max_health, checkpoint)
    hero.control_enabled = true
    if boss_spawned and not boss_defeated:
        _spawn_boss()
    else:
        _check_boss_spawn()
    _refresh_hud()
    game_active = true
    if not intro_seen:
        _dialogue("intro", "VIRGILIO · COCITO",
            "Aquí el castigo no arde: congela. Dos juramentos mantienen preso el paso hacia el centro. Vence a los guardianes, rompe los juramentos y escucha a las almas. Usa el brasero antes de enfrentar a quien yace bajo el hielo.",
            ["Entrar en Traición"])

func _process(delta: float) -> void:
    ice_break_time = maxf(0.0, ice_break_time - delta)
    queue_redraw()
    hud.set_dash_fraction(1.0 - clampf(hero.dash_recharge / hero.dash_cooldown_duration, 0.0, 1.0))
    if not game_active or paused or hud.dialogue_open:
        hud.set_nearby("")
        return
    _spawn_enemies(hero.global_position)
    var nearby: Variant = _nearest_marker()
    for marker in markers.get_children():
        marker.set("near", marker == nearby)
    hud.set_nearby(str(nearby.caption) if nearby != null else "")
    if Input.is_action_just_pressed("interact") and nearby != null:
        _use_marker(nearby)
        if not game_active:
            return
    if Input.is_action_just_pressed("hint"):
        _show_hint()
    if _on_thin_ice(hero.global_position) and hero.dash_time <= 0.0:
        frost_time += delta
        if frost_time >= (3.8 if Game.has_relic("traicion") else 2.2):
            frost_time = 0.0
            ice_break_point = hero.global_position
            ice_break_time = 1.1
            AudioManager.cue("hielo")
            hero.take_damage(hero.max_health, true)
    else:
        frost_time = maxf(0.0, frost_time - delta * 2.0)

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
        debug_collision = not debug_collision
        queue_redraw()
        get_viewport().set_input_as_handled()

func _draw() -> void:
    if ice_break_time > 0.0:
        var fall := 1.0 - ice_break_time / 1.1
        draw_circle(ice_break_point, 16.0 + fall * 20.0, Color("#0c1d32"))
        for i in range(13):
            var ray := Vector2.RIGHT.rotated(TAU * i / 13.0)
            var tip := ice_break_point + ray * (19.0 + fall * (22.0 + i % 3 * 8.0))
            draw_line(ice_break_point, tip, Color(0.75, 0.94, 1.0, ice_break_time * 0.8), 1.5)
            draw_colored_polygon(PackedVector2Array([tip + ray * 5.0, tip + ray.orthogonal() * 3.0, tip - ray * 4.0]), Color(0.64, 0.87, 1.0, ice_break_time * 0.8))
    if debug_collision:
        for area in floors.get_children():
            draw_colored_polygon(area.transform * area.polygon, Color(0.18, 0.9, 0.55, 0.20))
        for area in $Obstaculos.get_children():
            draw_colored_polygon(area.transform * area.polygon, Color(0.9, 0.2, 0.25, 0.54))
        for marker in solid_markers:
            draw_circle(marker.position, 11.0, Color(0.9, 0.2, 0.25, 0.54))
        if is_instance_valid(boss) and not boss.dead:
            draw_arc(to_local(boss.global_position), boss.body_radius + 10.0, 0.0, TAU, 48, Color.TOMATO, 2.0)
    var shimmer := Time.get_ticks_msec() * 0.001
    for area in thin_ice.get_children():
        var polygon: PackedVector2Array = area.transform * area.get("polygon")
        var tint := Color(0.61, 0.83, 0.88, 0.032)
        draw_colored_polygon(polygon, tint)
        var center := Rect2(polygon[0], Vector2.ZERO)
        for tip in polygon:
            center = center.expand(tip)
        for i in range(polygon.size()):
            var direction := center.get_center().direction_to(polygon[i])
            var length := center.get_center().distance_to(polygon[i])
            var root := center.get_center()
            var bend := root + direction * length * 0.41 + direction.orthogonal() * 9.0
            var opacity := 0.24 + 0.16 * sin(shimmer * 1.7 + i * 0.84)
            draw_polyline(PackedVector2Array([root, bend, polygon[i]]), Color(0.79, 0.94, 0.97, opacity), 2.0, true)
            draw_line(bend, bend + direction.rotated(0.62) * 24.0, Color(0.76, 0.90, 0.93, opacity * 0.72), 1.0, true)

func can_walk(p: Vector2, radius: float = 10.0) -> bool:
    for offset in SAMPLES:
        var sample: Vector2 = p + offset * radius
        var found := false
        for polygon in floor_shapes:
            if Geometry2D.is_point_in_polygon(sample, polygon):
                found = true
                break
        if not found:
            return false
        for polygon in obstacle_shapes:
            if Geometry2D.is_point_in_polygon(sample, polygon):
                return false
        for marker in solid_markers:
            if sample.distance_squared_to(marker.global_position) < 121.0:
                return false
    return true

func has_clear_path(a: Vector2, b: Vector2, radius: float = 5.0) -> bool:
    return WALK_SOLVER.clear_segment(a, b, can_walk.bind(radius))

func can_occupy_enemy(p: Vector2, actor: Node2D, radius: float) -> bool:
    if not can_walk(p, radius):
        return false
    var hero_distance := p.distance_to(hero.global_position)
    if hero_distance < radius + 10.0 and hero_distance <= actor.global_position.distance_to(hero.global_position):
        return false
    if actor.state == "lunge":
        var step := actor.global_position.direction_to(p)
        if step.dot(actor.attack_direction) < 0.999:
            return false
    for enemy in foes.get_children():
        if enemy != actor and enemy.active and not enemy.dead and p.distance_to(enemy.global_position) < radius + enemy.body_radius:
            return false
    return true

func _build_navigation() -> void:
    var map_size: Vector2 = $Cocito.texture.get_size()
    nav_dimensions = Vector2i((map_size / float(NAV_CELL)).ceil())
    for clearance in [21, 27]:
        var graph := AStar2D.new()
        for y in range(nav_dimensions.y):
            for x in range(nav_dimensions.x):
                var cell := Vector2i(x, y)
                var location := _nav_position(cell)
                if can_walk(location, float(clearance)):
                    graph.add_point(_nav_id(cell), location)
        for id in graph.get_point_ids():
            var cell := Vector2i(id % nav_dimensions.x, int(float(id) / nav_dimensions.x))
            for neighbor in [cell + Vector2i.RIGHT, cell + Vector2i.DOWN]:
                if not Rect2i(Vector2i.ZERO, nav_dimensions).has_point(neighbor):
                    continue
                var next_id := _nav_id(neighbor)
                if graph.has_point(next_id) and has_clear_path(graph.get_point_position(id), graph.get_point_position(next_id), float(clearance)):
                    graph.connect_points(id, next_id)
        navigation[clearance] = graph

func _nav_id(cell: Vector2i) -> int:
    return cell.y * nav_dimensions.x + cell.x

func _nav_position(cell: Vector2i) -> Vector2:
    return (Vector2(cell) + Vector2(0.5, 0.5)) * NAV_CELL

func _nearest_nav_point(graph: AStar2D, p: Vector2, radius: float) -> int:
    var home := Vector2i((p / NAV_CELL).floor())
    var bounds := Rect2i(Vector2i.ZERO, nav_dimensions)
    var best := -1
    var distance := INF
    for y in range(home.y - 3, home.y + 4):
        for x in range(home.x - 3, home.x + 4):
            var cell := Vector2i(x, y)
            var id := _nav_id(cell)
            if not bounds.has_point(cell) or not graph.has_point(id):
                continue
            var center := _nav_position(cell)
            var candidate := p.distance_squared_to(center)
            if candidate < distance and has_clear_path(p, center, radius):
                best = id
                distance = candidate
    return best

func route_to(origin: Vector2, destination: Vector2, radius: float) -> PackedVector2Array:
    var graph: AStar2D = navigation[27 if radius > 21.0 else 21]
    var start := _nearest_nav_point(graph, origin, radius)
    var finish := _nearest_nav_point(graph, destination, 5.0)
    if start < 0 or finish < 0:
        return PackedVector2Array()
    return graph.get_point_path(start, finish)

func _spawn_enemies(origin: Vector2) -> void:
    if boss_spawned or boss_defeated:
        return
    for id in ENCOUNTERS:
        if id in defeated_enemies or encountered.has(id) or origin.distance_to(ENCOUNTERS[id][1]) > 205.0:
            continue
        encountered[id] = true

        var enemy = FOE_SCENE.instantiate()
        enemy.set_script(ICE_FOE)
        enemy.spawn_id = id
        enemy.archetype = ENCOUNTERS[id][0]
        enemy.position = ENCOUNTERS[id][1]
        enemy.world = self
        enemy.hero = hero
        enemy.died.connect(_on_enemy_defeated)
        foes.add_child(enemy)

func _on_enemy_defeated(id: String) -> void:
    if id in defeated_enemies:
        return
    defeated_enemies.append(id)
    _save_state()
    _refresh_hud()
    _check_boss_spawn()

func _on_thin_ice(p: Vector2) -> bool:
    for area in thin_ice.get_children():
        var polygon: PackedVector2Array = area.get("polygon")
        if Geometry2D.is_point_in_polygon(area.to_local(p), polygon):
            return true
    return false

func movement_factor(p: Vector2) -> float:
    return 0.72 if _on_thin_ice(p) else 1.0

func can_occupy_hero(p: Vector2, _dodging: bool = false) -> bool:
    if not can_walk(p, 10.0):
        return false
    if is_instance_valid(boss) and not boss.dead and p.distance_to(boss.global_position) < boss.body_radius + 10.0:
        return false
    return true

func wind_at(_p: Vector2) -> Vector2:
    return Vector2.ZERO

func melee_hit(origin: Vector2, facing: Vector2) -> void:
    for enemy in foes.get_children():
        if enemy.dead or not enemy.active:
            continue
        var toward: Vector2 = enemy.global_position - origin
        var reach := 125.0 if enemy == boss else 77.0
        if toward.length() < reach and (toward.length() < 20.0 or toward.normalized().dot(facing) > 0.20) and has_clear_path(origin, enemy.global_position):
            enemy.take_damage(2, facing)

func spawn_projectile(start: Vector2, direction: Vector2, hostile: bool, hit_damage: int) -> void:
    var shot: Variant = PROJECTILE_SCENE.instantiate()
    shot.position = start
    shot.direction = direction.normalized()
    shot.enemy_owned = hostile
    shot.damage = hit_damage
    shot.speed = 285.0 if hostile else 620.0
    shot.world = self
    bullets.add_child(shot)

func _nearest_marker() -> Variant:
    var best: Variant
    var best_distance := 88.0
    for marker in markers.get_children():
        var distance: float = hero.global_position.distance_to(marker.global_position)
        if distance < best_distance and (marker.kind not in ["alma", "guia"] or distance <= 59.0) and _interaction_clear(marker):
            best = marker
            best_distance = distance
    return best

func _interaction_clear(marker: Node2D) -> bool:
    var origin: Vector2 = hero.global_position
    var offset: Vector2 = marker.global_position.direction_to(origin) * minf(origin.distance_to(marker.global_position), 17.0)
    return has_clear_path(origin, marker.global_position + offset, 2.0)

func _use_marker(marker: Variant) -> void:
    match str(marker.uid):
        "virgilio":
            _show_hint()
        "inscripcion":
            _dialogue("short", "INSCRIPCIÓN · LOS JURAMENTOS", "Los custodios guardan los patios. El sabueso se impulsa en línea recta y el espectro conserva distancia. El brasero central guarda tu regreso y restaura tu salud.", ["Continuar"])
        "brasero":
            _activate_brazier()
        "sello_oeste", "sello_este":
            _break_seal(marker)
        "alma_ugolino", "alma_bocca":
            _talk_soul(str(marker.uid))
        "salida":
            if boss_defeated:
                _complete_level()
            else:
                _toast("El centro sigue sellado. Rompe los juramentos y vence al guardián.")

func _activate_brazier() -> void:
    var marker: Node2D = $Marcadores/Brasero
    var rest_point := marker.global_position + Vector2.DOWN * 38.0
    if checkpoint == rest_point:
        _toast("El brasero ya guarda tu regreso.")
        return
    checkpoint = rest_point
    frost_time = 0.0
    hero.heal(hero.max_health)
    marker.set_done(true)
    _save_state()
    _toast("Brasero encendido · punto de regreso guardado.")

func _break_seal(marker: Variant) -> void:
    var uid: String = str(marker.uid)
    if uid in seals:
        _toast("Este juramento ya está roto.")
        return
    seals.append(uid)
    hero.heal(1)
    marker.set_done(true)
    _save_state()
    _refresh_hud()
    _dialogue("sello", "JURAMENTO ROTO",
        "Una grieta de luz atraviesa el hielo. %d de 2 juramentos han caído." % seals.size(),
        ["Continuar"])
    _check_boss_spawn()

func _talk_soul(uid: String) -> void:
    if decided.has(uid):
        _dialogue("short", "ECO EN EL HIELO", "Tu respuesta permanece conmigo.", ["Continuar"])
    elif uid == "alma_ugolino":
        # Los identificadores históricos del guardado se conservan para no duplicar decisiones.
        _dialogue(uid, "JUDAS ISCARIOTE · ALMA DE LA TRAICIÓN",
            "La bolsa aún pesa lo mismo. Entregué a quien confiaba en mí y después quise huir de lo que había hecho. La plata no borra el daño.",
            ["Escuchar tu arrepentimiento sin borrar la traición", "Dejar que el peso de tus actos hable por ti"])
    else:
        _dialogue(uid, "HITLER · ALMA DE LA TRAICIÓN",
            "Dante contempla al responsable de un régimen que persiguió y asesinó a millones. Aquí no hay estandartes ni discursos, solo la memoria de las víctimas y el peso de sus crímenes.",
            ["Guardar silencio por las víctimas y preservar sus nombres", "Condenar sus crímenes sin concederle otra palabra"])

func _dialogue(context: String, title: String, message: String, options: Array) -> void:
    dialogue_context = context
    game_active = false
    hero.control_enabled = false
    hud.show_dialogue(title, message, options)

func _on_dialogue_selected(choice: int) -> void:
    if dialogue_context == "death":
        frost_time = 0.0
        if is_instance_valid(boss) and not boss.dead:
            boss.reset_encounter()
        hero.restore(hero.max_health, checkpoint)
    elif dialogue_context == "intro":
        intro_seen = true
    elif dialogue_context in ["alma_ugolino", "alma_bocca"]:
        if not decided.has(dialogue_context):
            decided[dialogue_context] = choice
            Game.decide(dialogue_context, choice == 0)
            for marker in markers.get_children():
                if str(marker.uid) == dialogue_context:
                    marker.set_done(true)
            _save_state()
            _refresh_hud()
            _dialogue("short", "ECO DE COCITO", "Tu respuesta permanecerá con esta alma.", ["Continuar"])
            _check_boss_spawn()
            return
    dialogue_context = ""
    _save_state()
    _refresh_hud()
    game_active = true
    hero.control_enabled = true

func _show_hint() -> void:
    if seals.size() < 2:
        _toast("VIRGILIO: Los juramentos están en los dos patios laterales.", 5.0)
    elif decided.size() < 2:
        _toast("VIRGILIO: Escucha a Judas Iscariote y a Hitler antes de avanzar.", 5.0)
    elif defeated_enemies.size() < ENCOUNTERS.size() and not boss_spawned:
        _toast("VIRGILIO: Quedan %d guardianes del hielo." % (ENCOUNTERS.size() - defeated_enemies.size()), 5.0)
    elif not boss_defeated:
        _toast("VIRGILIO: El guardián despierta en la arena. Apártate del hielo quebrado y esquiva los proyectiles.", 5.0)
    else:
        _toast("VIRGILIO: Cruza el umbral del norte. El descenso termina aquí.", 5.0)

func _check_boss_spawn() -> void:
    if boss_spawned or boss_defeated or seals.size() < 2 or decided.size() < 2 or defeated_enemies.size() < ENCOUNTERS.size():
        return
    boss_spawned = true
    for shot in bullets.get_children():
        shot.queue_free()
    _spawn_boss()
    hero.heal(hero.max_health)
    _save_state()
    _toast("Lucifer despierta en la arena · salud restaurada antes del duelo.", 5.0)

func _spawn_boss() -> void:
    boss = BOSS_SCENE.instantiate()
    boss.position = Vector2(724, 355)
    boss.world = self
    boss.hero = hero
    boss.hp_changed.connect(hud.set_boss_health)
    boss.defeated.connect(_on_boss_defeated)
    foes.add_child(boss)
    hud.boss_text.text = "LUCIFER · GUARDIÁN DE COCITO"
    hud.set_boss_health(boss.hp, boss.max_hp)

func _on_boss_defeated() -> void:
    boss_defeated = true
    for shot in bullets.get_children():
        shot.queue_free()
    hud.hide_boss()
    $Marcadores/Salida.set_done(true)
    _save_state()
    _refresh_hud()
    _toast("El guardián cayó. El umbral del centro está abierto.", 5.0)

func _load_state() -> void:
    var data: Dictionary = Game.progress
    seals.clear()
    var saved_seals: Variant = data.get("traicion_seals", [])
    if saved_seals is Array:
        for value in saved_seals:
            var uid := str(value)
            if uid in ["sello_oeste", "sello_este"] and not uid in seals:
                seals.append(uid)
    var saved_decisions: Variant = data.get("traicion_decisions", {})
    decided = saved_decisions.duplicate(true) if saved_decisions is Dictionary else {}
    var saved_enemies: Variant = data.get("traicion_defeated_enemies", [])
    if saved_enemies is Array:
        for id in saved_enemies:
            if ENCOUNTERS.has(id) and id not in defeated_enemies:
                defeated_enemies.append(id)
    intro_seen = bool(data.get("traicion_intro_seen", false))
    boss_spawned = bool(data.get("traicion_boss_spawned", false))
    boss_defeated = bool(data.get("traicion_boss_defeated", false))
    checkpoint = Vector2(float(data.get("traicion_checkpoint_x", SPAWN.x)), float(data.get("traicion_checkpoint_y", SPAWN.y)))
    if not can_walk(checkpoint, 10.0) or (checkpoint.distance_to(Vector2(724, 355)) < 80.0 and boss_spawned):
        checkpoint = SPAWN
    $Marcadores/Brasero.set_done(checkpoint == $Marcadores/Brasero.global_position + Vector2.DOWN * 38.0)
    for marker in markers.get_children():
        var uid: String = str(marker.uid)
        if uid != "brasero":
            marker.set_done(uid in seals or uid in decided or uid == "salida" and boss_defeated)

func _save_state() -> void:
    Game.progress["circle"] = "traicion"
    Game.progress["traicion_started"] = true
    Game.progress["traicion_defeated_enemies"] = defeated_enemies.duplicate()
    Game.progress["traicion_seals"] = seals.duplicate()
    Game.progress["traicion_decisions"] = decided.duplicate(true)
    Game.progress["traicion_intro_seen"] = intro_seen
    Game.progress["traicion_boss_spawned"] = boss_spawned
    Game.progress["traicion_boss_defeated"] = boss_defeated
    Game.progress["traicion_checkpoint_x"] = checkpoint.x
    Game.progress["traicion_checkpoint_y"] = checkpoint.y
    Game.save_progress()

func _refresh_hud() -> void:
    gate_art.set("open", boss_defeated)
    hud.set_traicion_state(Game.progress, seals.size(), decided.size(), boss_defeated)
    if not boss_spawned and not boss_defeated:
        hud.gate_label.text = "○  Guardianes del hielo: %d / %d" % [defeated_enemies.size(), ENCOUNTERS.size()]
    hud.set_health(hero.health, hero.max_health)

func _on_health_changed(current: int, maximum: int) -> void:
    hud.set_health(current, maximum)

func _on_exhausted() -> void:
    var cause := "El hielo cedió bajo tus pies. Levántate, Dante, y sigue la piedra firme." if ice_break_time > 0.0 else "Lucifer te ha derribado, Dante. Deja pasar la ventisca y ataca cuando recobre el aliento." if is_instance_valid(boss) and not boss.dead else "Los guardianes de Cocito te han hecho caer, Dante. Escucha sus pasos y busca espacio para esquivar."
    game_active = false
    for shot in bullets.get_children():
        shot.queue_free()
    _save_state()
    _toast("Dante ha caído. Regresa al inicio del tramo con su progreso guardado.", 4.5)
    await get_tree().create_timer(1.1).timeout
    if not is_inside_tree():
        return
    _dialogue("death", "VIRGILIO", cause + " Volverás al punto de descanso con tu progreso guardado.", ["Volver al inicio"])

func _complete_level() -> void:
    game_active = false
    hero.control_enabled = false
    Game.progress["traicion_completed"] = true
    _save_state()
    Game.cross_threshold("res://scenes/FinTraicion.tscn")

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
