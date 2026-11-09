extends Node2D
## Circulo II: usa Dante de tamaño idéntico al Limbo y el mismo HUD, diálogos y guardado.
const INTER_SCENE: PackedScene = preload("res://scenes/LujuriaInteractivo.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/LujuriaEnemigo.tscn")
const PROJECTILE_SCENE: PackedScene = preload("res://scenes/LujuriaProyectil.tscn")
const SPAWN := Vector2(723, 977)
const SEAL_ORDER := ["sello_inicio", "sello_izquierdo", "sello_derecho"]
const SPAWNS := {
    "inicio": [
        {"id": "diablillo_entrada_1", "type": "diablillo", "pos": Vector2(634, 851)},
        {"id": "diablillo_entrada_2", "type": "diablillo", "pos": Vector2(837, 844)},
    ],
    "izquierda": [
        {"id": "diablillo_izq", "type": "diablillo", "pos": Vector2(287, 495)},
        {"id": "espectro_izq", "type": "espectro", "pos": Vector2(478, 462)},
    ],
    "derecha": [
        {"id": "carcelero_derecha", "type": "carcelero", "pos": Vector2(1153, 492)},
        {"id": "espectro_derecha", "type": "espectro", "pos": Vector2(985, 475)},
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
var ambient: AudioStreamPlayer
var effect: AudioStreamPlayer

func _ready() -> void:
    Game.enter_lujuria()
    hero.world = self
    hero.health_changed.connect(_on_hero_health_changed)
    hero.exhausted.connect(_on_hero_exhausted)
    hud.configure_chapter("lujuria", hero)
    hud.option_selected.connect(_answer_dialogue)
    hud.pause_requested.connect(_toggle_pause)
    hud.exit_to_menu_requested.connect(_back_to_menu)
    fx.world_ref = self
    _make_interactives()
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
    ambient = AudioStreamPlayer.new()
    ambient.stream = load("res://assets/lujuria/audio/lujuria_ambiente.wav")
    ambient.volume_db = -19.0
    add_child(ambient)
    if ambient.stream != null:
        ambient.finished.connect(func() -> void: ambient.play())
        ambient.play()
    effect = AudioStreamPlayer.new()
    effect.stream = load("res://assets/lujuria/audio/sello.wav")
    effect.volume_db = -12.0
    add_child(effect)

func _play_fx() -> void:
    if effect.stream != null:
        effect.play()

func _make_interactives() -> void:
    _add_marker("virgilio", "virgilio", "HABLAR CON VIRGILIO", Vector2(858, 877))
    _add_marker("paolo", "paolo", "ESCUCHAR A PAOLO", Vector2(293, 532))
    _add_marker("francesca", "francesca", "ESCUCHAR A FRANCESCA", Vector2(1153, 529))
    _add_marker("sello_inicio", "sello", "SELLO DE LA MEMORIA", Vector2(722, 689))
    _add_marker("sello_izquierdo", "sello", "SELLO DEL ALIENTO", Vector2(387, 422))
    _add_marker("sello_derecho", "sello", "SELLO DEL JUICIO", Vector2(1052, 420))
    _add_marker("puerta", "puerta", "UMBRAL HACIA LA GULA", Vector2(720, 179))

func _add_marker(uid: String, kind: String, caption: String, where: Vector2) -> void:
    var marker: Variant = INTER_SCENE.instantiate()
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
    if not can_walk(checkpoint, 14.0):
        checkpoint = SPAWN
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
    hud.set_dash_fraction(1.0 - clampf(hero.dash_recharge / 0.85, 0.0, 1.0))
    if not game_active or paused or hud.dialogue_open:
        hud.set_nearby("")
        return
    var nearby: Variant = _nearest_interactive()
    for marker in markers.get_children():
        marker.set("near", marker == nearby)
    hud.set_nearby(str(nearby.caption) if nearby != null else "")
    if Input.is_action_just_pressed("interact") and nearby != null:
        _use_marker(nearby)
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
            ["Aliviar su culpa: el amor los venció a los dos · Redención",
             "Recordarle que la pasión no disculpa la traición · Rigor"])
    else:
        _open_dialogue("francesca", "FRANCESCA · ALMA DE LA LUJURIA",
            "Sigo leyendo el mismo libro que leíamos la noche en que morimos. Sabía lo que hacía y no dejé de leer: elegí cada página. Dime algo que yo no sepa: ¿aún se puede aprender después de caer, o mi historia ya se terminó de escribir?",
            ["Decirle que aprender aún puede redimirla · Redención",
             "Decirle que su caída ya escribió el final · Rigor"])

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
    checkpoint = Vector2(722, 685) if seals.size() == 1 else Vector2(544, 390) if seals.size() == 3 else checkpoint
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
        message = "Escucha a Paolo y Francesca. Tu juicio alterará Redención y Rigor."
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
    if dialogue_context == "intro":
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
    if hud.dialogue_open:
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
    hud.set_lujuria_state(Game.progress, seals.size(), decided.size(), boss_defeated)
    hud.set_health(hero.health, hero.max_health)

func _on_hero_health_changed(current: int, maximum: int) -> void:
    hud.set_health(current, maximum)

func _on_hero_exhausted() -> void:
    game_active = false
    _toast("Dante cae, pero su camino aún continúa...")
    await get_tree().create_timer(1.2).timeout
    if not is_inside_tree():
        return
    hero.restore(hero.max_health, checkpoint)
    hero.control_enabled = true
    game_active = true
    _toast("Dante regresa a su último punto de descanso.")

func _complete_level() -> void:
    game_active = false
    hero.control_enabled = false
    Game.progress["lujuria_completed"] = true
    _save_state()
    _play_fx()
    get_tree().change_scene_to_file("res://scenes/FinLujuria.tscn")

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
        if vector.length() <= (100.0 if enemy.archetype == "minos" else 72.0) and vector.normalized().dot(facing) > 0.05:
            enemy.take_damage(2, facing)
    _play_fx()

func spawn_projectile(start: Vector2, direction: Vector2, hostile: bool, hit_damage: int) -> void:
    var shot = PROJECTILE_SCENE.instantiate()
    shot.position = start
    shot.direction = direction.normalized()
    shot.enemy_owned = hostile
    shot.damage = hit_damage
    shot.speed = 258.0 if hostile else 355.0
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
    for pt in [p, p + Vector2(radius, 0), p + Vector2(-radius, 0), p + Vector2(0, radius), p + Vector2(0, -radius)]:
        if not _is_ground(pt):
            return false
    return true

func _in_ellipse(p: Vector2, c: Vector2, rx: float, ry: float) -> bool:
    return pow((p.x - c.x) / rx, 2.0) + pow((p.y - c.y) / ry, 2.0) <= 1.0

func _is_ground(p: Vector2) -> bool:
    if p.x < 104.0 or p.x > 1342.0 or p.y < 155.0 or p.y > 1070.0:
        return false
    var ground := false
    # Entrance causeway and lower ceremonial courtyard.
    ground = ground or Rect2(634, 900, 188, 176).has_point(p)
    ground = ground or _in_ellipse(p, Vector2(720, 833), 339.0, 164.0)
    ground = ground or Rect2(609, 620, 230, 157).has_point(p)
    # Circumferential plaza around the lovers' statue.
    ground = ground or _in_ellipse(p, Vector2(724, 531), 300.0, 198.0)
    ground = ground or Rect2(140, 440, 1170, 113).has_point(p)
    ground = ground or Rect2(260, 395, 275, 153).has_point(p)
    ground = ground or Rect2(910, 395, 280, 153).has_point(p)
    # Upper platform with Minos and the doorway.
    ground = ground or Rect2(454, 258, 540, 165).has_point(p)
    ground = ground or Rect2(560, 177, 325, 155).has_point(p)
    ground = ground or Rect2(580, 389, 291, 57).has_point(p)
    # Monumental statue is solid and not traversable.
    if _in_ellipse(p, Vector2(727, 503), 125.0, 116.0):
        return false
    return ground


