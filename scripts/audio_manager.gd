extends Node

const ROOTS := {"limbo": 110.0, "lujuria": 146.8, "gula": 98.0, "violencia": 82.4, "traicion": 196.0, "menu": 130.8, "credits": 164.8, "luz": 174.6, "ceniza": 73.4}
const LENGTHS := {"paso": 0.09, "golpe": 0.16, "verso": 0.20, "impacto": 0.15, "enemigo": 0.29,
    "jefe": 0.55, "muerte": 0.42, "alma": 0.52, "sello": 0.41, "menu": 0.11, "victoria": 0.82,
    "derrota": 0.63, "hielo": 0.50, "aparicion": 0.39, "tinta": 0.042, "reliquia": 0.56}
const RATE := 16000
const EXISTING := {
    "limbo": preload("res://assets/audio/limbo_ambiente.wav"),
    "lujuria": preload("res://assets/lujuria/audio/lujuria_ambiente.wav"),
    "violencia": preload("res://assets/violencia/violencia_ambiente.wav"),
}
var chapter := ""
var cache: Dictionary = {}
var ambience: AudioStreamPlayer
var voices: Array[AudioStreamPlayer] = []
var next_voice := 0
var retiring: AudioStreamPlayer
var fade: Tween
var arrival_queue: Array[String] = []
var arrival_delay := 0.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    for bus_name in ["Música", "SFX"]:
        AudioServer.add_bus()
        AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
    ambience = AudioStreamPlayer.new()
    ambience.bus = "Música"
    ambience.volume_db = -22.0
    add_child(ambience)
    for i in range(10):
        var voice := AudioStreamPlayer.new()
        voice.bus = "SFX"
        add_child(voice)
        voices.append(voice)
    get_tree().node_added.connect(_connect_button)

func _exit_tree() -> void:
    if is_instance_valid(ambience):
        ambience.stop()
        ambience.stream = null
    if is_instance_valid(retiring):
        retiring.stop()
    for voice in voices:
        if is_instance_valid(voice):
            voice.stop()
            voice.stream = null
    cache.clear()

func _connect_button(node: Node) -> void:
    if node is Button:
        node.pressed.connect(cue.bind("menu"))

func enter(circle: String) -> void:
    if chapter == circle:
        return
    chapter = circle
    arrival_queue.clear()
    arrival_delay = 0.0
    if fade != null:
        fade.kill()
    if is_instance_valid(retiring):
        retiring.stop()
        retiring.queue_free()
    retiring = ambience if ambience.playing else null
    if retiring != null:
        ambience = AudioStreamPlayer.new()
        ambience.bus = "Música"
        add_child(ambience)
    if chapter.is_empty() and not is_instance_valid(retiring):
        return
    fade = create_tween().set_parallel()
    if is_instance_valid(retiring):
        fade.tween_property(retiring, "volume_db", -60.0, 0.55)
    if not chapter.is_empty():
        ambience.stream = _ambience_track()
        ambience.volume_db = -58.0
        ambience.play()
        fade.tween_property(ambience, "volume_db", -22.0, 0.55)
    if is_instance_valid(retiring):
        fade.chain().tween_callback(_retire)

func _retire() -> void:
    if is_instance_valid(retiring):
        retiring.stop()
        retiring.queue_free()
        retiring = null

func _ambience_track() -> AudioStreamWAV:
    if not EXISTING.has(chapter):
        return _sound("ambiente")
    var stream := EXISTING[chapter].duplicate() as AudioStreamWAV
    stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
    stream.loop_end = roundi(stream.get_length() * stream.mix_rate)
    return stream

func cue(event: String, pitch: float = 1.0, profile: String = "") -> void:
    if not LENGTHS.has(event) or voices.is_empty():
        return
    var voice := voices[next_voice]
    next_voice = (next_voice + 1) % voices.size()
    voice.stream = _sound(event, profile)
    voice.pitch_scale = pitch
    voice.volume_db = -30.0 if event == "tinta" else -8.0 if event == "aparicion" else -20.0 if event == "paso" else -12.0
    voice.play()

