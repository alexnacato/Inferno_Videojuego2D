extends Node2D
## Capítulo VII independiente: no presupone que III-VI estén implementados.
const Geometry = preload("res://scripts/violencia_geometry.gd")
const Enemy = preload("res://scripts/violencia_enemy.gd")
const Guardian = preload("res://scripts/violencia_guardian.gd")
const Ash = preload("res://scripts/violencia_ash.gd")
const Marker = preload("res://scripts/violencia_marker.gd")
const Projectile = preload("res://scripts/violencia_projectile.gd")
const SEAL_ORDER := ["contencion", "memoria", "tregua"]
const POINTS := [
    {"id":"virgilio", "kind":"guide", "caption":"HABLAR CON VIRGILIO", "p":Vector2(449,542) * Geometry.SCALE},
    {"id":"contencion", "kind":"seal", "caption":"VOTO DE CONTENCIÓN", "p":Geometry.VOWS[0]},
    {"id":"guardia", "kind":"soul", "caption":"ESCUCHAR AL GUARDIA", "p":Vector2(505,482) * Geometry.SCALE},
    {"id":"memoria", "kind":"seal", "caption":"VOTO DE MEMORIA", "p":Geometry.VOWS[1]},
    {"id":"testigo", "kind":"soul", "caption":"ESCUCHAR AL TESTIGO", "p":Vector2(142,311) * Geometry.SCALE},
    {"id":"tregua", "kind":"seal", "caption":"VOTO DE TREGUA", "p":Geometry.VOWS[2]},
    {"id":"puerta", "kind":"gate", "caption":"UMBRAL DE SALIDA", "p":Geometry.EXIT}
]
const PILLAR_RADIUS := 125.0
const WAVES := {
    "pilar_contencion": [{"id":"guardian_contencion","type":"centauro","p":Vector2(361,488) * Geometry.SCALE}],
    "pilar_memoria": [{"id":"guardian_memoria","type":"mastin","p":Vector2(183,304) * Geometry.SCALE}],
    "pilar_tregua": [{"id":"guardian_tregua","type":"ceniza","p":Vector2(665,310) * Geometry.SCALE}]
}
const HEAT_ZONES := [Rect2(775,470,140,98), Rect2(1390,470,125,98)]
@onready var hero = $Actores/Dante
@onready var hud = $HUD
@onready var actors = $Actores
@onready var foes = $Enemigos
@onready var bullets = $Proyectiles
var geometry = Geometry.new()
var data: Dictionary = {}
var game_active := false
var paused := false
var boss_fighting := false
var boss_actor: Node2D
var markers: Dictionary = {}
var dialogue_context := ""
var heat_clock := 0.0
var heat_announced := false
var current_zone := ""
var debug_collision := false
var damage_flash := 0.0
var last_hp := 6
var sounds: Dictionary = {}
var finishing := false

var gate_art: Node2D

