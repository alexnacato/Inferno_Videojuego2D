extends Node2D
## Circulo II: usa Dante de tamaño idéntico al Limbo y el mismo HUD, diálogos y guardado.
const INTER_SCENE: PackedScene = preload("res://scenes/LujuriaInteractivo.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/LujuriaEnemigo.tscn")
const PROJECTILE_SCENE: PackedScene = preload("res://scenes/LujuriaProyectil.tscn")
const SPAWN := Vector2(723, 977)
const SEAL_ORDER := ["sello_inicio", "sello_izquierdo", "sello_derecho"]
const COLLISION_SAMPLES = [Vector2.ZERO, Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN,
    Vector2(0.7071, 0.7071), Vector2(-0.7071, 0.7071), Vector2(0.7071, -0.7071), Vector2(-0.7071, -0.7071)]
const SPAWNS := {
    "inicio": [
        {"id": "diablillo_entrada_1", "type": "diablillo", "pos": Vector2(634, 851)},
        {"id": "diablillo_entrada_2", "type": "diablillo", "pos": Vector2(814, 844)},
    ],
    "izquierda": [
        {"id": "diablillo_izq", "type": "diablillo", "pos": Vector2(287, 495)},
        {"id": "espectro_izq", "type": "espectro", "pos": Vector2(478, 495)},
    ],
    "derecha": [
        {"id": "carcelero_derecha", "type": "carcelero", "pos": Vector2(1153, 492)},
        {"id": "espectro_derecha", "type": "espectro", "pos": Vector2(985, 495)},
    ],
    "patio": [
        {"id": "furia_patio", "type": "furia", "pos": Vector2(518, 340)},
        {"id": "diablillo_patio", "type": "diablillo", "pos": Vector2(901, 348)},
    ],
}


@onready var hero: Variant = $Dante
@onready var hud: Variant = $HUD
@onready var markers: Node2D = $Interactivos
@onready var foes: Node2D = $Enemigos
@onready var bullets: Node2D = $Proyectiles
@onready var fx: Variant = $EfectosViento

var game_active: bool = false
var paused: bool = false
var seals: Array[String] = []
var decided: Dictionary = {}
var triggered: Dictionary = {}
var defeated: Dictionary = {}
var boss_spawned: bool = false
var boss_defeated: bool = false
var intro_seen: bool = false
var checkpoint: Vector2 = SPAWN
var wind_clock: float = 0.0
var pulse_at: Vector2 = Vector2.ZERO
var pulse_left: float = 0.0
var dialogue_context: String = ""
var enemy_boss: Variant
var effect: AudioStreamPlayer
var navigation_grids: Dictionary = {}
const NAV_CELL: int = 24
var left_ramp: PackedVector2Array = PackedVector2Array([
    Vector2(520, 595), Vector2(630, 600), Vector2(625, 675),
    Vector2(575, 735), Vector2(485, 760), Vector2(455, 725), Vector2(505, 655)
])
var right_ramp: PackedVector2Array = PackedVector2Array([
    Vector2(820, 600), Vector2(930, 595), Vector2(945, 655),
    Vector2(995, 725), Vector2(965, 760), Vector2(875, 735), Vector2(825, 675)
])
var upper_court: PackedVector2Array = PackedVector2Array([
    Vector2(480, 275), Vector2(965, 275), Vector2(965, 390),
    Vector2(920, 410), Vector2(525, 410), Vector2(480, 390)
])
var left_side_floor: PackedVector2Array = PackedVector2Array([
    Vector2(125, 458), Vector2(325, 450), Vector2(460, 475),
    Vector2(455, 535), Vector2(410, 560), Vector2(395, 610),
    Vector2(343, 665), Vector2(290, 692), Vector2(235, 678),
    Vector2(172, 620), Vector2(126, 555)
])
var right_side_floor: PackedVector2Array = PackedVector2Array([
    Vector2(1323, 458), Vector2(1123, 450), Vector2(988, 475),
    Vector2(993, 535), Vector2(1038, 560), Vector2(1053, 610),
    Vector2(1105, 665), Vector2(1158, 692), Vector2(1213, 678),
    Vector2(1276, 620), Vector2(1322, 555)
])

