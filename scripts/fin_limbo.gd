extends Control
## Fin jugable del primer capítulo, sin simular un segundo círculo inexistente.
func _ready() -> void:
	var bg: TextureRect = TextureRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.texture = load("res://assets/world/limbo_master.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(bg)
	var shade: ColorRect = ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.025, 0.030, 0.040, 0.82)
	add_child(shade)
	var panel: PanelContainer = PanelContainer.new()
	panel.position = Vector2(307, 123)
	panel.custom_minimum_size = Vector2(666, 469)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("#e7e4dc")
	style.border_color = Color("#9aa0a6")
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var stack: VBoxContainer = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 20)
	panel.add_child(stack)
	var header: Label = _label("INFERNO  ·  EL DESCENSO", 32)
	stack.add_child(header)
	stack.add_child(HSeparator.new())
	stack.add_child(_label("CAPÍTULO I — LIMBO COMPLETADO", 25))
	var summary: Label = _label("Los tres santuarios despertaron y las voces de los olvidados han sido escuchadas. La puerta del segundo círculo ha cedido.", 19)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(summary)
	stack.add_child(_label("Redención: %d       Rigor: %d" % [int(Game.progress["redencion"]), int(Game.progress["rigor"])], 22))
	var reading: String = "En tu viaje predominó la compasión." if int(Game.progress["redencion"]) > int(Game.progress["rigor"]) else "El juicio ha pesado sobre tu camino." if int(Game.progress["rigor"]) > int(Game.progress["redencion"]) else "Tu camino mantiene el equilibrio entre compasión y rigor."
	var outro: Label = _label(reading, 18)
	outro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(outro)
	var foot: Label = _label("PRÓXIMAMENTE: CÍRCULO II — LUJURIA", 16)
	stack.add_child(foot)
	var back: Button = Button.new()
	back.text = "VOLVER AL MENÚ PRINCIPAL"
	back.custom_minimum_size = Vector2(320, 49)
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/MenuPrincipal.tscn"))
	stack.add_child(back)
	back.grab_focus()

func _label(value: String, font_size: int) -> Label:
	var label_node: Label = Label.new()
	label_node.text = value
	label_node.add_theme_font_size_override("font_size", font_size)
	label_node.add_theme_color_override("font_color", Color("#30363c"))
	label_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label_node