func _ready() -> void:
    preload("res://scripts/foreground.gd").install($Mapa, hero, PackedVector2Array([Vector2(218,225),Vector2(235,197),Vector2(246,166),Vector2(270,148),Vector2(299,145),Vector2(319,139),Vector2(325,167),Vector2(334,201),Vector2(346,229),Vector2(326,244),Vector2(242,247)]), 241.0)
    gate_art = preload("res://scripts/gate_visual.gd").install(self, Rect2(1083, 74, 135, 186), Color("ffac61"))
    Game.enter_violencia()
    data = _validated_state(Game.progress.get("violencia", {}))
    Game.progress["circle"] = "violencia"
    hero.world = self
    hero.control_enabled = true
    hero.health_changed.connect(_health_changed)
    hero.exhausted.connect(_exhausted)
    hero.combat_action.connect(_combat_feedback)
    hud.configure_chapter("violencia", hero)
    hud.option_selected.connect(_answer)
    hud.pause_requested.connect(_toggle_pause)
    hud.exit_to_menu_requested.connect(_to_menu)
    for point in POINTS:
        var marker = Marker.new()
        marker.uid = point["id"]
        marker.kind = point["kind"]
        marker.caption = point["caption"]
        marker.position = point["p"]
        actors.add_child(marker)
        markers[marker.uid] = marker
    var saved := Vector2(float(data.get("x",Geometry.SPAWN.x)),float(data.get("y",Geometry.SPAWN.y)))
    if int(data.get("layout", 0)) != 2 or not geometry.can_walk(saved,10):
        saved = Geometry.SPAWN
    hero.restore(hero.max_health,saved)
    _apply_upgrade()
    for wave in data["waves"]:
        if WAVES.has(wave):
            _spawn_wave(wave)
    _make_audio()
    _refresh()
    _save()
    game_active = true
    if not data["intro"]:
        _dialogue("intro", "VIRGILIO · EL SÉPTIMO CÍRCULO", "Tres recintos guardan la violencia: el río de sangre, el bosque de las almas y la arena ardiente. Cruza por la piedra. Enciende los votos en orden: CONTENCIÓN, MEMORIA y TREGUA. Escucha a quienes encuentres; después, el Minotauro probará tu dominio de la esquiva.", ["Entrar en el círculo VII"])
    else:
        notify("Círculo VII · Tu memoria y tus decisiones permanecen.")

func _validated_state(raw: Variant) -> Dictionary:
    var d := {"layout":0.0,"intro":false,"seals":[],"decisions":{},"waves":[],"defeated":[],"boss_down":false,"completed":false,"x":Geometry.SPAWN.x,"y":Geometry.SPAWN.y}
    if raw is Dictionary:
        for key in d:
            if raw.has(key) and (typeof(d[key]) == typeof(raw[key]) or key in ["x","y","layout"] and (raw[key] is float or raw[key] is int)):
                d[key] = raw[key]
    var ordered: Array = []
    for seal in d["seals"]:
        if ordered.size() < 3 and seal == SEAL_ORDER[ordered.size()]:
            ordered.append(seal)
        else:
            break
    d["seals"] = ordered
    var waves: Array = []
    for wave in d["waves"]:
        if WAVES.has(wave) and not wave in waves:
            waves.append(wave)
    d["waves"] = waves
    var decisions: Dictionary = {}
    for soul in ["guardia", "testigo"]:
        if str(d["decisions"].get(soul,"")) in ["redencion","rigor"]:
            decisions[soul] = d["decisions"][soul]
    d["decisions"] = decisions
    return d

func _process(delta: float) -> void:
    hero.control_enabled = game_active
    hud.set_dash_fraction(1.0-clampf(hero.dash_recharge/hero.dash_cooldown_duration,0,1))
    if not game_active:
        hud.set_nearby("")
        return
    heat_clock += delta
    damage_flash = maxf(0,damage_flash-delta)
    var near: Node2D = _nearest()
    for marker in markers.values():
        marker.near = marker == near
    hud.set_nearby(near.caption if near != null else "")
    if Input.is_action_just_pressed("interact") and near != null:
        _use_marker(near.uid)
    if Input.is_action_just_pressed("hint"):
        _hint()
    if not game_active:
        return
    _update_zone()
    _encounters()
    if not data["boss_down"] and not boss_fighting and _ritual_complete() and Geometry.ARENA.grow(-45).has_point(hero.position):
        _begin_boss()
        return
    if heat_active() and _on_hot_sand(hero.position):
        hero.take_damage(1)
    queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
        debug_collision = not debug_collision
        queue_redraw()
        get_viewport().set_input_as_handled()

func _update_zone() -> void:
    var zone := "FLEGETONTE · RÍO DE SANGRE" if hero.position.y > 1100 else "BOSQUE DE LAS ALMAS" if hero.position.y > 665 else "ARENAL ARDIENTE"
    if zone != current_zone:
        current_zone = zone
        notify(zone + (" · La piedra central te protege del calor." if hero.position.y < 665 else ""),4)

