extends CanvasLayer
## HUD propio del proyecto: vivo, no está impreso en el fondo.
signal option_selected(index: int)
signal pause_requested
signal exit_to_menu_requested

var root: Control
var heart_label: Label
var red_bar: ProgressBar
var rig_bar: ProgressBar
var shrine_label: Label
var soul_label: Label
var gate_label: Label
var nearby_label: Label
var nearby_frame: PanelContainer
var toast_label: Label
var toast_frame: PanelContainer
var toast_remaining: float = 0.0
var minimap: Variant
var dialogue_frame: PanelContainer
var dialogue_overlay: ColorRect
var dialogue_portrait: TextureRect
var dialogue_title: Label
var dialogue_text: Label
var dialogue_choices: HBoxContainer
var pause_overlay: ColorRect
var dialogue_open: bool = false
var pause_open: bool = false
var dash_bar: ProgressBar
var chapter_title: Label
var chapter_subtitle: Label
var map_title: Label
var control_text: Label
var boss_frame: PanelContainer
var boss_text: Label
var boss_bar: ProgressBar
var current_circle: String = "limbo"

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _build()

func _process(delta: float) -> void:
    if toast_remaining > 0.0 and not pause_open:
        toast_remaining -= delta
        if toast_remaining <= 0.0:
            toast_frame.visible = false

func _style(background: Color, border: Color, radius: int = 9, margin: int = 12) -> StyleBoxFlat:
    var box: StyleBoxFlat = StyleBoxFlat.new()
    box.bg_color = background
    box.border_color = border
    box.set_border_width_all(2)
    box.set_corner_radius_all(radius)
    box.set_content_margin_all(margin)
    return box

func _label(value: String, font_size: int, color: Color) -> Label:
    var l: Label = Label.new()
    l.text = value
    l.add_theme_font_size_override("font_size", font_size)
    l.add_theme_color_override("font_color", color)
    return l

func _panel(parent: Node, pos: Vector2, dimensions: Vector2, parchment: bool = false) -> PanelContainer:
    var p: PanelContainer = PanelContainer.new()
    p.position = pos
    p.size = dimensions
    p.custom_minimum_size = dimensions
    if parchment:
        p.add_theme_stylebox_override("panel", _style(Color(0.92, 0.90, 0.86, 0.98), Color("#66717a"), 9, 13))
    else:
        p.add_theme_stylebox_override("panel", _style(Color(0.055, 0.067, 0.083, 0.83), Color(0.59, 0.64, 0.67, 0.77), 9, 11))
    parent.add_child(p)
    return p

func _button(text_value: String) -> Button:
    var b: Button = Button.new()
    b.text = text_value
    b.custom_minimum_size = Vector2(205, 47)
    b.add_theme_font_size_override("font_size", 16)
    b.add_theme_color_override("font_color", Color("#242930"))
    b.add_theme_stylebox_override("normal", _style(Color("#eceae3"), Color("#7a858a"), 7, 7))
    b.add_theme_stylebox_override("hover", _style(Color("#d9e0e2"), Color("#435560"), 7, 7))
    b.add_theme_stylebox_override("pressed", _style(Color("#b9c8ce"), Color("#435560"), 7, 7))
    b.add_theme_stylebox_override("focus", _style(Color(0.7, 0.77, 0.82, 0.22), Color("#b2c7d2"), 7, 7))
    return b

func _progress() -> ProgressBar:
    var bar: ProgressBar = ProgressBar.new()
    bar.min_value = 0
    bar.max_value = 3
    bar.value = 0
    bar.show_percentage = false
    bar.custom_minimum_size = Vector2(133, 11)
    bar.add_theme_stylebox_override("background", _style(Color("#171d23"), Color("#6f777a"), 2, 0))
    bar.add_theme_stylebox_override("fill", _style(Color("#b4c2cb"), Color("#b4c2cb"), 2, 0))
    return bar