var gate_art: Node2D
var npc_positions := PackedVector2Array()

func _ready() -> void:
    preload("res://scripts/foreground.gd").install($MapaPintado, hero, PackedVector2Array([Vector2(232,226),Vector2(242,186),Vector2(264,162),Vector2(280,155),Vector2(299,161),Vector2(315,183),Vector2(329,226),Vector2(317,242),Vector2(247,242)]), 240.0)
    gate_art = preload("res://scripts/gate_visual.gd").install(self, Rect2(670, 43, 107, 115), Color("e3afff"))
    Game.enter_lujuria()
    hero.world = self
    hero.health_changed.connect(_on_hero_health_changed)
    hero.exhausted.connect(_on_hero_exhausted)
    hud.configure_chapter("lujuria", hero)
    hud.option_selected.connect(_answer_dialogue)
    hud.pause_requested.connect(_toggle_pause)
    hud.exit_to_menu_requested.connect(_back_to_menu)
    fx.world_ref = self
    gate_art.z_index = 1
    _make_interactives()
    for marker in markers.get_children():
        if str(marker.kind) in ["paolo", "francesca", "virgilio"]:
            npc_positions.append(marker.global_position)
    _build_navigation()
    _load_state()
    hero.restore(hero.max_health, checkpoint)
    hero.control_enabled = true
    _restore_enemies()
    _start_audio()
    _refresh_hud()
    game_active = true
    if not intro_seen:
        _open_dialogue("intro", "VIRGILIO · GUÍA DE DANTE", "Abandonamos el silencio del Limbo. Aquí las almas son arrastradas por una tempestad sin descanso. Los vientos alteran tu camino y el juez Minos guarda el umbral. Escucha a Paolo y Francesca: su dolor también exige una elección.", ["Descender al segundo círculo"])
    else:
        _toast("Continuamos el descenso. Las decisiones del Limbo permanecen.")

func _start_audio() -> void:
    effect = AudioStreamPlayer.new()
    effect.bus = "SFX"
    effect.stream = load("res://assets/lujuria/audio/sello.wav")
    effect.volume_db = -12.0
    add_child(effect)

func _exit_tree() -> void:
    if is_instance_valid(effect):
        effect.stop()

func _play_fx() -> void:
    if effect.stream != null:
        effect.play()

func _make_interactives() -> void:
    _add_marker("virgilio", "virgilio", "HABLAR CON VIRGILIO", Vector2(858, 877))
    _add_marker("paolo", "paolo", "ESCUCHAR A PAOLO", Vector2(293, 575))
    _add_marker("francesca", "francesca", "ESCUCHAR A FRANCESCA", Vector2(1153, 575))
    _add_marker("sello_inicio", "sello", "SELLO DE LA MEMORIA", Vector2(722, 689))
    _add_marker("sello_izquierdo", "sello", "SELLO DEL ALIENTO", Vector2(387, 422))
    _add_marker("sello_derecho", "sello", "SELLO DEL JUICIO", Vector2(1052, 420))
    _add_marker("puerta", "puerta", "UMBRAL HACIA LA GULA", Vector2(720, 179))

func _add_marker(uid: String, kind: String, caption: String, where: Vector2) -> void:
    var marker: Variant = INTER_SCENE.instantiate()
    marker.name = uid
    marker.uid = uid
    marker.kind = kind
    marker.caption = caption
    marker.position = where
    markers.add_child(marker)

