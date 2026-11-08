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
    {"id":"alma_livia", "name":"ESCUCHAR A LIVIA", "pos":Vector2(1092, 287), "radius":116.0, "kind":"soul"},
    {"id":"puerta", "name":"PUERTA DEL DESCENSO", "pos":Vector2(769, 236), "radius":96.0, "kind":"gate"}
]
const ORDER = ["altar_memoria", "altar_saber", "altar_compasion"]

@onready var player: Variant = $World/Dante
@onready var world: Node2D = $World
@onready var gate_art: Node2D = $GateVisual
var hud: Variant
var markers: Dictionary = {}
var focused_id: String = ""
var dialog_context: String = ""
var paused: bool = false
var ambient: AudioStreamPlayer

func _ready() -> void:
    _build_collision()
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
    player.global_position = Vector2(float(Game.progress["pos_x"]), float(Game.progress["pos_y"])) if bool(Game.progress["checkpoint"]) else Vector2(769, 834)
    _build_ambient()
    _refresh()
    if not bool(Game.progress["intro_seen"]):
        _talk("intro", "VIRGILIO · GUÍA DE DANTE", "Éste es el Limbo. No escucharás gritos, sino el eco de quienes vivieron con virtud y sin esperanza. Recuerda, comprende y compadece. Solo así cederá el umbral.", ["Comenzar el recorrido"])
    else:
        _toast("Has regresado al Limbo. Tus elecciones permanecen.", 4.0)

func _process(_delta: float) -> void:
    if hud == null:
        return
    player.input_locked = paused or hud.dialogue_open
    hud.set_dash_fraction(player.dash_ready_fraction())
    if paused or hud.dialogue_open:
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

func _build_collision() -> void:
    # Límites invisibles, alineados con los bordes del jardín.
    for rectangle in [
        Rect2(-60, -60, 1660, 65), Rect2(-60, 967, 1660, 70),
        Rect2(-60, -60, 74, 1120), Rect2(1526, -60, 76, 1120),
        Rect2(0, 0, 692, 174), Rect2(842, 0, 698, 174),
        Rect2(700, 0, 140, 143),
        Rect2(129, 414, 350, 131), Rect2(1062, 414, 354, 131),
        Rect2(609, 317, 323, 277),
        Rect2(224, 187, 116, 150), Rect2(1204, 187, 116, 150)
    ]:
        _solid(rectangle)

func _solid(rectangle: Rect2) -> void:
    var obj: StaticBody2D = StaticBody2D.new()
    obj.name = "DecoracionSolida"
    obj.collision_layer = 1
    obj.collision_mask = 0
    obj.position = rectangle.position + rectangle.size / 2.0
    world.add_child(obj)
    var collider: CollisionShape2D = CollisionShape2D.new()
    var shape: RectangleShape2D = RectangleShape2D.new()
    shape.size = rectangle.size
    collider.shape = shape
    obj.add_child(collider)

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
    if paused or hud.dialogue_open:
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
        _talk(id, "ELIO · ALMA DEL LIMBO", "En vida busqué la verdad y enseñé a otros a pensar. Aun así, nadie pronuncia mi nombre. ¿Recordarás lo bueno que dejé, o me juzgarás por aquello que nunca conocí?", ["Reconocer su virtud · Redención", "Juzgar su ignorancia · Rigor"])
    else:
        _talk(id, "LIVIA · ALMA DEL LIMBO", "Cuidé de quienes estaban solos. Ahora mi voz se pierde entre las ruinas. ¿Me escucharás sin esperar recompensa, o condenarás mi silencio?", ["Escuchar y consolar · Redención", "Imponer tu juicio · Rigor"])

func _handle_door() -> void:
    if not Game.gate_unlocked():
        _talk("blocked", "UMBRAL DEL DESCENSO", "La puerta permanece sellada. Debes despertar los tres santuarios y escuchar a las dos almas. Aquí ninguna espada abrirá el camino.", ["Volver al jardín"])
        return
    _talk("finish", "EL UMBRAL RESPONDE", "El jardín se inclina ante tus decisiones. Al otro lado comienza el círculo de la Lujuria. Virgilio te aguarda para seguir descendiendo.", ["Terminar el capítulo I"])

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
            _toast("Tu decisión ha quedado escrita en el viaje.", 4.0)
        "finish":
            Game.progress["limbo_completed"] = true
            _play_sound("umbral", -8.0)
            _save_at_position()
            get_tree().change_scene_to_file("res://scenes/FinLimbo.tscn")
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