func _nearest() -> Node2D:
    var nearest: Node2D
    var distance := 91.0
    for marker in markers.values():
        var d: float = hero.position.distance_to(marker.position)
        if d < distance and (marker.kind not in ["soul", "guide"] or d <= 60.0):
            nearest = marker
            distance = d
    return nearest

func _use_marker(id: String) -> void:
    if id == "virgilio":
        _hint()
    elif id in SEAL_ORDER:
        _activate_seal(id)
    elif id in ["guardia", "testigo"]:
        if data["decisions"].has(id):
            _dialogue("", "ALMA · UN VEREDICTO RECORDADO", "Mi historia ya forma parte de tu descenso. Que el siguiente paso no repita la misma herida.", ["Continuar"])
        elif id == "guardia":
            _dialogue("soul_guardia", "ALMA DEL RÍO · EL GUARDIA", "Custodié un puente y obedecí órdenes que dañaban a los indefensos. Decirme inocente sería mentir; creer que no puedo cambiar también lo sería. ¿Qué harás con mi confesión?", ["Exigir reparación y ofrecer guía", "Imponer un juicio severo"])
        else:
            _dialogue("soul_testigo", "ALMA DEL BOSQUE · EL TESTIGO", "Guardé silencio cuando otros sufrían. Hoy cada rama guarda un nombre que no defendí. No te pido que borres mi responsabilidad: te pido que escuches esos nombres.", ["Escuchar y preservar su memoria", "Condenar su silencio"])
    elif id == "puerta":
        if data["boss_down"] and _ritual_complete():
            data["completed"] = true
            finishing = true
            _save()
            game_active = false
            hero.control_enabled = false
            Game.cross_threshold("res://scenes/FinViolencia.tscn")
        else:
            _hint()

func _activate_seal(id: String) -> void:
    if id in data["seals"]:
        notify("Este voto ya está encendido.")
        return
    var expected: String = SEAL_ORDER[data["seals"].size()]
    if id != expected:
        notify("La inscripción dice: CONTENCIÓN → MEMORIA → TREGUA.",5)
        play_sound("error")
        return
    _trigger_pillar(id)
    if _pillar_guardian_alive(id):
        notify("Derrota al guardián de este pilar antes de encender su voto.",4)
        return
    data["seals"].append(id)
    hero.heal(1)
    _save()
    _refresh()
    play_sound("sello")
    if _ritual_complete():
        _dialogue("", "LOS TRES VOTOS", "Los votos responden a las dos historias escuchadas. El camino a la arena está preparado. El Minotauro prepara sus cargas con el cuerpo: apártate cuando se lance y atácalo después del choque.",["Avanzar hacia la arena"])
    else:
        notify("Voto de %s encendido · Salud +1. Los nombres importan tanto como los sellos." % id.to_upper(),5)

func _pillar_guardian_alive(seal: String) -> bool:
    for enemy in foes.get_children():
        if not enemy.dead and enemy.uid == "guardian_"+seal:
            return true
    return false

func _dialogue(context: String, speaker: String, body: String, choices: Array) -> void:
    dialogue_context = context
    game_active = false
    hero.control_enabled = false
    hud.show_dialogue(speaker,body,choices)

func _answer(index: int) -> void:
    var context := dialogue_context
    dialogue_context = ""
    if context == "intro":
        data["intro"] = true
    elif context.begins_with("soul_"):
        var soul := context.trim_prefix("soul_")
        if not data["decisions"].has(soul):
            var key := "redencion" if index == 0 else "rigor"
            data["decisions"][soul] = key
            Game.progress[key] = int(Game.progress.get(key,0))+1
            play_sound("sello")
    elif context == "death":
        _respawn()
    _save()
    _refresh()
    game_active = not paused
    hero.control_enabled = game_active

func _ritual_complete() -> bool:
    return data["seals"].size() == 3 and data["decisions"].size() == 2