func _load_state() -> void:
    var data: Dictionary = Game.progress
    seals.clear()
    var old_seals: Variant = data.get("lujuria_seals", [])
    if old_seals is Array:
        for value in old_seals:
            var sid: String = str(value)
            if sid in SEAL_ORDER and not sid in seals and SEAL_ORDER.find(sid) == seals.size():
                seals.append(sid)
    var raw_decisions: Variant = data.get("lujuria_decisions", {})
    decided = raw_decisions.duplicate(true) if raw_decisions is Dictionary else {}
    var raw_triggered: Variant = data.get("lujuria_triggered", {})
    triggered = raw_triggered.duplicate(true) if raw_triggered is Dictionary else {}
    var raw_defeated: Variant = data.get("lujuria_defeated", {})
    defeated = raw_defeated.duplicate(true) if raw_defeated is Dictionary else {}
    intro_seen = bool(data.get("lujuria_intro_seen", false))
    boss_spawned = bool(data.get("lujuria_boss_spawned", false))
    boss_defeated = bool(data.get("lujuria_boss_defeated", false))
    checkpoint = Vector2(float(data.get("lujuria_checkpoint_x", SPAWN.x)), float(data.get("lujuria_checkpoint_y", SPAWN.y)))
    if not can_walk(checkpoint, 10.0):
        checkpoint = Vector2(544, 390) if seals.size() >= 3 else Vector2(720, 790) if seals.size() > 0 else SPAWN
    for marker in markers.get_children():
        marker.call("set_done", str(marker.get("uid")) in seals or str(marker.get("uid")) in decided or str(marker.get("uid")) == "puerta" and boss_defeated)

func _save_state() -> void:
    Game.progress["circle"] = "lujuria"
    Game.progress["lujuria_started"] = true
    Game.progress["lujuria_seals"] = seals.duplicate()
    Game.progress["lujuria_decisions"] = decided.duplicate(true)
    Game.progress["lujuria_triggered"] = triggered.duplicate(true)
    Game.progress["lujuria_defeated"] = defeated.duplicate(true)
    Game.progress["lujuria_boss_spawned"] = boss_spawned
    Game.progress["lujuria_boss_defeated"] = boss_defeated
    Game.progress["lujuria_intro_seen"] = intro_seen
    Game.progress["lujuria_checkpoint_x"] = checkpoint.x
    Game.progress["lujuria_checkpoint_y"] = checkpoint.y
    Game.save_progress()

func _restore_enemies() -> void:
    for wave_id in triggered.keys():
        if not SPAWNS.has(wave_id):
            continue
        for spec in SPAWNS[wave_id]:
            if not defeated.has(spec["id"]):
                _spawn_enemy(str(spec["type"]), str(spec["id"]), spec["pos"])
    if boss_spawned and not boss_defeated:
        enemy_boss = _spawn_enemy("minos", "guardian_minos", Vector2(716, 317))
        hud.set_boss_health(enemy_boss.hp, enemy_boss.max_hp)

func _process(delta: float) -> void:
    wind_clock += delta
    pulse_left = maxf(0.0, pulse_left - delta)
    hud.set_dash_fraction(1.0 - clampf(hero.dash_recharge / hero.dash_cooldown_duration, 0.0, 1.0))
    if not game_active or paused or hud.dialogue_open:
        hud.set_nearby("")
        return
    var nearby: Variant = _nearest_interactive()
    for marker in markers.get_children():
        marker.set("near", marker == nearby)
    hud.set_nearby(str(nearby.caption) if nearby != null else "")
    if Input.is_action_just_pressed("interact") and nearby != null:
        _use_marker(nearby)
    if Input.is_action_just_pressed("hint"):
        _show_hint()
    _trigger_encounters()
    _check_boss_spawn()

func _nearest_interactive() -> Variant:
    var closest: Variant
    var best: float = 95.0
    for marker in markers.get_children():
        var dist: float = hero.global_position.distance_to(marker.global_position)
        if dist < best:
            closest = marker
            best = dist
    return closest

func _use_marker(marker: Variant) -> void:
    match str(marker.uid):
        "virgilio":
            _show_hint()
        "paolo", "francesca":
            _soul_dialogue(str(marker.uid))
        "sello_inicio", "sello_izquierdo", "sello_derecho":
            _activate_seal(marker)
        "puerta":
            if boss_defeated:
                _complete_level()
            else:
                _toast("La puerta permanece sellada por Minos. Despierta los sellos y escucha las almas.", 5.0)

