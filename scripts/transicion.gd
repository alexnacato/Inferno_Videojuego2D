extends Control
## Pantalla entre capítulos: mantiene el progreso moral y permite continuar.

func _ready() -> void:
    Game.enter_lujuria()
    var bg: TextureRect = TextureRect.new()
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.texture = load("res://assets/lujuria/world/lujuria_base.png")
    bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    add_child(bg)

    var veil: ColorRect = ColorRect.new()
    veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    veil.color = Color(0.055, 0.040, 0.080, 0.83)
    add_child(veil)

    var panel: PanelContainer = PanelContainer.new()
    panel.position = Vector2(279, 133)
    panel.custom_minimum_size = Vector2(722, 461)
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = Color("#e6e2dc")
    style.border_color = Color("#7b3f9e")
    style.set_border_width_all(3)
    style.set_corner_radius_all(11)
    style.set_content_margin_all(24)
    panel.add_theme_stylebox_override("panel", style)
    add_child(panel)

    var box: VBoxContainer = VBoxContainer.new()
    box.add_theme_constant_override("separation", 20)
    panel.add_child(box)
    box.add_child(_label("I N F E R N O   ·   E L   D E S C E N S O", 19))
    box.add_child(HSeparator.new())
    box.add_child(_label("DEL SILENCIO AL VENDAVAL", 29))
    var copy: Label = _label("El jardín del Limbo queda atrás. Un viento incesante te llama al segundo círculo, donde Paolo y Francesca aguardan junto al juez Minos.", 19)
    copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    box.add_child(copy)
    box.add_child(_label("CÍRCULO II  ·  LUJURIA", 27))
    box.add_child(_label("Redención: %d   ·   Rigor: %d" % [int(Game.progress["redencion"]), int(Game.progress["rigor"])], 21))
    var continue_button: Button = Button.new()
    continue_button.text = "CONTINUAR A LUJURIA"
    continue_button.custom_minimum_size = Vector2(335, 55)
    continue_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/Lujuria.tscn"))
    box.add_child(continue_button)
    continue_button.grab_focus()

    var fade: ColorRect = ColorRect.new()
    fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    fade.color = Color.BLACK
    fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(fade)
    create_tween().tween_property(fade, "modulate:a", 0.0, 0.85)

func _label(value: String, size_px: int) -> Label:
    var node: Label = Label.new()
    node.text = value
    node.add_theme_font_size_override("font_size", size_px)
    node.add_theme_color_override("font_color", Color("#373040"))
    node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    return node
