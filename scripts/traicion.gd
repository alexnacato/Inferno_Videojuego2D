extends Node2D

## Círculo IX: Cocito, juramentos rotos y el guardián del hielo.
const BOSS_SCENE: PackedScene = preload("res://scenes/TraicionLucifer.tscn")
const PROJECTILE_SCENE: PackedScene = preload("res://scenes/LujuriaProyectil.tscn")
const SPAWN := Vector2(724, 1000)
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

func _ready() -> void:
    Game.enter_traicion()
    hero.world = self
    hero.health_changed.connect(_on_health_changed)
    hero.exhausted.connect(_on_exhausted)
    hud.configure_chapter("traicion", hero)
    hud.option_selected.connect(_on_dialogue_selected)
    hud.pause_requested.connect(_toggle_pause)
    hud.exit_to_menu_requested.connect(_back_to_menu)
    _load_state()
    hero.restore(hero.max_health, checkpoint)
    hero.control_enabled = true
    if boss_spawned and not boss_defeated:
        _spawn_boss()
    _refresh_hud()
    game_active = true
    if not intro_seen:
        _dialogue("intro", "VIRGILIO · COCITO",
            "Aquí el castigo no arde: congela. Dos juramentos mantienen preso el paso hacia el centro. Rompe sus sellos, escucha a las almas y enfrenta a quien yace bajo el hielo.",
            ["Entrar en Traición"])

func _process(delta: float) -> void:
    queue_redraw()
    hud.set_dash_fraction(1.0 - clampf(hero.dash_recharge / hero.dash_cooldown_duration, 0.0, 1.0))
    if not game_active or paused or hud.dialogue_open:
        hud.set_nearby("")
        return
    var nearby: Variant = _nearest_marker()
    for marker in markers.get_children():
        marker.set("near", marker == nearby)
    hud.set_nearby(str(nearby.caption) if nearby != null else "")
    if Input.is_action_just_pressed("interact") and nearby != null:
        _use_marker(nearby)
    if Input.is_action_just_pressed("hint"):
        _show_hint()
    if _on_thin_ice(hero.global_position) and hero.dash_time <= 0.0:
        frost_time += delta
        if frost_time >= 2.2:
            frost_time = 0.0
            hero.take_damage(1)
            _toast("El hielo se quiebra bajo tus pies. Muévete o esquiva.", 2.5)
    else:
        frost_time = maxf(0.0, frost_time - delta * 2.0)

func _draw() -> void:
    for area in thin_ice.get_children():
        var polygon: PackedVector2Array = area.get("polygon")
        draw_colored_polygon(polygon, Color(0.35, 0.84, 1.0, 0.12))
        for i in range(polygon.size()):
            draw_line(polygon[i], polygon[(i + 1) % polygon.size()], Color(0.65, 0.93, 1.0, 0.48), 2.0)

func can_walk(p: Vector2, radius: float = 10.0) -> bool:
    for offset in SAMPLES:
        var sample: Vector2 = p + offset * radius
        var found := false
        for area in floors.get_children():
            var polygon: PackedVector2Array = area.get("polygon")
            if Geometry2D.is_point_in_polygon(sample, polygon):
                found = true
                break
        if not found:
            return false
    return true

func _on_thin_ice(p: Vector2) -> bool:
    for area in thin_ice.get_children():
        var polygon: PackedVector2Array = area.get("polygon")
        if Geometry2D.is_point_in_polygon(p, polygon):
            return true
    return false

func movement_factor(p: Vector2) -> float:
    return 0.72 if _on_thin_ice(p) else 0.92

func can_occupy_hero(p: Vector2, _dodging: bool = false) -> bool:
    if not can_walk(p, 10.0):
        return false
    if is_instance_valid(boss) and not boss.dead and p.distance_to(boss.global_position) < 63.0:
        return false
    return true

func wind_at(_p: Vector2) -> Vector2:
    return Vector2.ZERO

func melee_hit(origin: Vector2, facing: Vector2) -> void:
    if not is_instance_valid(boss) or boss.dead or not boss.active:
        return
    var toward: Vector2 = boss.global_position - origin
    if toward.length() < 125.0 and toward.normalized().dot(facing) > 0.15:
        boss.take_damage(2, facing)

func spawn_projectile(start: Vector2, direction: Vector2, hostile: bool, hit_damage: int) -> void:
    var shot: Variant = PROJECTILE_SCENE.instantiate()
    shot.position = start
    shot.direction = direction.normalized()
    shot.enemy_owned = hostile
    shot.damage = hit_damage
    shot.speed = 230.0 if hostile else 355.0
    shot.world = self
    bullets.add_child(shot)