func _hint() -> void:
    var message := ""
    if data["seals"].size() < 3:
        var next: String = SEAL_ORDER[data["seals"].size()]
        message = "Enciende CONTENCIÓN al inicio del puente, MEMORIA junto al obelisco izquierdo y TREGUA junto al derecho, en ese orden. Ahora falta %s." % next.to_upper()
    elif data["decisions"].size() < 2:
        message = "Escucha al guardia en el patio de entrada y al testigo en el bosque. Puedes elegir compasión o rigor: ambas decisiones permiten continuar."
    elif not data["boss_down"]:
        message = "Sube por las escaleras centrales. En la arena, apártate hacia un lado cuando comience la carga. Si el Minotauro choca con una columna o un muro queda aturdido y recibe el doble de daño. La piedra central es segura; la arena lateral arde por pulsos."
    else:
        message = "El Minotauro ha caído. Tu esquiva ahora llega más lejos y te protege más tiempo. El arco del norte te llevará a Cocito."
    _dialogue("", "VIRGILIO · CONSEJO DEL GUÍA",message,["Continuar"])

func _encounters() -> void:
    if boss_fighting:
        return
    for seal in SEAL_ORDER:
        if hero.position.distance_to(markers[seal].position)<=PILLAR_RADIUS:
            _trigger_pillar(seal)

func _trigger_pillar(seal: String) -> void:
    var wave := "pilar_"+seal
    if wave in data["waves"]:
        return
    data["waves"].append(wave)
    _spawn_wave(wave)
    notify("Un guardián despierta junto al pilar de %s." % seal.to_upper(),4)
    _save()

func _spawn_wave(id: String) -> void:
    if not WAVES.has(id):
        return
    for spec in WAVES[id]:
        if spec["id"] in data["defeated"]:
            continue
        var exists := false
        for enemy in foes.get_children():
            if not enemy.is_queued_for_deletion() and enemy.uid==spec["id"]:
                exists = true
                break
        if not exists:
            _spawn_enemy(spec["type"],spec["id"],spec["p"])

func _spawn_enemy(type: String, id: String, p: Vector2) -> Node2D:
    var enemy = Enemy.new() if type == "minotauro" else Guardian.new()
    enemy.archetype = type
    enemy.uid = id
    enemy.world = self
    enemy.hero = hero
    enemy.position = geometry.nearest_walkable(p,31 if type == "minotauro" else float(Guardian.CONFIG[type]["radius"]))
    enemy.died.connect(_enemy_died)
    foes.add_child(enemy)
    return enemy

func _begin_boss() -> void:
    boss_fighting = true
    # Las amenazas del bosque no interfieren en el duelo ni disparan desde fuera.
    for enemy in foes.get_children():
        enemy.queue_free()
    for projectile in bullets.get_children():
        projectile.queue_free()
    boss_actor = _spawn_enemy("minotauro","minotauro",Vector2(425,182) * Geometry.SCALE)
    boss_actor.hp_changed.connect(func(hp: int, maximum: int): hud.set_boss_health(hp,maximum))
    hud.boss_text.text = "MINOTAURO · GUARDIÁN DE LA VIOLENCIA"
    hud.set_boss_health(boss_actor.hp,boss_actor.max_hp)
    hero.heal(hero.max_health)
    _dialogue("", "MINOTAURO · EL FUROR SIN SALIDA", "La bestia no comprende palabras. No habrá líneas que indiquen su embestida: no huyas en línea recta. Apártate, deja que choque y responde durante su aturdimiento. El duelo comienza con tu salud completa.",["Enfrentar al Minotauro"])
    play_sound("carga")