func _soul_dialogue(uid: String) -> void:
    if decided.has(uid):
        _open_dialogue("short", uid.to_upper(), "Tu decisión ya forma parte de nuestro destino. El viento seguirá soplando.", ["Continuar"])
    elif uid == "paolo":
        _open_dialogue("paolo", "PAOLO · ALMA DE LA LUJURIA",
            "Leíamos la historia de Lanzarote cuando mi hermano nos mató. Amé a su esposa y morí por ese beso, y el viento nos arrastra juntos sin dejarme pensar. Tu palabra define mi tormento: ¿puedo cargar la culpa sabiendo que ella me amó, o merezco que el viento se vuelva más cruel?",
            ["Aliviar su culpa: el amor los venció a los dos",
             "Recordarle que la pasión no disculpa la traición"])
    else:
        _open_dialogue("francesca", "FRANCESCA · ALMA DE LA LUJURIA",
            "Sigo leyendo el mismo libro que leíamos la noche en que morimos. Sabía lo que hacía y no dejé de leer: elegí cada página. Dime algo que yo no sepa: ¿aún se puede aprender después de caer, o mi historia ya se terminó de escribir?",
            ["Decirle que aprender aún puede redimirla",
             "Decirle que su caída ya escribió el final"])

func _activate_seal(marker: Variant) -> void:
    var uid: String = str(marker.uid)
    if uid in seals:
        _toast("Este sello ya ha sido activado.")
        return
    if seals.size() >= 3 or uid != SEAL_ORDER[seals.size()]:
        _toast("El viento marca el orden: Memoria → Aliento → Juicio.", 5.0)
        return
    if _hostiles_near(marker.global_position, 140.0):
        _toast("La presencia de demonios impide activar el sello.")
        return
    seals.append(uid)
    marker.set_done(true)
    checkpoint = Vector2(720, 790) if seals.size() == 1 else Vector2(544, 390) if seals.size() == 3 else checkpoint
    _play_fx()
    _save_state()
    _refresh_hud()
    _open_dialogue("seal", "SELLO DE LA TEMPESTAD", "El sello responde y el vendaval pierde fuerza. Has activado %d de los 3 sellos." % seals.size(), ["Continuar"])

func _show_hint() -> void:
    var message: String = ""
    if seals.size() < 3:
        var names: Array[String] = ["Memoria", "Aliento", "Juicio"]
        message = "Busca el sello de " + names[seals.size()] + ". Recuerda el orden de los vientos."
    elif decided.size() < 2:
        message = "Escucha a Paolo y Francesca y decide qué decirles."
    elif not boss_defeated:
        message = "Minos espera en la plataforma superior. Supera a sus demonios y esquiva las ráfagas."
    else:
        message = "El umbral ya no está custodiado. Dirígete a la puerta del norte."
    _open_dialogue("short", "VIRGILIO · CONSEJO", message, ["Comprendido"])

func _open_dialogue(context: String, speaker: String, message: String, choices: Array) -> void:
    dialogue_context = context
    game_active = false
    hero.control_enabled = false
    hud.show_dialogue(speaker, message, choices)

func _answer_dialogue(choice: int) -> void:
    if dialogue_context == "death":
        if is_instance_valid(enemy_boss) and not enemy_boss.dead:
            enemy_boss.reset_encounter()
        hero.restore(hero.max_health, SPAWN)
    elif dialogue_context == "intro":
        intro_seen = true
    elif dialogue_context == "paolo" or dialogue_context == "francesca":
        if not decided.has(dialogue_context):
            decided[dialogue_context] = choice
            Game.decide("alma_" + dialogue_context, choice == 0)
            _play_fx()
            for marker in markers.get_children():
                if str(marker.get("uid")) == dialogue_context:
                    marker.call("set_done", true)
            _save_state()
            _refresh_hud()
            if dialogue_context == "paolo":
                _open_dialogue("paolo_r", "PAOLO · ALMA DE LA LUJURIA",
                    "Si tú, que vienes de juzgar a otros, me comprendes… quizá el viento pueda volverse un poco más leve. Que esta tregua sea tuya, no mía." if choice == 0
                    else "Traicioné, es verdad. Que cada ráfaga me lo recuerde sin piedad. Tu palabra pesa como el plomo de mi hermano.",
                    ["Seguir tu camino"])
            else:
                _open_dialogue("francesca_r", "FRANCESCA · ALMA DE LA LUJURIA",
                    "Entonces el libro aún no terminó: faltan páginas que yo escriba. Te agradezco no ver en mí solo la mujer que cayó, sino la que siguió leyendo." if choice == 0
                    else "Vienes a decirme lo que el viento repite cada noche. Lo acepto: la caída también es un final. Tu juicio llega tarde, pero llega claro.",
                    ["Seguir tu camino"])
            return
    dialogue_context = ""
    hud.set_nearby("")
    _save_state()
    _refresh_hud()
    game_active = true
    hero.control_enabled = true

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

