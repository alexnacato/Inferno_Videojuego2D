extends Node

const ROOTS := {"limbo": 110.0, "lujuria": 146.8, "gula": 98.0, "violencia": 82.4, "traicion": 196.0}
const LENGTHS := {"paso": 0.09, "golpe": 0.16, "verso": 0.20, "impacto": 0.15, "enemigo": 0.29,
    "jefe": 0.55, "muerte": 0.42, "alma": 0.52, "sello": 0.41, "menu": 0.11, "victoria": 0.82,
    "derrota": 0.63, "hielo": 0.50, "aparicion": 0.29}
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
    for voice in voices:
        if is_instance_valid(voice):
            voice.stop()

func _connect_button(node: Node) -> void:
    if node is Button:
        node.pressed.connect(cue.bind("menu"))

func enter(circle: String) -> void:
    if chapter == circle:
        return
    chapter = circle
    ambience.stop()
    if chapter != "":
        ambience.stream = _ambience_track()
        ambience.play()

func _ambience_track() -> AudioStreamWAV:
    if not EXISTING.has(chapter):
        return _sound("ambiente")
    var stream := EXISTING[chapter].duplicate() as AudioStreamWAV
    stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
    stream.loop_end = roundi(stream.get_length() * stream.mix_rate)
    return stream

func cue(event: String) -> void:
    if not LENGTHS.has(event) or voices.is_empty():
        return
    var voice := voices[next_voice]
    next_voice = (next_voice + 1) % voices.size()
    voice.stream = _sound(event)
    voice.volume_db = -20.0 if event == "paso" else -12.0
    voice.play()

func _sound(event: String) -> AudioStreamWAV:
    var key := chapter + "/" + event
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
        elif event in ["alma", "sello", "menu", "victoria"]:
            sound = (sin(TAU * base * 3.0 * t) + sin(TAU * base * 4.5 * t) * u) * 0.24
        else:
            var bright := 2.6 if chapter == "traicion" else 0.8 if chapter in ["gula", "violencia"] else 1.6
            sound = filtered * 0.55 + sin(TAU * base * bright * t * (1.0 - u * 0.45)) * 0.24
            if event in ["jefe", "derrota", "muerte"]:
                sound += sin(TAU * base * 0.55 * t) * 0.20
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