func _nearest_marker() -> Variant:
    var best: Variant
    var best_distance := 88.0
    for marker in markers.get_children():
        var distance: float = hero.global_position.distance_to(marker.global_position)
        if distance < best_distance:
            best = marker
            best_distance = distance
    return best

func _use_marker(marker: Variant) -> void:
    match str(marker.uid):
        "virgilio":
            _show_hint()
        "sello_oeste", "sello_este":
            _break_seal(marker)
        "alma_ugolino", "alma_bocca":
            _talk_soul(str(marker.uid))
        "salida":
            if boss_defeated:
                _complete_level()
            else:
                _toast("El centro sigue sellado. Rompe los juramentos y vence al guardián.")

func _break_seal(marker: Variant) -> void:
    var uid: String = str(marker.uid)
    if uid in seals:
        _toast("Este juramento ya está roto.")
        return
    seals.append(uid)
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
        _dialogue(uid, "UGOLINO · ALMA DE LA TRAICIÓN",
            "Fui prisionero de una alianza rota. El hambre me arrebató hasta el nombre. ¿Me recordarás como hombre, pese a mis faltas?",
            ["Reconocer su dolor · Redención", "Recordar también sus culpas · Rigor"])
    else:
        _dialogue(uid, "BOCCA · ALMA DE LA TRAICIÓN",
            "Entregué a quienes confiaron en mí para salvarme. Sus voces quedaron bajo este hielo. ¿Puedo confesar la verdad ahora?",
            ["Escuchar su confesión · Redención", "Exigirle que asuma el daño · Rigor"])

func _dialogue(context: String, title: String, message: String, options: Array) -> void:
    dialogue_context = context
    game_active = false
    hero.control_enabled = false
    hud.show_dialogue(title, message, options)

func _on_dialogue_selected(choice: int) -> void:
    if dialogue_context == "intro":
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
            _dialogue("short", "ECO DE COCITO", "Tu decisión se suma a tu camino de Redención o Rigor.", ["Continuar"])
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
        _toast("VIRGILIO: Escucha a Ugolino y a Bocca antes de avanzar.", 5.0)
    elif not boss_defeated:
        _toast("VIRGILIO: El guardián despierta en la arena. Observa los avisos azules y esquiva.", 5.0)
    else:
        _toast("VIRGILIO: Cruza el umbral del norte. El descenso termina aquí.", 5.0)

func _check_boss_spawn() -> void:
    if boss_spawned or boss_defeated or seals.size() < 2 or decided.size() < 2:
        return
    boss_spawned = true
    _spawn_boss()
    _save_state()
    _toast("El hielo se parte: Lucifer despierta en la arena central.", 5.0)

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
    intro_seen = bool(data.get("traicion_intro_seen", false))
    boss_spawned = bool(data.get("traicion_boss_spawned", false))
    boss_defeated = bool(data.get("traicion_boss_defeated", false))
    checkpoint = Vector2(float(data.get("traicion_checkpoint_x", SPAWN.x)), float(data.get("traicion_checkpoint_y", SPAWN.y)))
    if not can_walk(checkpoint, 10.0):
        checkpoint = SPAWN
    for marker in markers.get_children():
        var uid: String = str(marker.uid)
        marker.set_done(uid in seals or uid in decided or uid == "salida" and boss_defeated)

func _save_state() -> void:
    Game.progress["circle"] = "traicion"
    Game.progress["traicion_started"] = true
    Game.progress["traicion_seals"] = seals.duplicate()
    Game.progress["traicion_decisions"] = decided.duplicate(true)
    Game.progress["traicion_intro_seen"] = intro_seen
    Game.progress["traicion_boss_spawned"] = boss_spawned
    Game.progress["traicion_boss_defeated"] = boss_defeated
    Game.progress["traicion_checkpoint_x"] = checkpoint.x
    Game.progress["traicion_checkpoint_y"] = checkpoint.y
    Game.save_progress()

func _refresh_hud() -> void:
    hud.set_traicion_state(Game.progress, seals.size(), decided.size(), boss_defeated)
    hud.set_health(hero.health, hero.max_health)

func _on_health_changed(current: int, maximum: int) -> void:
    hud.set_health(current, maximum)

func _on_exhausted() -> void:
    game_active = false
    _toast("Dante cae sobre el hielo y regresa a la entrada...")
    await get_tree().create_timer(1.1).timeout
    if not is_inside_tree():
        return
    hero.restore(hero.max_health, checkpoint)
    hero.control_enabled = true
    game_active = true

func _complete_level() -> void:
    game_active = false
    hero.control_enabled = false
    Game.progress["traicion_completed"] = true
    _save_state()
    get_tree().change_scene_to_file("res://scenes/FinTraicion.tscn")

func _toggle_pause() -> void:
    if hud.dialogue_open:
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
