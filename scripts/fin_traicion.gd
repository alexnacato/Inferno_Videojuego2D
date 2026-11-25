extends Control

func _ready() -> void:
    var background := TextureRect.new()
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background.texture = load("res://assets/traicion/world/cocito.png")
    background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    add_child(background)
    var shade := ColorRect.new()
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.color = Color(0.05, 0.068, 0.083, 0.76)
    add_child(shade)
    var panel := PanelContainer.new()
    panel.custom_minimum_size.x = 650.0
    var center := CenterContainer.new()
    add_child(center)
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    center.add_child(panel)
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation", 12)
    panel.add_child(stack)
    stack.add_child(_label("INFERNO · EL DESCENSO", 30))
    stack.add_child(HSeparator.new())
    stack.add_child(_label("CÍRCULO IX · TRAICIÓN COMPLETADA", 24))
    var story := _label("Los juramentos se rompieron. Ugolino y Bocca fueron escuchados. El guardián de Cocito cayó y Dante cruzó el centro del Infierno.", 18)
    story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    stack.add_child(story)
    stack.add_child(_label("Redención: %d     Rigor: %d" % [int(Game.progress["redencion"]), int(Game.progress["rigor"])], 20))
    stack.add_child(_label("El camino hacia la salida comienza.", 17))
    var menu := Button.new()
    menu.text = "VOLVER AL MENÚ PRINCIPAL"
    menu.custom_minimum_size = Vector2(320, 50)
    menu.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/MenuPrincipal.tscn"))
    stack.add_child(menu)
    menu.grab_focus()

func _label(value: String, font_size: int) -> Label:
    var node := Label.new()
    node.text = value
    node.add_theme_font_size_override("font_size", font_size)
    node.add_theme_color_override("font_color", Color("#20333d"))
    node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    return node
