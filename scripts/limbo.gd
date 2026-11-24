extends Node2D
## Círculo I: el jardín silencioso. Sin combate, con exploración, diálogo y dilemas.
const HUD_SCENE: PackedScene = preload("res://scenes/HUD.tscn")
const HOTSPOT_SCRIPT: Script = preload("res://scripts/hotspot.gd")
const POINTS = [
    {"id":"virgilio", "name":"HABLAR CON VIRGILIO", "pos":Vector2(936, 886), "radius":112.0, "kind":"guide"},
    {"id":"inscripcion", "name":"LEER INSCRIPCIÓN", "pos":Vector2(770, 850), "radius":77.0, "kind":"altar"},
    {"id":"altar_memoria", "name":"SANTUARIO DE LA MEMORIA", "pos":Vector2(282, 362), "radius":112.0, "kind":"altar"},
    {"id":"altar_saber", "name":"SANTUARIO DEL SABER", "pos":Vector2(1255, 362), "radius":112.0, "kind":"altar"},
    {"id":"altar_compasion", "name":"SANTUARIO DE LA COMPASIÓN", "pos":Vector2(770, 620), "radius":110.0, "kind":"altar"},
    {"id":"alma_elio", "name":"ESCUCHAR A ELIO", "pos":Vector2(67, 633), "radius":115.0, "kind":"soul"},
    {"id":"alma_livia", "name":"ESCUCHAR A LIVIA", "pos":Vector2(1092, 287), "radius":135.0, "kind":"soul"},
    {"id":"puerta", "name":"PUERTA DEL DESCENSO", "pos":Vector2(769, 236), "radius":96.0, "kind":"gate"}
]
const ORDER = ["altar_memoria", "altar_saber", "altar_compasion"]
const COLLISION_SAMPLES = [Vector2.ZERO, Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN,
    Vector2(0.7071, 0.7071), Vector2(-0.7071, 0.7071), Vector2(0.7071, -0.7071), Vector2(-0.7071, -0.7071)]

@onready var player: Variant = $World/Dante
@onready var world: Node2D = $World
@onready var gate_art: Node2D = $GateVisual
var hud: Variant
var markers: Dictionary = {}
var focused_id: String = ""
var dialog_context: String = ""
var paused: bool = false
var leaving := false
var ambient: AudioStreamPlayer
var monument_outline: PackedVector2Array = PackedVector2Array([
    Vector2(674, 491), Vector2(860, 491), Vector2(915, 527),
    Vector2(943, 568), Vector2(926, 605), Vector2(859, 639),
    Vector2(665, 639), Vector2(613, 608), Vector2(594, 565), Vector2(621, 525)
])

func _ready() -> void:
    player.navigation = self
    _build_markers()
    hud = HUD_SCENE.instantiate()
    add_child(hud)
    hud.set_player(player)
    hud.option_selected.connect(_on_dialogue_selected)
    hud.pause_requested.connect(_toggle_pause)
    hud.exit_to_menu_requested.connect(_back_to_menu)
    player.interaction_requested.connect(_interact)
    player.hint_requested.connect(_hint)
    player.dash_started.connect(func() -> void: _play_sound("esquiva", -17.0))
    player.message_requested.connect(_toast)
    player.combat_enabled = false
    var saved_position: Vector2 = Vector2(float(Game.progress["pos_x"]), float(Game.progress["pos_y"])) if bool(Game.progress["checkpoint"]) else Vector2(769, 834)
    player.global_position = saved_position if can_walk(saved_position, 10.0) else Vector2(769, 834)
    _build_ambient()
    _refresh()
    if not bool(Game.progress["intro_seen"]):
        _talk("intro", "VIRGILIO · GUÍA DE DANTE", "Éste es el Limbo. No escucharás gritos, sino el eco de quienes vivieron con virtud y sin esperanza. Recuerda, comprende y compadece. Solo así cederá el umbral.", ["Comenzar el recorrido"])
    else:
        _toast("Has regresado al Limbo. Tus elecciones permanecen.", 4.0)

