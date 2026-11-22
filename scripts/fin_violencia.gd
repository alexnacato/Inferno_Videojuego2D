extends Control
func _ready() -> void:
    var background := TextureRect.new()
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background.texture = load("res://assets/violencia/violencia_mapa.png")
    background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    add_child(background)
    var shade := ColorRect.new()
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.color = Color(0.04,0.02,0.03,0.84)
    add_child(shade)
    var panel := PanelContainer.new()
    panel.position = Vector2(310,65)
    panel.size = Vector2(660,590)
    var style := StyleBoxFlat.new()
    style.bg_color = Color("e6ded2")
    style.border_color = Color("7a0c1c")
    style.set_border_width_all(3)
    style.set_corner_radius_all(8)
    style.set_content_margin_all(25)
    panel.add_theme_stylebox_override("panel",style)
    add_child(panel)
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation",17)
    panel.add_child(stack)
    _label(stack,"CÍRCULO VII COMPLETADO",18,Color("7a0c1c"))
    _label(stack,"V I O L E N C I A",35,Color("30292b"))
    stack.add_child(HSeparator.new())
    _label(stack,"El Minotauro ha caído. El río sigue su curso, pero las voces que escuchaste ya no son silencio.",20,Color("453c3d"))
    var red := int(Game.progress.get("redencion",0))
    var rig := int(Game.progress.get("rigor",0))
    var path := "LA COMPASIÓN GUÍA TU FUERZA" if red > rig else "EL JUICIO GUÍA TU FUERZA" if rig > red else "TU BALANZA PERMANECE ABIERTA"
    _label(stack,path,19,Color("7a0c1c"))
    _label(stack,"Redención: %d     ·     Rigor: %d" % [red,rig],19,Color("453c3d"))
    _label(stack,"ESQUIVA EXTENDIDA OBTENIDA\nMás distancia · mayor protección · menor recarga",19,Color("51473d"))
    _label(stack,"El hielo de Cocito espera en Traición, el último círculo disponible.",17,Color("74645f"))
    var next := Button.new()
    next.text = "CONTINUAR A TRAICIÓN · CÍRCULO IX"
    next.custom_minimum_size = Vector2(0,48)
    stack.add_child(next)
    next.pressed.connect(func() -> void:
        Game.enter_traicion()
        get_tree().change_scene_to_file("res://scenes/Traicion.tscn"))
    var button := Button.new()
    button.text = "VOLVER AL MENÚ PRINCIPAL"
    button.custom_minimum_size = Vector2(0,48)
    stack.add_child(button)
    button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/MenuPrincipal.tscn"))
    next.grab_focus()
func _label(parent: Node, value: String, font_size: int, color: Color) -> void:
    var label := Label.new()
    label.text = value
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size",font_size)
    label.add_theme_color_override("font_color",color)
    parent.add_child(label)