func _enemy_died(id: String) -> void:
    if id == "minotauro":
        data["boss_down"] = true
        boss_fighting = false
        Game.progress["dash_extended"] = true
        _apply_upgrade()
        hero.heal(hero.max_health)
        hud.hide_boss()
        _dialogue("", "VIRGILIO · LA FUERZA QUE SE CONTIENE", "El Minotauro ha caído. Has ganado ESQUIVA EXTENDIDA: mayor distancia, más invulnerabilidad y menor recarga. La salida del norte está abierta. La violencia no termina al devolver cada golpe; termina cuando eliges qué hacer con tu fuerza.",["Ir hacia el umbral"])
    elif not id in data["defeated"]:
        data["defeated"].append(id)
    _save()
    _refresh()

func _apply_upgrade() -> void:
    var improved := bool(Game.progress.get("dash_extended",false)) or bool(data["boss_down"])
    hero.dash_duration = 0.25 if improved else 0.18
    hero.dash_invulnerability = 0.42 if improved else 0.28
    hero.apply_relics()

func melee_hit(origin: Vector2, direction: Vector2) -> void:
    for enemy in foes.get_children():
        if enemy.dead:
            continue
        var to_enemy: Vector2 = enemy.position-origin
        if to_enemy.length() < 90+enemy.body_radius and (to_enemy.length() < 28 or direction.dot(to_enemy.normalized()) > 0.25):
            if has_clear_path(origin, enemy.position):
                enemy.take_damage(2,direction)
    play_sound("golpe")

func spawn_projectile(origin: Vector2, direction: Vector2, hostile: bool, amount: int, kind: String = "verse") -> void:
    var shot = Projectile.new()
    shot.position = origin
    shot.direction = direction.normalized()
    shot.enemy_owned = hostile
    shot.kind = kind
    shot.damage = amount
    shot.world = self
    shot.speed = (300 if kind == "arrow" else 205 if kind == "ember" else 255) if hostile else 620
    bullets.add_child(shot)
    if not hostile:
        play_sound("verso")

func spawn_ash(origin: Vector2) -> void:
    if not geometry.can_walk(origin,5):
        return
    var ash = Ash.new()
    ash.position = origin
    ash.world = self
    bullets.add_child(ash)

func can_walk(p: Vector2, radius: float = 14.0) -> bool:
    return geometry.can_walk(p,radius,boss_fighting)

func has_clear_path(a: Vector2, b: Vector2) -> bool:
    return preload("res://scripts/walk_solver.gd").clear_segment(a, b, can_walk.bind(3.0))

func can_occupy_hero(p: Vector2, _dodging: bool = false) -> bool:
    if not can_walk(p, 10.0):
        return false
    for marker in markers.values():
        if marker.kind in ["guide", "soul"] and preload("res://scripts/interaction_visual.gd").footprint(p, marker, 10.0):
            return false
    return true

func move_on_ground(origin: Vector2, displacement: Vector2, radius: float) -> Vector2:
    return geometry.move_on_ground(origin,displacement,radius,boss_fighting)

func wind_at(_p: Vector2) -> Vector2:
    return Vector2.ZERO

func heat_active() -> bool:
    return fmod(heat_clock,6.0) >= 3.8

func _on_hot_sand(p: Vector2) -> bool:
    for zone in HEAT_ZONES:
        if zone.has_point(p):
            return true
    return false

func _health_changed(current: int, maximum: int) -> void:
    hud.set_health(current,maximum)
    if current < last_hp:
        play_sound("herida")
        damage_flash = 0.35
    last_hp = current

func _exhausted() -> void:
    game_active = false
    hero.control_enabled = false
    _dialogue("death", "VIRGILIO", ("El Minotauro te ha derribado. Respira, Dante. Sus cargas lo dejan indefenso cuando choca." if boss_fighting else "La violencia de estos guardianes te ha hecho caer. Levántate, Dante. Ya conoces el ritmo de sus golpes.") + " Volverás a la entrada con los votos y las decisiones guardados.",["Volver a la entrada"])