func _process(_delta: float) -> void:
    if hud == null:
        return
    player.input_locked = leaving or paused or hud.dialogue_open
    hud.set_dash_fraction(player.dash_ready_fraction())
    if leaving or paused or hud.dialogue_open:
        hud.set_nearby("")
        return
    var near: Dictionary = _nearby()
    var id: String = str(near.get("id", ""))
    if id != focused_id:
        focused_id = id
        hud.set_nearby(str(near.get("name", "")))
        for key in markers.keys():
            var marker: Node2D = markers[key]
            marker.set("hovered", str(key) == id)

func can_walk(p: Vector2, radius: float = 10.0) -> bool:
    for offset in COLLISION_SAMPLES:
        if not _is_path(p + offset * radius):
            return false
    return true

func lake_jump_target(start: Vector2, direction: Vector2) -> Vector2:
    if absf(direction.y) < 0.88 or absf(direction.x) > 0.35 or not can_walk(start, 10.0):
        return start
    var landing: Vector2 = start + Vector2(0.0, signf(direction.y) * 225.0)
    if not can_walk(landing, 10.0):
        return start
    var midpoint: Vector2 = (start + landing) * 0.5
    for center_x in [285.0, 1253.0]:
        if _in_ellipse(midpoint, Vector2(center_x, 568.0), 142.0, 67.0):
            return landing
    return start

func _is_path(p: Vector2) -> bool:
    if p.x < 16.0 or p.x > 1524.0 or p.y < 218.0 or p.y > 964.0:
        return false
    # Stone paths, steps and the entrance apron of the painted garden.
    var stone: bool = Rect2(16, 391, 1508, 94).has_point(p)
    stone = stone or Rect2(16, 640, 1508, 102).has_point(p)
    stone = stone or Rect2(450, 455, 640, 287).has_point(p)
    stone = stone or Rect2(640, 720, 259, 245).has_point(p)
    stone = stone or Rect2(675, 218, 190, 227).has_point(p)
    stone = stone or Rect2(630, 350, 85, 95).has_point(p)
    stone = stone or Rect2(170, 355, 222, 91).has_point(p)
    stone = stone or Rect2(1148, 355, 222, 91).has_point(p)
    if not stone:
        return false
    # The two ponds and the sculpture are solid even where broad paths overlap.
    if _in_ellipse(p, Vector2(285, 568), 180.0, 90.0):
        return false
    if _in_ellipse(p, Vector2(1253, 568), 180.0, 90.0):
        return false
    # Sólo se bloquea el pedestal y su jardinera, sin proyectar la altura de las figuras sobre la escalera.
    return not Geometry2D.is_point_in_polygon(p, monument_outline)

func _in_ellipse(p: Vector2, center: Vector2, rx: float, ry: float) -> bool:
    var d: Vector2 = p - center
    return d.x * d.x / (rx * rx) + d.y * d.y / (ry * ry) <= 1.0

func _build_markers() -> void:
    for point in POINTS:
        var marker: Node2D = Node2D.new()
        marker.set_script(HOTSPOT_SCRIPT)
        marker.name = str(point["id"])
        marker.position = point["pos"]
        marker.set("kind", str(point["kind"]))
        marker.set("accent", Color(str(Game.CIRCLE_TINTS.get("limbo", "#9aa0a6"))))
        world.add_child(marker)
        markers[str(point["id"])] = marker

func _nearby() -> Dictionary:
    var best: Dictionary = {}
    var best_distance: float = INF
    for point in POINTS:
        var dist: float = player.global_position.distance_to(point["pos"])
        if dist <= float(point["radius"]) and dist < best_distance:
            best = point
            best_distance = dist
    return best

func _interact() -> void:
    if leaving or paused or hud.dialogue_open:
        return
    var point: Dictionary = _nearby()
    var id: String = str(point.get("id", ""))
    match id:
        "": _toast("No hay nada cercano con lo que interactuar.", 2.0)
        "virgilio": _talk("guide", "VIRGILIO", "Hay tres pilares en este lugar: el recuerdo, el conocimiento y la misericordia. Su orden no es casual. Las almas esperan que elijas qué hacer con sus historias.", ["Gracias, maestro"])
        "inscripcion": _talk("inscripcion", "LA INSCRIPCIÓN DEL LIMBO", "«Primero recuerda tu origen. Después conoce el sentido del camino. Por último, mira el dolor ajeno con compasión». La piedra describe el orden de los tres santuarios.", ["He comprendido"])
        "altar_memoria", "altar_saber", "altar_compasion": _activate_shrine(id)
        "alma_elio", "alma_livia": _talk_to_soul(id)
        "puerta": _handle_door()