func _build() -> void:
    root = Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(root)

    var portrait_frame: PanelContainer = _panel(root, Vector2(17, 17), Vector2(104, 104))
    portrait_frame.add_theme_stylebox_override("panel", _style(Color("#11171c"), Color("#b7b4ae"), 54, 5))
    var portrait: TextureRect = TextureRect.new()
    portrait.texture = load("res://assets/ui/retrato_dante.png")
    portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    portrait_frame.add_child(portrait)

    var name_frame: PanelContainer = _panel(root, Vector2(123, 18), Vector2(290, 108))
    var vitals: VBoxContainer = VBoxContainer.new()
    vitals.add_theme_constant_override("separation", 3)
    name_frame.add_child(vitals)
    vitals.add_child(_label("D A N T E   /   EL PEREGRINO", 16, Color("#e7e2d8")))
    heart_label = _label("♥  ♥  ♥", 21, Color("#e7a5a0"))
    vitals.add_child(heart_label)
    var red_row: HBoxContainer = HBoxContainer.new()
    red_row.add_child(_label("REDENCIÓN", 13, Color("#d8dedf")))
    red_bar = _progress()
    red_bar.max_value = 2.0
    red_row.add_child(red_bar)
    vitals.add_child(red_row)
    var rig_row: HBoxContainer = HBoxContainer.new()
    rig_row.add_child(_label("RIGOR         ", 13, Color("#c5d0d7")))
    rig_bar = _progress()
    rig_bar.max_value = 2.0
    rig_row.add_child(rig_bar)
    vitals.add_child(rig_row)

    var title_frame: PanelContainer = _panel(root, Vector2(518, 17), Vector2(246, 64), true)
    var title_stack: VBoxContainer = VBoxContainer.new()
    title_stack.add_theme_constant_override("separation", 0)
    title_frame.add_child(title_stack)
    chapter_title = _label("I N F E R N O  ·  I", 13, Color("#545960"))
    chapter_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title_stack.add_child(chapter_title)
    chapter_subtitle = _label("L I M B O", 24, Color("#242c30"))
    chapter_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title_stack.add_child(chapter_subtitle)

    var objectives: PanelContainer = _panel(root, Vector2(19, 143), Vector2(292, 137), true)
    var obj_v: VBoxContainer = VBoxContainer.new()
    obj_v.add_theme_constant_override("separation", 4)
    objectives.add_child(obj_v)
    obj_v.add_child(_label("✦  OBJETIVO ACTUAL", 16, Color("#262d31")))
    obj_v.add_child(HSeparator.new())
    shrine_label = _label("◇  Santuario 0/3", 16, Color("#323a3d"))
    soul_label = _label("◇  Almas 0/2", 16, Color("#323a3d"))
    gate_label = _label("○  Umbral sellado", 14, Color("#59666c"))
    obj_v.add_child(shrine_label)
    obj_v.add_child(soul_label)
    obj_v.add_child(gate_label)

    var map_panel: PanelContainer = _panel(root, Vector2(1055, 17), Vector2(205, 178))
    var map_v: VBoxContainer = VBoxContainer.new()
    map_v.add_theme_constant_override("separation", 0)
    map_panel.add_child(map_v)
    map_title = _label("✧  PLANO DEL LIMBO", 14, Color("#e1e3e3"))
    map_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    map_v.add_child(map_title)
    minimap = Control.new()
    minimap.set_script(load("res://scripts/minimap.gd"))
    minimap.custom_minimum_size = Vector2(185, 138)
    minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
    map_v.add_child(minimap)

    var control_panel: PanelContainer = _panel(root, Vector2(16, 661), Vector2(564, 47))
    control_text = _label("WASD  MOVER    ESPACIO  ESQUIVA    E  INTERACTUAR    Q  PISTA    ESC  PAUSA", 13, Color("#d9dfe0"))
    control_panel.add_child(control_text)

    var dash_frame: PanelContainer = _panel(root, Vector2(1083, 660), Vector2(177, 49))
    var dash_v: VBoxContainer = VBoxContainer.new()
    dash_frame.add_child(dash_v)
    dash_v.add_child(_label("ESQUIVA", 12, Color("#dfe4e7")))
    dash_bar = _progress()
    dash_bar.max_value = 1.0
    dash_bar.value = 1.0
    dash_v.add_child(dash_bar)

    boss_frame = _panel(root, Vector2(477, 90), Vector2(328, 72))
    var boss_v: VBoxContainer = VBoxContainer.new()
    boss_v.add_theme_constant_override("separation", 5)
    boss_frame.add_child(boss_v)
    boss_text = _label("MINOS · GUARDIÁN DEL CÍRCULO II", 14, Color("#ebe1ee"))
    boss_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    boss_v.add_child(boss_text)
    boss_bar = _progress()
    boss_bar.max_value = 38.0
    boss_bar.value = 38.0
    boss_bar.custom_minimum_size = Vector2(294, 14)
    boss_v.add_child(boss_bar)
    boss_frame.visible = false

    nearby_frame = _panel(root, Vector2(431, 578), Vector2(418, 55), true)
    nearby_label = _label("E  ·  INTERACTUAR", 16, Color("#222a2e"))
    nearby_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    nearby_frame.add_child(nearby_label)
    nearby_frame.visible = false

    toast_frame = _panel(root, Vector2(420, 99), Vector2(444, 65))
    toast_label = _label("", 16, Color("#f0eae2"))
    toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    toast_frame.add_child(toast_label)
    toast_frame.visible = false

    dialogue_overlay = ColorRect.new()
    dialogue_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    dialogue_overlay.color = Color(0.0, 0.0, 0.0, 0.27)
    dialogue_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    root.add_child(dialogue_overlay)
    dialogue_frame = _panel(dialogue_overlay, Vector2(145, 471), Vector2(990, 223), true)
    var dialogue_row: HBoxContainer = HBoxContainer.new()
    dialogue_row.add_theme_constant_override("separation", 15)
    dialogue_frame.add_child(dialogue_row)
    dialogue_portrait = TextureRect.new()
    dialogue_portrait.texture = load("res://assets/ui/retrato_virgilio.png")
    dialogue_portrait.custom_minimum_size = Vector2(125, 125)
    dialogue_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    dialogue_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    dialogue_row.add_child(dialogue_portrait)
    var dbox: VBoxContainer = VBoxContainer.new()
    dbox.custom_minimum_size = Vector2(794, 0)
    dbox.add_theme_constant_override("separation", 7)
    dialogue_row.add_child(dbox)
    dialogue_title = _label("VIRGILIO", 22, Color("#343a3f"))
    dbox.add_child(dialogue_title)
    dbox.add_child(HSeparator.new())
    dialogue_text = _label("", 18, Color("#272b2b"))
    dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    dialogue_text.custom_minimum_size = Vector2(790, 77)
    dbox.add_child(dialogue_text)
    dialogue_choices = HBoxContainer.new()
    dialogue_choices.add_theme_constant_override("separation", 18)
    dbox.add_child(dialogue_choices)
    dialogue_overlay.visible = false

    pause_overlay = ColorRect.new()
    pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    pause_overlay.color = Color(0.0, 0.0, 0.0, 0.73)
    pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    root.add_child(pause_overlay)
    var pause_frame: PanelContainer = _panel(pause_overlay, Vector2(397, 169), Vector2(486, 390), true)
    var pv: VBoxContainer = VBoxContainer.new()
    pv.add_theme_constant_override("separation", 23)
    pause_frame.add_child(pv)
    pv.add_child(_label("INFERNO  ·  EL DESCENSO", 27, Color("#27313a")))
    pv.add_child(_label("EL VIAJE SE DETIENE", 17, Color("#52616b")))
    var resume: Button = _button("REANUDAR  ·  ESC")
    pv.add_child(resume)
    resume.pressed.connect(func() -> void: pause_requested.emit())
    var menu: Button = _button("GUARDAR Y VOLVER AL MENÚ")
    pv.add_child(menu)
    menu.pressed.connect(func() -> void: exit_to_menu_requested.emit())
    pv.add_child(_label("Las decisiones morales se guardan automáticamente.", 15, Color("#4f5c61")))
    pause_overlay.visible = false