func _toast(message: String, duration: float = 3.6) -> void:
    hud.toast(message, duration)

## Mensajes de combate que llegan desde los enemigos (lujuria_enemigo.gd).
func notify(message: String, duration: float = 4.0) -> void:
    if not game_active:
        return
    _toast(message, duration)

func _refresh_hud() -> void:
    gate_art.set("open", boss_defeated)
    hud.set_lujuria_state(Game.progress, seals.size(), decided.size(), boss_defeated)
    hud.set_health(hero.health, hero.max_health)

func _on_hero_health_changed(current: int, maximum: int) -> void:
    hud.set_health(current, maximum)

func _on_hero_exhausted() -> void:
    game_active = false
    for shot in bullets.get_children():
        shot.queue_free()
    _save_state()
    _toast("Dante ha caído. Regresa al inicio del círculo con su progreso guardado.", 4.5)
    await get_tree().create_timer(1.2).timeout
    if not is_inside_tree():
        return
    _open_dialogue("death", "VIRGILIO · LEVÁNTATE", "Dante regresará al inicio del círculo con su progreso guardado.", ["Volver al inicio"])

func _complete_level() -> void:
    game_active = false
    hero.control_enabled = false
    Game.progress["lujuria_completed"] = true
    _save_state()
    _play_fx()
    Game.cross_threshold("res://scenes/FinLujuria.tscn")

func _trigger_encounters() -> void:
    var p: Vector2 = hero.global_position
    if not triggered.has("inicio") and p.y < 932.0:
        _spawn_wave("inicio")
    if not triggered.has("izquierda") and p.x < 480.0 and p.y > 397.0 and p.y < 590.0:
        _spawn_wave("izquierda")
    if not triggered.has("derecha") and p.x > 975.0 and p.y > 397.0 and p.y < 590.0:
        _spawn_wave("derecha")
    if seals.size() >= 2 and not triggered.has("patio") and p.y < 393.0 and p.x > 465.0 and p.x < 965.0:
        _spawn_wave("patio")

func _spawn_wave(key: String) -> void:
    if triggered.has(key):
        return
    triggered[key] = true
    for spec in SPAWNS[key]:
        if defeated.has(spec["id"]):
            continue
        _spawn_enemy(str(spec["type"]), str(spec["id"]), spec["pos"])
    if key == "patio":
        _toast("Una furia protege la antesala de Minos.")
    else:
        _toast("La tempestad ha convocado criaturas infernales.")
    _save_state()

func _spawn_enemy(kind: String, uid: String, spawn_at: Vector2):
    var enemy = ENEMY_SCENE.instantiate()
    enemy.archetype = kind
    enemy.spawn_id = uid
    enemy.world = self
    enemy.hero = hero
    enemy.active = true
    enemy.position = spawn_at
    enemy.died.connect(_on_enemy_died)
    if kind == "minos":
        enemy.hp_changed.connect(func(value: int, maximum: int): hud.set_boss_health(value, maximum))
    foes.add_child(enemy)
    if not can_occupy_enemy(enemy.global_position, enemy, enemy.body_radius):
        for distance in [64.0, 104.0, 144.0]:
            var relocated: bool = false
            for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN,
                    Vector2(-0.7071, -0.7071), Vector2(0.7071, -0.7071),
                    Vector2(-0.7071, 0.7071), Vector2(0.7071, 0.7071)]:
                var candidate: Vector2 = spawn_at + direction * distance
                if can_occupy_enemy(candidate, enemy, enemy.body_radius):
                    enemy.global_position = candidate
                    enemy.anchor = candidate
                    relocated = true
                    break
            if relocated:
                break
    return enemy

func _on_enemy_died(uid: String, kind: String) -> void:
    defeated[uid] = true
    _play_fx()
    if kind == "minos":
        boss_defeated = true
        enemy_boss = null
        hud.hide_boss()
        _toast("Minos cae. El umbral hacia el tercer círculo ha sido liberado.")
        for m in markers.get_children():
            if str(m.get("uid")) == "puerta":
                m.call("set_done", true)
    else:
        _toast("Enemigo vencido: %s" % kind.capitalize())
    _refresh_hud()
    _save_state()