func _process(delta: float) -> void:
    arrival_delay = maxf(0.0, arrival_delay - delta)
    if arrival_delay == 0.0 and not arrival_queue.is_empty():
        var kind: String = arrival_queue.pop_front()
        cue("aparicion", 0.63 + float(posmod(kind.hash(), 21)) * 0.046, kind)
        arrival_delay = 0.28

func foe_voice(kind: String, id: String = "") -> void:
    var pitch := 0.63 + float(posmod(kind.hash(), 21)) * 0.046
    if not id.is_empty():
        var key := chapter + "/" + id
        if Game.progress["seen_foes"].has(key):
            return
        Game.progress["seen_foes"][key] = true
        arrival_queue.append(kind)
    else:
        cue("enemigo", pitch, kind)

func _sound(event: String, profile: String = "") -> AudioStreamWAV:
    var key := chapter + "/" + event + "/" + profile
    if cache.has(key):
        return cache[key]
    var looped := event == "ambiente"
    var duration: float = 4.0 if looped else LENGTHS[event]
    var base: float = ROOTS.get(chapter, 130.8)
    var seed := RandomNumberGenerator.new()
    seed.seed = key.hash()
    var pcm := PackedByteArray()
    var count := roundi(duration * RATE)
    pcm.resize(count * 2)
    var filtered := 0.0
    for i in range(count):
        var t := float(i) / RATE
        var u := t / duration
        filtered = lerpf(filtered, seed.randf_range(-1.0, 1.0), 0.25)
        var sound: float
        if looped:
            var pitch := roundf(base * 0.5 * duration) / duration
            sound = sin(TAU * pitch * t) * 0.18 + sin(TAU * pitch * 1.5 * t) * 0.10
            sound *= sin(PI * u) * (0.7 + 0.3 * cos(TAU * u * 3.0))
            var beat := fposmod(t, 0.5) * 2.0
            var pattern := int(t * 2.0) % 8
            var interval := [1.0, 1.25, 1.5, 2.0, 1.5, 1.25, 1.125, 1.0][pattern] as float
            if chapter == "gula":
                sound += pow(1.0 - beat, 5.0) * sin(TAU * base * 0.34 * t) * 0.3
            else:
                sound += sin(TAU * base * interval * t) * sin(PI * beat) * (0.18 if chapter in ["luz", "credits"] else 0.09)
                if chapter == "traicion":
                    sound += sin(TAU * base * interval * 3.0 * t) * sin(PI * beat) * pow(1.0 - beat, 4.0) * 0.12
        elif event in ["alma", "sello", "menu", "victoria", "tinta", "reliquia"]:
            sound = (sin(TAU * base * 3.0 * t) + sin(TAU * base * 4.5 * t) * u) * 0.24
        else:
            var bright := 2.6 if chapter == "traicion" else 0.8 if chapter in ["gula", "violencia"] else 1.6
            sound = filtered * 0.55 + sin(TAU * base * bright * t * (1.0 - u * 0.45)) * 0.24
            if event in ["jefe", "derrota", "muerte"]:
                sound += sin(TAU * base * 0.55 * t) * 0.20
        if not profile.is_empty():
            if profile in ["mastin", "rastrero", "cerbero"]:
                sound += sin(TAU * base * (0.8 * t + 0.62 * t * t)) * sin(PI * u) * 0.50
            elif profile in ["espectro", "escanciador", "ceniza"]:
                sound = filtered * 0.72 + sin(TAU * base * 2.7 * t) * 0.13
            elif profile in ["minos", "minotauro", "lucifer"]:
                sound += sin(TAU * base * 0.39 * t) * (0.24 + 0.18 * cos(TAU * 19.0 * t))
            else:
                sound += sin(TAU * base * 0.72 * t) * (0.20 + 0.11 * sin(TAU * 12.0 * t))
        if not looped:
            sound *= minf(1.0, u * 28.0) * pow(1.0 - u, 1.8)
        pcm.encode_s16(i * 2, roundi(clampf(sound, -1.0, 1.0) * 30200))
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = RATE
    stream.data = pcm
    if looped:
        stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
        stream.loop_end = count
    cache[key] = stream
    return stream