func set_player(player_node: Node2D) -> void:
    minimap.player = player_node

func set_state(data: Dictionary, souls: int, open_gate: bool) -> void:
    heart_label.text = "♥  ♥  ♥"
    red_bar.max_value = 2.0
    rig_bar.max_value = 2.0
    red_bar.value = int(data.get("redencion", 0))
    rig_bar.value = int(data.get("rigor", 0))
    shrine_label.text = "◆  Santuarios: %d / 3" % int(data.get("shrine_step", 0))
    soul_label.text = "◆  Almas escuchadas: %d / 2" % souls
    gate_label.text = "✦  Umbral abierto" if open_gate else "○  Umbral sellado"
    minimap.altar_step = int(data.get("shrine_step", 0))
    minimap.soul_count = souls
    minimap.door_open = open_gate

func set_dash_fraction(value: float) -> void:
    dash_bar.value = value

func set_nearby(label_text: String) -> void:
    nearby_frame.visible = not label_text.is_empty() and not dialogue_open and not pause_open
    nearby_label.text = "E  ·  " + label_text

func toast(message: String, duration: float = 3.5) -> void:
    toast_label.text = message
    toast_frame.visible = true
    toast_remaining = duration

func show_dialogue(speaker: String, body: String, options: Array) -> void:
    dialogue_open = true
    dialogue_overlay.visible = true
    nearby_frame.visible = false
    dialogue_title.text = speaker
    if speaker.contains("VIRGILIO"):
        dialogue_portrait.texture = load("res://assets/ui/retrato_virgilio.png")
    elif speaker.contains("ALMA") or speaker.contains("PAOLO") or speaker.contains("FRANCESCA"):
        dialogue_portrait.texture = load("res://assets/ui/retrato_alma.png")
    else:
        dialogue_portrait.texture = load("res://assets/ui/retrato_piedra.png")
    dialogue_text.text = body
    for child in dialogue_choices.get_children():
        dialogue_choices.remove_child(child)
        child.queue_free()
    var choices: Array = options.duplicate()
    if choices.is_empty():
        choices.append("Continuar")
    var index: int = 0
    for option in choices:
        var b: Button = _button(("%d. " % (index + 1)) + str(option))
        b.custom_minimum_size = Vector2(270 if choices.size() == 1 else 352, 47)
        dialogue_choices.add_child(b)
        var captured_index: int = index
        b.pressed.connect(func() -> void: _select(captured_index))
        if index == 0:
            b.grab_focus()
        index += 1