func _hostiles_near(where: Vector2, radius: float) -> bool:
    for e in foes.get_children():
        if not e.dead and e.active and e.position.distance_to(where) < radius:
            return true
    return false


func _check_boss_spawn() -> void:
    if boss_spawned or boss_defeated:
        return
    if seals.size() != 3 or decided.size() != 2:
        return
    if not triggered.has("patio"):
        return
    if _hostiles_near(Vector2(715, 343), 750.0):
        return
    boss_spawned = true
    enemy_boss = _spawn_enemy("minos", "guardian_minos", Vector2(716, 317))
    hud.set_boss_health(enemy_boss.hp, enemy_boss.max_hp)
    _toast("¡MINOS! El juez infernal cierra el paso a la Gula.")
    _save_state()

func melee_hit(origin: Vector2, facing: Vector2) -> void:
    for enemy in foes.get_children():
        if enemy.dead or not enemy.active:
            continue
        var vector: Vector2 = enemy.global_position - origin
        if vector.length() <= (100.0 if enemy.archetype == "minos" else 72.0) and vector.normalized().dot(facing) > 0.25 and has_clear_path(origin, enemy.global_position, 5.0):
            enemy.take_damage(2, facing)
    _play_fx()

func spawn_projectile(start: Vector2, direction: Vector2, hostile: bool, hit_damage: int) -> void:
    var shot = PROJECTILE_SCENE.instantiate()
    shot.position = start
    shot.direction = direction.normalized()
    shot.enemy_owned = hostile
    shot.damage = hit_damage
    shot.speed = 258.0 if hostile else 620.0
    shot.world = self
    bullets.add_child(shot)

func pulse_wind(origin: Vector2, _strength: float) -> void:
    pulse_at = origin
    pulse_left = 0.60
    _toast("¡Ráfaga infernal!")

func wind_at(p: Vector2) -> Vector2:
    var wind := Vector2.ZERO
    var t := wind_clock
    if Rect2(130, 420, 425, 145).has_point(p):
        var intensity := 116.0 if not "sello_izquierdo" in seals else 42.0
        wind = Vector2(0.97, 0.22).normalized() * intensity * (0.78 + 0.22 * sin(t * 1.35))
    elif Rect2(880, 420, 450, 145).has_point(p):
        var intensity := 126.0 if not "sello_derecho" in seals else 43.0
        wind = Vector2(-0.95, 0.31).normalized() * intensity * (0.78 + 0.22 * sin(t * 1.50))
    elif Rect2(540, 277, 380, 118).has_point(p):
        wind = Vector2(0.42, -0.90) * (45.0 if seals.size() < 3 else 19.0)
    if pulse_left > 0.0:
        var away: Vector2 = p - pulse_at
        if away.length() < 285.0 and away.length() > 5.0:
            wind += away.normalized() * 165.0 * pulse_left
    return wind

func can_walk(p: Vector2, radius: float = 8.0) -> bool:
    # Hand-authored traversal geometry built over the user's illustrated 2D map.
    # Tested with a graph reachability scan; excludes abyss, walls, and the center statue.
    for offset in COLLISION_SAMPLES:
        var sample: Vector2 = p + offset * radius
        if not _is_ground(sample):
            return false
        for npc_position in npc_positions:
            if _in_ellipse(sample, npc_position, 17.0, 11.0):
                return false
    return true

func can_occupy_hero(p: Vector2, _dodging: bool = false) -> bool:
    if not can_walk(p, 10.0):
        return false
    # Los enemigos aplican daño por contacto, pero no forman muros móviles que
    # atrapen al jugador entre ellos y el borde de la plataforma.
    return true

func can_occupy_enemy(p: Vector2, moving_enemy: Node2D, radius: float) -> bool:
    if not can_walk(p, radius):
        return false
    if moving_enemy.archetype == "minos" and not Geometry2D.is_point_in_polygon(p, upper_court):
        return false
    if p.distance_to(hero.global_position) < radius + 10.0:
        return false
    for enemy in foes.get_children():
        if enemy != moving_enemy and not enemy.dead and p.distance_to(enemy.global_position) < radius + enemy.body_radius:
            return false
    return true

