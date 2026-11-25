extends Control

var story: Variant
var stack: VBoxContainer
var advance: Button
var veil: ColorRect
var verdict := ""
var summarized := false

func _ready() -> void:
    verdict = Game.record_ending()
    var saved := verdict == "luz"
    AudioManager.enter(verdict)
    var backdrop := ColorRect.new()
    backdrop.color = Color("#100d0b")
    add_child(backdrop)
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var background := TextureRect.new()
    background.texture = preload("res://assets/traicion/world/final_luz.png") if saved else preload("res://assets/traicion/world/final_ceniza.png")
    background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    add_child(background)
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    veil = ColorRect.new()
    veil.color = Color("#120e0b")
    add_child(veil)
    veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    create_tween().tween_property(veil, "color:a", 0.24 if saved else 0.44, 1.7)
    var dock := VBoxContainer.new()
    dock.alignment = BoxContainer.ALIGNMENT_END
    add_child(dock)
    dock.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    dock.offset_left = 160
    dock.offset_right = -160
    dock.offset_bottom = -32
    var panel := PanelContainer.new()
    dock.add_child(panel)
    stack = VBoxContainer.new()
    stack.add_theme_constant_override("separation", 10)
    panel.add_child(stack)
    stack.add_child(_label("✦  INFERNO: EL DESCENSO  ✦", 17))
    stack.add_child(HSeparator.new())
    stack.add_child(_label("BEATRIZ SE SALVA" if saved else "BEATRIZ NO SE SALVA", 27))
    story = preload("res://scripts/ink_text.gd").new()
    story.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    story.add_theme_font_size_override("font_size", 19)
    stack.add_child(story)
    advance = preload("res://scripts/inferno_button.gd").new()
    advance.text = "Ver resumen del viaje"
    advance.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    stack.add_child(advance)
    advance.hide()
    advance.pressed.connect(_advance)
    story.revealed.connect(func() -> void:
        advance.show()
        advance.grab_focus())
    story.begin("Dante extiende la mano. Beatriz pisa el primer peldaño y la luz atraviesa el hielo. Detrás quedan las voces que eligió escuchar." if saved else "La ceniza cubre el último peldaño. Dante llama a Beatriz, pero su voz ya no alcanza la otra orilla. Sale con el peso de cada decisión.")

func _input(event: InputEvent) -> void:
    if not summarized and story.writing and event.is_pressed() and event.is_action_pressed("ui_accept"):
        story.finish()
        get_viewport().set_input_as_handled()

func _advance() -> void:
    if not summarized:
        summarized = true
        story.visible = false
        var summary := _label("REDENCIÓN  %d     ◆     RIGOR  %d" % [Game.progress["redencion"], Game.progress["rigor"]], 22)
        stack.add_child(summary)
        stack.move_child(summary, advance.get_index())
        var rows := ["Limbo", "Lujuria", "Gula", "Violencia", "Traición"]
        var keys := ["limbo", "lujuria", "gula", "violencia", "traicion"]
        for i in range(keys.size()):
            var row := _label("%s · %s · %s" % [rows[i], Game.decisions_summary(keys[i]), "Reliquia encontrada" if Game.has_relic(keys[i]) else "Sin reliquia"], 17)
            stack.add_child(row)
            stack.move_child(row, advance.get_index())
        advance.text = "VER CRÉDITOS"
    else:
        advance.disabled = true
        var reel = preload("res://scripts/credit_roll.gd").new()
        reel.finished.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/MenuPrincipal.tscn"))
        add_child(reel)

func _label(value: String, font_size: int) -> Label:
    var node := Label.new()
    node.text = value
    node.add_theme_font_size_override("font_size", font_size)
    node.add_theme_color_override("font_color", Color("#352b22"))
    node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    return node