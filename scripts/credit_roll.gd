extends Control

signal finished
var exit_after := false
var closing := false

func _ready() -> void:
    set_anchors_and_offsets_preset(PRESET_FULL_RECT)
    AudioManager.enter("credits")
    var art := TextureRect.new()
    art.texture = preload("res://assets/traicion/world/cocito.png")
    art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    add_child(art)
    art.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
    var shade := ColorRect.new()
    shade.color = Color("#111015e8")
    add_child(shade)
    shade.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
    var reel := VBoxContainer.new()
    reel.add_theme_constant_override("separation", 25)
    reel.anchor_right = 1.0
    shade.add_child(reel)
    for line in ["INFERNO: EL DESCENSO", "✦", "CREADO POR", "Alexander Ñacato", "Leidy Saraguro", "Gabriel Baez", "✦", "GRACIAS POR ACOMPAÑAR A DANTE"]:
        var label := Label.new()
        label.text = line
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        label.add_theme_font_size_override("font_size", 40 if line.begins_with("INFERNO") else 26)
        label.add_theme_color_override("font_color", Color("#efd6aa"))
        reel.add_child(label)
    var button = preload("res://scripts/inferno_button.gd").new()
    button.text = "Volver" if not exit_after else "Saltar y salir"
    var margin := MarginContainer.new()
    margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
    shade.add_child(margin)
    margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_right", 22)
    margin.add_theme_constant_override("margin_bottom", 20)
    button.size_flags_horizontal = Control.SIZE_SHRINK_END
    button.size_flags_vertical = Control.SIZE_SHRINK_END
    margin.add_child(button)
    button.pressed.connect(_close)
    button.grab_focus()
    reel.position.y = size.y * 0.74
    var roll := create_tween()
    roll.tween_property(reel, "position:y", -460.0, 21.0)
    roll.tween_callback(_close)

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER]:
        get_viewport().set_input_as_handled()
        _close()

func _close() -> void:
    if closing:
        return
    closing = true
    if exit_after:
        get_tree().quit()
    else:
        finished.emit()
        queue_free()
