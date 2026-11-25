extends Label

signal revealed
var progress := 0.0
var writing := false
var last_tick := -1

func begin(value: String) -> void:
    text = value
    visible_characters = 0
    progress = 0.0
    last_tick = -1
    writing = not text.is_empty()
    if not writing:
        finish()

func finish() -> void:
    writing = false
    visible_characters = -1
    revealed.emit()

func _process(delta: float) -> void:
    if not writing:
        return
    progress += delta * 48.0
    visible_characters = int(progress)
    var pulse := int(progress / 5.0)
    if pulse != last_tick:
        last_tick = pulse
        AudioManager.cue("tinta", 0.91 + 0.15 * sin(pulse * 1.72))
    if visible_characters >= get_total_character_count():
        finish()