func _activate_shrine(id: String) -> void:
    var index: int = ORDER.find(id)
    var step: int = int(Game.progress["shrine_step"])
    if index < step:
        _toast("Este santuario ya conserva su luz serena.")
        return
    if index != step:
        Game.progress["puzzle_errors"] = int(Game.progress["puzzle_errors"]) + 1
        Game.save_progress()
        if int(Game.progress["puzzle_errors"]) >= 2:
            _toast("Virgilio: «Memoria, Saber y Compasión. Nada florece fuera de ese orden». ", 5.0)
        else:
            _toast("Las marcas de la piedra se apagan: hay un orden que debes descubrir.", 5.0)
        return
    Game.progress["shrine_step"] = step + 1
    _play_sound("santuario", -9.0)
    _save_at_position()
    _refresh()
    match id:
        "altar_memoria": _talk("shrine", "SANTUARIO DE LA MEMORIA", "La piedra refleja un recuerdo de Beatriz. Algo que creías perdido sigue vivo en tu interior. La primera virtud despierta.", ["Continuar"])
        "altar_saber": _talk("shrine", "SANTUARIO DEL SABER", "Un verso grabado en la roca cobra significado: no todo castigo explica el valor de un alma. La segunda virtud despierta.", ["Continuar"])
        "altar_compasion": _talk("shrine", "SANTUARIO DE LA COMPASIÓN", "La última luz no ofrece poder, sino comprensión. El jardín vuelve a respirar. Has despertado sus tres virtudes.", ["Continuar"])

func _talk_to_soul(id: String) -> void:
    if not str(Game.progress.get(id, "")).is_empty():
        _toast("Esta alma ya conoce tu decisión.")
        return
    if id == "alma_elio":
        _talk(id, "ELIO · ALMA DEL LIMBO",
            "Fui maestro en Florencia: enseñé a pensar a quienes hoy son jueces y poetas, y ninguno repite mi nombre. Junto a mí espera una piedra sin inscribir, preparada para mi memoria. Dime, peregrino: ¿qué hago con ella?",
            ["Inscribir su nombre y contar su historia · Redención",
             "Dejar la piedra en blanco: la obra vale más que la fama · Rigor"])
    else:
        _talk(id, "LIVIA · ALMA DEL LIMBO",
            "Cuidé huérfanos durante la peste y enterré a más de los que salvé. Nadie reza por ellos ni por mí, y yo sé sus nombres: los recuerdo todos. ¿Valió la pena amar a los que no pudo salvar del todo?",
            ["Nombrar a sus huérfanos: su amor no se perdió · Redención",
             "El consuelo sin esperanza no borra el dolor · Rigor"])

func _handle_door() -> void:
    if not Game.gate_unlocked():
        _talk("blocked", "UMBRAL DEL DESCENSO", "La puerta permanece sellada. Debes despertar los tres santuarios y escuchar a las dos almas. Aquí ninguna espada abrirá el camino.", ["Volver al jardín"])
        return
    var red: int = int(Game.progress["redencion"])
    var rig: int = int(Game.progress["rigor"])
    var verdict: String
    if red > rig:
        verdict = "tu misericordia pesa más que tu severidad, y el jardín florece con ella."
    elif rig > red:
        verdict = "tu severidad pesa más que tu misericordia, y el jardín se aquieta ante ella."
    else:
        verdict = "tu balanza sigue pareja: ni piedad firme ni juicio firme."
    _talk("finish", "EL UMBRAL RESPONDE",
        "Has decidido sobre dos vidas y el jardín escuchó todo: %s Así recordarán las almas tu paso. Al otro lado comienza la Lujuria, donde nuevas voces exigirán tu juicio." % verdict,
        ["Descender a Lujuria"])

func _talk(context: String, speaker: String, message: String, choices: Array) -> void:
    dialog_context = context
    hud.show_dialogue(speaker, message, choices)
    player.input_locked = true

