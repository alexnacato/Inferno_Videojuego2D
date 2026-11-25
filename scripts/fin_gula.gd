extends Control

func _ready() -> void:
    var background := TextureRect.new()
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background.texture = load("res://assets/gula/world/gula_base.png")
    background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    add_child(background)
    var shade := ColorRect.new()
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.color = Color(0.025, 0.045, 0.020, 0.84)
    add_child(shade)
    var panel := PanelContainer.new()
    panel.custom_minimum_size.x = 650.0
    var style := StyleBoxFlat.new()
    style.bg_color = Color("#e6e5d9")
    style.border_color = Color("#5e8c31")
    style.set_border_width_all(3)
    style.set_corner_radius_all(10)
    style.set_content_margin_all(22)
    panel.add_theme_stylebox_override("panel", style)
    var center := CenterContainer.new()
    add_child(center)
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    center.add_child(panel)
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation", 20)
    panel.add_child(stack)
    stack.add_child(_label("INFERNO · EL DESCENSO", 30))
    stack.add_child(HSeparator.new())
    stack.add_child(_label("CÍRCULO III · GULA COMPLETADO", 24))
    var story := _label("Las ofrendas se hundieron, las almas fueron escuchadas y Cerbero dejó libre el umbral.", 18)
    story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    stack.add_child(story)
    stack.add_child(_label("Redención: %d     Rigor: %d" % [int(Game.progress["redencion"]), int(Game.progress["rigor"])], 20))
    stack.add_child(_label("El siguiente descenso lleva a Violencia; después aguarda Traición.", 17))
    var next := Button.new()
    next.text = "CONTINUAR A VIOLENCIA · CÍRCULO VII"
    next.custom_minimum_size = Vector2(320, 50)
    next.pressed.connect(func() -> void:
        Game.enter_violencia()
        Game.cross_threshold("res://scenes/Violencia.tscn"))
    stack.add_child(next)
    var menu := Button.new()
    menu.text = "VOLVER AL MENÚ PRINCIPAL"
    menu.custom_minimum_size = Vector2(320, 50)
    menu.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/MenuPrincipal.tscn"))
    stack.add_child(menu)
    next.grab_focus()

func _label(value: String, font_size: int) -> Label:
    var node := Label.new()
    node.text = value
    node.add_theme_font_size_override("font_size", font_size)
    node.add_theme_color_override("font_color", Color("#2d3927"))
    node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    return node