func _respawn() -> void:
    boss_fighting = false
    for enemy in foes.get_children():
        enemy.queue_free()
    for shot in bullets.get_children():
        shot.queue_free()
    hud.hide_boss()
    boss_actor = null
    hero.restore(hero.max_health,Geometry.SPAWN)
    _apply_upgrade()
    data["x"] = Geometry.SPAWN.x
    data["y"] = Geometry.SPAWN.y
    for wave in data["waves"]:
        if WAVES.has(wave):
            _spawn_wave(wave)
    heat_clock = 0

func _toggle_pause() -> void:
    if hud.dialogue_open or (not game_active and not paused):
        return
    paused = not paused
    game_active = not paused
    hero.control_enabled = game_active
    hud.set_pause(paused)
    if paused:
        _save()

func _to_menu() -> void:
    _save()
    game_active = false
    get_tree().change_scene_to_file("res://scenes/MenuPrincipal.tscn")

func _save() -> void:
    data["layout"] = 2
    # Una carga interrumpida no reanuda un jefe a medias: se vuelve al pie de la arena.
    var p: Vector2 = Vector2(352,263) * Geometry.SCALE if boss_fighting else hero.position
    data["x"] = p.x
    data["y"] = p.y
    Game.progress["violencia"] = data.duplicate(true)
    Game.progress["circle"] = "violencia"
    Game.save_progress()

func _refresh() -> void:
    gate_art.set("open", data["boss_down"])
    hud.set_violencia_state(Game.progress,data["seals"].size(),data["decisions"].size(),data["boss_down"])
    for id in markers:
        markers[id].complete = id in data["seals"] or data["decisions"].has(id) or id == "puerta" and data["boss_down"]

func notify(message: String, duration: float = 3.8) -> void:
    hud.toast(message,duration)

func _combat_feedback(kind: String) -> void:
    if kind == "esquivar":
        play_sound("esquiva")

func _make_audio() -> void:
    for id in ["sello","error","carga","choque","impacto","golpe","verso","herida","esquiva"]:
        var sound := AudioStreamPlayer.new()
        sound.bus = "SFX"
        sound.stream = load("res://assets/violencia/%s.wav" % id)
        sound.volume_db = -18 if id in ["carga","choque"] else -23
        add_child(sound)
        sounds[id] = sound

func play_sound(id: String) -> void:
    if sounds.has(id):
        sounds[id].play()

func _exit_tree() -> void:
    for sound in sounds.values():
        if is_instance_valid(sound):
            sound.stop()

func _draw() -> void:
    if heat_clock > 0:
        var pulse := fmod(heat_clock,6.0)
        var warning := pulse >= 2.7 and pulse < 3.8
        var hot := heat_active()
        if warning or hot:
            for zone in HEAT_ZONES:
                # Brasas y ceniza sobre las fisuras ya pintadas en el mapa.
                # Se evita dibujar geometría que tape el grabado del suelo.
                for i in range(24):
                    var origin: Vector2 = zone.position+Vector2(15+fmod(i*61.7,zone.size.x-30),15+fmod(i*37.3,zone.size.y-30))
                    var life := fmod(heat_clock*0.45+float(i)*0.13,1.0)
                    var ember := origin+Vector2(sin(heat_clock+i)*7,-life*38)
                    var opacity := sin(life*PI)*(0.65 if hot else 0.12)
                    draw_circle(ember,4,Color(0.6,0.18,0.08,opacity*0.10))
                    draw_circle(ember,1.1,Color(0.88,0.49,0.25,opacity))
                    draw_line(ember,ember+Vector2(1,3),Color(0.54,0.30,0.22,opacity*0.3),1,true)
    if debug_collision:
        for polygon in geometry.polygons:
            var closed: PackedVector2Array = polygon.duplicate()
            closed.append(polygon[0])
            draw_polyline(closed,Color(0.2,0.95,0.55,0.9),2,true)
        for pillar in Geometry.PILLARS:
            draw_arc(pillar,32,0,TAU,40,Color(1,0.4,0.3),2,true)