func has_clear_path(a: Vector2, b: Vector2, radius: float = 4.0) -> bool:
    var distance: float = a.distance_to(b)
    var steps: int = maxi(1, ceili(distance / 8.0))
    for i in range(1, steps):
        if not can_walk(a.lerp(b, float(i) / float(steps)), radius):
            return false
    return true

func _build_navigation() -> void:
    # Three clearance maps keep large enemies away from narrow painted ledges.
    for clearance in [14, 24, 36]:
        var grid: AStarGrid2D = AStarGrid2D.new()
        grid.region = Rect2i(0, 0, 61, 46)
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
    var clearance: int = 36 if radius > 25.0 else 24 if radius > 18.0 else 14
    var grid: AStarGrid2D = navigation_grids[clearance]
    var start: Vector2i = _nearest_nav_cell(grid, from)
    var finish: Vector2i = _nearest_nav_cell(grid, destination)
    if start.x < 0 or finish.x < 0:
        return PackedVector2Array()
    var ids: Array[Vector2i] = grid.get_id_path(start, finish)
    var result: PackedVector2Array = PackedVector2Array()
    for id in ids:
        result.append(Vector2(id.x + 0.5, id.y + 0.5) * float(NAV_CELL))
    return result

func _nearest_nav_cell(grid: AStarGrid2D, p: Vector2) -> Vector2i:
    var base: Vector2i = Vector2i(floori(p.x / NAV_CELL), floori(p.y / NAV_CELL))
    for ring in range(0, 5):
        for x in range(base.x - ring, base.x + ring + 1):
            for y in range(base.y - ring, base.y + ring + 1):
                var cell: Vector2i = Vector2i(x, y)
                if grid.is_in_boundsv(cell) and not grid.is_point_solid(cell):
                    return cell
    return Vector2i(-1, -1)

func _in_ellipse(p: Vector2, c: Vector2, rx: float, ry: float) -> bool:
    var d: Vector2 = p - c
    return d.x * d.x / (rx * rx) + d.y * d.y / (ry * ry) <= 1.0

func _is_ground(p: Vector2) -> bool:
    if p.x < 104.0 or p.x > 1342.0 or p.y < 155.0 or p.y > 1070.0:
        return false
    var ground := false
    # Floor shapes follow the visible stone: entrance, lower court and two curved ramps.
    ground = ground or Rect2(650, 930, 145, 156).has_point(p)
    ground = ground or _in_ellipse(p, Vector2(720, 825), 340.0, 138.0)
    ground = ground or Geometry2D.is_point_in_polygon(p, left_ramp)
    ground = ground or Geometry2D.is_point_in_polygon(p, right_ramp)
    # Ring around the statue and the two side paths to the souls.
    ground = ground or _in_ellipse(p, Vector2(725, 535), 235.0, 150.0)
    ground = ground or Geometry2D.is_point_in_polygon(p, left_side_floor)
    ground = ground or Geometry2D.is_point_in_polygon(p, right_side_floor)
    ground = ground or Rect2(150, 455, 400, 85).has_point(p)
    ground = ground or Rect2(900, 455, 400, 85).has_point(p)
    # Upper court, side approaches and the doorway terrace.
    ground = ground or Geometry2D.is_point_in_polygon(p, upper_court)
    ground = ground or Rect2(540, 380, 110, 85).has_point(p)
    ground = ground or Rect2(800, 380, 110, 85).has_point(p)
    ground = ground or Rect2(455, 175, 535, 50).has_point(p)
    ground = ground or Rect2(575, 215, 290, 75).has_point(p)
    if _in_ellipse(p, Vector2(727, 556), 125.0, 66.0):
        return false
    # Openings beneath the soul balconies are chasms, despite the painted wind.
    if _in_ellipse(p, Vector2(347, 616), 118.0, 72.0) or _in_ellipse(p, Vector2(1101, 616), 118.0, 72.0):
        return false
    # The arch below the statue is a wall, between the two ramps.
    if Rect2(654, 670, 146, 85).has_point(p):
        return false
    return ground