func _select(index: int) -> void:
    if not dialogue_open:
        return
    dialogue_open = false
    dialogue_overlay.visible = false
    option_selected.emit(index)

func set_pause(value: bool) -> void:
    pause_open = value
    pause_overlay.visible = value
    if value:
        nearby_frame.visible = false

func _unhandled_key_input(event: InputEvent) -> void:
    var ke: InputEventKey = event as InputEventKey
    if ke == null or not ke.pressed or ke.echo:
        return
    if pause_open:
        if ke.keycode == KEY_ESCAPE:
            pause_requested.emit()
            get_viewport().set_input_as_handled()
        return
    if dialogue_open:
        if ke.keycode == KEY_1 or ke.keycode == KEY_KP_1:
            _select(0)
            get_viewport().set_input_as_handled()
        elif (ke.keycode == KEY_2 or ke.keycode == KEY_KP_2) and dialogue_choices.get_child_count() > 1:
            _select(1)
            get_viewport().set_input_as_handled()
        return
    if ke.keycode == KEY_ESCAPE:
        pause_requested.emit()
        get_viewport().set_input_as_handled()

# Lujuria shares precisely the same parchment HUD, portraits and moral dialogue frame.
func configure_chapter(circle: String, player_node: Node2D) -> void:
    current_circle = circle
    set_player(player_node)
    minimap.mode = circle
    if circle == "lujuria":
        chapter_title.text = "I N F E R N O  ·  I I"
        chapter_subtitle.text = "L U J U R I A"
        map_title.text = "✧  PLANO DE LUJURIA"
        control_text.text = "WASD MOVER   ESPACIO ESQUIVA   J GOLPE   K VERSO   E HABLAR   Q PISTA   ESC PAUSA"
        red_bar.max_value = 9.0
        rig_bar.max_value = 9.0
    else:
        chapter_title.text = "I N F E R N O  ·  I"
        chapter_subtitle.text = "L I M B O"
        map_title.text = "✧  PLANO DEL LIMBO"
        control_text.text = "WASD  MOVER    ESPACIO  ESQUIVA    E  INTERACTUAR    Q  PISTA    ESC  PAUSA"
        red_bar.max_value = 2.0
        rig_bar.max_value = 2.0
    minimap.queue_redraw()

func set_health(current: int, maximum: int) -> void:
    heart_label.text = "♥ ".repeat(maxi(0, current)) + "♡ ".repeat(maxi(0, maximum - current))

func set_lujuria_state(data: Dictionary, seals_count: int, souls: int, boss_down: bool) -> void:
    red_bar.max_value = maxf(9.0, float(data.get("redencion", 0)))
    rig_bar.max_value = maxf(9.0, float(data.get("rigor", 0)))
    red_bar.value = int(data.get("redencion", 0))
    rig_bar.value = int(data.get("rigor", 0))
    shrine_label.text = "◆  Sellos del viento: %d / 3" % seals_count
    soul_label.text = "◆  Almas escuchadas: %d / 2" % souls
    gate_label.text = "✦  Minos vencido · salida abierta" if boss_down else "○  Minos protege el umbral"
    minimap.altar_step = seals_count
    minimap.soul_count = souls
    minimap.door_open = boss_down

func set_boss_health(current: int, maximum: int) -> void:
    boss_frame.visible = current > 0
    toast_frame.position = Vector2(420, 174) if current > 0 else Vector2(420, 99)
    boss_bar.max_value = maxf(1.0, float(maximum))
    boss_bar.value = maxf(0.0, float(current))

func hide_boss() -> void:
    boss_frame.visible = false
    toast_frame.position = Vector2(420, 99)