func _on_dialogue_selected(index: int) -> void:
    match dialog_context:
        "intro":
            Game.progress["intro_seen"] = true
            _save_at_position()
        "alma_elio", "alma_livia":
            var chosen_id: String = dialog_context
            Game.decide(chosen_id, index == 0)
            _play_sound("decision", -10.0)
            _save_at_position()
            _refresh()
            if chosen_id == "alma_elio":
                _talk("reply_elio", "ELIO · ALMA DEL LIMBO",
                    "Mi nombre vuelve a sonar en boca de los vivos. Sabré que pensé para alguien, y no en vano. Lleva mi recuerdo contigo al descenso." if index == 0
                    else "En blanco… Quizá tengas razón: la obra importa más que la firma. Aprendo a quedarme quieto. Tu veredicto serán siglos de silencio.",
                    ["Seguir tu camino"])
            else:
                _talk("reply_livia", "LIVIA · ALMA DEL LIMBO",
                    "Los nombres… sí, aún los recuerdo todos. Con que uno viva, mi cuidado seguirá vivo. Gracias por mirarme cuando todos miran al frente." if index == 0
                    else "Duelen tus palabras, pero no mienten. Aprendo a mirar lo que no hice, no solo lo que di. Que tu juicio me haga más honesta.",
                    ["Seguir tu camino"])
            return
        "finish":
            leaving = true
            Game.progress["limbo_completed"] = true
            _play_sound("umbral", -8.0)
            _save_at_position()
            Game.enter_lujuria()
            Game.cross_threshold("res://scenes/Transicion.tscn")
            return
    dialog_context = ""
    player.input_locked = false
    _refresh()

func _hint() -> void:
    if hud.dialogue_open or paused:
        return
    if int(Game.progress["shrine_step"]) < 3:
        var names: Array[String] = ["Memoria", "Saber", "Compasión"]
        _toast("VIRGILIO: Busca ahora el santuario de " + names[int(Game.progress["shrine_step"])] + ".", 5.0)
    elif Game.souls_completed() < 2:
        _toast("VIRGILIO: Escucha las voces sin nombre. Aún resta una decisión.", 5.0)
    else:
        _toast("VIRGILIO: El umbral ya ha escuchado tus pasos. Dirígete al norte.", 5.0)

func _refresh() -> void:
    hud.set_state(Game.progress, Game.souls_completed(), Game.gate_unlocked())
    gate_art.set("open", Game.gate_unlocked())
    for marker_id in markers.keys():
        var marker: Node2D = markers[marker_id]
        var id: String = str(marker_id)
        if id.begins_with("altar_"):
            marker.set("completed", ORDER.find(id) < int(Game.progress["shrine_step"]))
        elif id.begins_with("alma_"):
            marker.set("completed", not str(Game.progress.get(id, "")).is_empty())
        elif id == "puerta":
            marker.set("completed", Game.gate_unlocked())
        else:
            marker.set("completed", false)

func _save_at_position() -> void:
    Game.save_position(player.global_position)

func _toast(message: String, duration: float = 3.5) -> void:
    hud.toast(message, duration)

func _toggle_pause() -> void:
    if hud.dialogue_open:
        return
    paused = not paused
    player.input_locked = paused
    hud.set_pause(paused)

func _back_to_menu() -> void:
    _save_at_position()
    paused = false
    get_tree().change_scene_to_file("res://scenes/MenuPrincipal.tscn")

func _build_ambient() -> void:
    ambient = AudioStreamPlayer.new()
    var audio: AudioStream = load("res://assets/audio/limbo_ambiente.wav") as AudioStream
    ambient.stream = audio
    ambient.volume_db = -24.0
    add_child(ambient)
    if audio != null:
        ambient.finished.connect(func() -> void: ambient.play())
        ambient.play()

func _play_sound(id: String, volume: float = -12.0) -> void:
    var stream: AudioStream = load("res://assets/audio/" + id + ".wav") as AudioStream
    if stream == null:
        return
    var sound: AudioStreamPlayer = AudioStreamPlayer.new()
    sound.stream = stream
    sound.volume_db = volume
    add_child(sound)
    sound.finished.connect(func() -> void: sound.queue_free())
    sound.play()
