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
var dialogue_choices: VBoxContainer
var resume_button: Button
var pause_overlay: ColorRect
var dialogue_open: bool = false
var pause_open: bool = false
var dash_bar: ProgressBar
var chapter_title: Label
var chapter_subtitle: Label
var title_frame: PanelContainer
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
    p.mouse_filter = Control.MOUSE_FILTER_IGNORE
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

var objectives: PanelContainer
var objective_button: Button

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

    title_frame = _panel(root, Vector2(518, 17), Vector2(246, 64), true)
    var title_stack: VBoxContainer = VBoxContainer.new()
    title_stack.add_theme_constant_override("separation", 0)
    title_frame.add_child(title_stack)
    chapter_title = _label("I N F E R N O  ·  I", 13, Color("#545960"))
    chapter_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title_stack.add_child(chapter_title)
    chapter_subtitle = _label("L I M B O", 24, Color("#242c30"))
    chapter_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title_stack.add_child(chapter_subtitle)

    objectives = _panel(root, Vector2(19, 175), Vector2(292, 137), true)
    objectives.hide()
    objective_button = Button.new()
    objective_button.text = "OBJETIVOS · TAB"
    objective_button.custom_minimum_size = Vector2(172, 34)
    objective_button.position = Vector2(19, 133)
    objective_button.focus_mode = Control.FOCUS_NONE
    root.add_child(objective_button)
    objective_button.pressed.connect(_toggle_objectives)
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

    var map_panel: PanelContainer = _panel(root, Vector2(1102, 575), Vector2(160, 132))
    var map_v: VBoxContainer = VBoxContainer.new()
    map_v.add_theme_constant_override("separation", 0)
    map_panel.add_child(map_v)
    map_title = _label("✧  PLANO DEL LIMBO", 11, Color("#e1e3e3"))
    map_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    map_v.add_child(map_title)
    minimap = Control.new()
    minimap.set_script(load("res://scripts/minimap.gd"))
    minimap.custom_minimum_size = Vector2(130, 97)
    minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
    map_v.add_child(minimap)

    var control_panel: PanelContainer = _panel(root, Vector2(16, 661), Vector2(564, 47))
    control_text = _label("WASD MOVER   ESPACIO ESQUIVA / SALTO   E USAR   Q PISTA   ESC PAUSA", 12, Color("#d9dfe0"))
    control_panel.add_child(control_text)

    var dash_frame: PanelContainer = _panel(root, Vector2(902, 660), Vector2(177, 49))
    var dash_v: VBoxContainer = VBoxContainer.new()
    dash_frame.add_child(dash_v)
    dash_v.add_child(_label("ESQUIVA", 12, Color("#dfe4e7")))
    dash_bar = _progress()
    dash_bar.max_value = 1.0
    dash_bar.value = 1.0
    dash_v.add_child(dash_bar)

    boss_frame = _panel(root, Vector2(478, 16), Vector2(300, 56))
    var boss_v: VBoxContainer = VBoxContainer.new()
    boss_v.add_theme_constant_override("separation", 3)
    boss_frame.add_child(boss_v)
    boss_text = _label("MINOS", 15, Color("#ebe1ee"))
    boss_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    boss_text.clip_text = true
    boss_v.add_child(boss_text)
    boss_bar = _progress()
    boss_bar.max_value = 38.0
    boss_bar.value = 38.0
    boss_bar.custom_minimum_size = Vector2(260, 10)
    boss_bar.add_theme_stylebox_override("fill", _style(Color("#a56b9f"), Color("#d8adcf"), 2, 0))
    boss_v.add_child(boss_bar)
    boss_frame.visible = false

    nearby_frame = _panel(root, Vector2(390, 602), Vector2(500, 52), true)
    nearby_label = _label("E  ·  INTERACTUAR", 16, Color("#222a2e"))
    nearby_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    nearby_frame.add_child(nearby_label)
    nearby_frame.visible = false

    toast_frame = _panel(root, Vector2(390, 99), Vector2(500, 65))
    toast_frame.add_theme_stylebox_override("panel", _style(Color("#172027"), Color("#ac9d82"), 8, 10))
    toast_label = _label("", 18, Color("#fff7e5"))
    toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    toast_frame.add_child(toast_label)
    toast_frame.visible = false

    dialogue_overlay = ColorRect.new()
    dialogue_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    dialogue_overlay.color = Color(0.0, 0.0, 0.0, 0.27)
    dialogue_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    root.add_child(dialogue_overlay)
    var dialogue_margin := MarginContainer.new()
    dialogue_overlay.add_child(dialogue_margin)
    dialogue_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    dialogue_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
    dialogue_margin.add_theme_constant_override("margin_left", 180)
    dialogue_margin.add_theme_constant_override("margin_right", 180)
    dialogue_margin.add_theme_constant_override("margin_bottom", 72)
    var dialogue_dock := VBoxContainer.new()
    dialogue_dock.mouse_filter = Control.MOUSE_FILTER_IGNORE
    dialogue_dock.alignment = BoxContainer.ALIGNMENT_END
    dialogue_margin.add_child(dialogue_dock)
    dialogue_frame = _panel(dialogue_dock, Vector2.ZERO, Vector2(920, 0), true)
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
    dbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    dbox.add_theme_constant_override("separation", 7)
    dialogue_row.add_child(dbox)
    dialogue_title = _label("VIRGILIO", 22, Color("#343a3f"))
    dbox.add_child(dialogue_title)
    dbox.add_child(HSeparator.new())
    dialogue_text = _label("", 18, Color("#272b2b"))
    dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    dialogue_text.custom_minimum_size.y = 55.0
    dbox.add_child(dialogue_text)
    dialogue_choices = VBoxContainer.new()
    dialogue_choices.add_theme_constant_override("separation", 7)
    dbox.add_child(dialogue_choices)
    dialogue_overlay.visible = false

    pause_overlay = ColorRect.new()
    pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    pause_overlay.color = Color(0.0, 0.0, 0.0, 0.73)
    pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    root.add_child(pause_overlay)
    var pause_center := CenterContainer.new()
    pause_overlay.add_child(pause_center)
    pause_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    pause_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var pause_frame := _panel(pause_center, Vector2.ZERO, Vector2(486, 0), true)
    pause_frame.get_theme_stylebox("panel").set_content_margin_all(24)
    var pv: VBoxContainer = VBoxContainer.new()
    pv.add_theme_constant_override("separation", 16)
    pause_frame.add_child(pv)
    var pause_title := _label("PARTIDA EN PAUSA", 28, Color("#27313a"))
    pause_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    pv.add_child(pause_title)
    resume_button = _button("REANUDAR  ·  ESC")
    pv.add_child(resume_button)
    resume_button.pressed.connect(func() -> void: pause_requested.emit())
    var menu: Button = _button("GUARDAR Y VOLVER AL MENÚ")
    pv.add_child(menu)
    menu.pressed.connect(func() -> void:
        set_pause(false)
        exit_to_menu_requested.emit())
    var pause_note := _label("Las decisiones se guardan automáticamente.", 15, Color("#36444a"))
    pause_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    pv.add_child(pause_note)
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
    toast_frame.visible = not dialogue_open
    toast_remaining = duration

func show_dialogue(speaker: String, body: String, options: Array) -> void:
    dialogue_open = true
    red_bar.get_parent().hide()
    rig_bar.get_parent().hide()
    dialogue_overlay.visible = true
    toast_frame.visible = false
    nearby_frame.visible = false
    dialogue_title.text = speaker
    if current_circle == "lujuria" and speaker.contains("VIRGILIO"):
        dialogue_portrait.texture = _character_portrait("virgilio", Rect2(255, 0, 520, 520))
    elif current_circle == "lujuria" and speaker.contains("PAOLO"):
        dialogue_portrait.texture = _character_portrait("paolo", Rect2(260, 0, 520, 520))
    elif current_circle == "lujuria" and speaker.contains("FRANCESCA"):
        dialogue_portrait.texture = _character_portrait("francesca", Rect2(260, 0, 520, 520))
    elif current_circle == "gula" and speaker.contains("DARIA"):
        dialogue_portrait.texture = _gula_portrait("daria")
    elif current_circle == "gula" and speaker.contains("OLMO"):
        dialogue_portrait.texture = _gula_portrait("olmo")
    elif speaker.contains("VIRGILIO"):
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
    AudioManager.cue("alma" if speaker.contains("ALMA") else "sello")
    var index: int = 0
    for option in choices:
        var b: Button = _button(str(option))
        b.custom_minimum_size.y = 44.0
        dialogue_choices.add_child(b)
        var captured_index: int = index
        b.pressed.connect(func() -> void: _select(captured_index))
        if index == 0:
            b.grab_focus()
        index += 1

func _character_portrait(character: String, region: Rect2) -> Texture2D:
    var source: Texture2D = load("res://assets/lujuria/npcs/" + character + "_statue.png")
    var portrait: AtlasTexture = AtlasTexture.new()
    portrait.atlas = source
    portrait.region = region
    return portrait

func _gula_portrait(character: String) -> Texture2D:
    var portrait := AtlasTexture.new()
    portrait.atlas = load("res://assets/gula/npcs/" + character + ".png")
    portrait.region = Rect2(140, 0, 744, 800)
    return portrait

func _select(index: int) -> void:
    if not dialogue_open:
        return
    dialogue_open = false
    red_bar.get_parent().show()
    rig_bar.get_parent().show()
    dialogue_overlay.visible = false
    if toast_remaining > 0.0:
        toast_frame.visible = true
    option_selected.emit(index)

func set_pause(value: bool) -> void:
    AudioManager.cue("menu")
    pause_open = value
    pause_overlay.visible = value
    get_tree().paused = value
    if value:
        nearby_frame.visible = false
        resume_button.grab_focus()

func _exit_tree() -> void:
    if pause_open:
        get_tree().paused = false

func _input(event: InputEvent) -> void:
    if event is InputEventKey and (Game.crossing or ((pause_open or dialogue_open) and event.keycode == KEY_SPACE)):
        get_viewport().set_input_as_handled()

func _toggle_objectives() -> void:
    if not pause_open and not dialogue_open:
        objectives.visible = not objectives.visible
        objective_button.text = "OCULTAR OBJETIVOS" if objectives.visible else "OBJETIVOS · TAB"

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
    if ke.keycode == KEY_TAB:
        _toggle_objectives()
        get_viewport().set_input_as_handled()
    elif ke.keycode == KEY_ESCAPE:
        pause_requested.emit()
        get_viewport().set_input_as_handled()

# Lujuria shares precisely the same parchment HUD, portraits and moral dialogue frame.
func configure_chapter(circle: String, player_node: Node2D) -> void:
    current_circle = circle
    AudioManager.enter(circle)
    set_player(player_node)
    minimap.mode = circle
    if circle in ["lujuria", "gula", "violencia", "traicion"]:
        title_frame.position = Vector2(825, 17)
        title_frame.custom_minimum_size = Vector2(180, 46)
        title_frame.size = Vector2(180, 46)
        chapter_title.visible = false
        chapter_subtitle.text = "II · LUJURIA" if circle == "lujuria" else "III · GULA" if circle == "gula" else "VII · VIOLENCIA" if circle == "violencia" else "IX · TRAICIÓN"
        chapter_subtitle.add_theme_font_size_override("font_size", 17)
        map_title.text = "✧  PLANO DE LUJURIA" if circle == "lujuria" else "✧  PLANO DE GULA" if circle == "gula" else "✧  PLANO DE VIOLENCIA" if circle == "violencia" else "✧  PLANO DE COCITO"
        control_text.text = "WASD MOVER   ESPACIO ESQUIVA   J GOLPE   K VERSO   E HABLAR   Q PISTA   ESC PAUSA"
        red_bar.max_value = 9.0
        rig_bar.max_value = 9.0
    else:
        title_frame.position = Vector2(518, 17)
        title_frame.custom_minimum_size = Vector2(246, 64)
        title_frame.size = Vector2(246, 64)
        chapter_title.visible = true
        chapter_title.text = "I N F E R N O  ·  I"
        chapter_subtitle.text = "L I M B O"
        chapter_subtitle.add_theme_font_size_override("font_size", 24)
        map_title.text = "✧  PLANO DEL LIMBO"
        control_text.text = "WASD MOVER   ESPACIO ESQUIVA / SALTO   E USAR   Q PISTA   ESC PAUSA"
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

func set_gula_state(data: Dictionary, offerings_count: int, souls: int, boss_down: bool) -> void:
    red_bar.max_value = maxf(9.0, float(data.get("redencion", 0)))
    rig_bar.max_value = maxf(9.0, float(data.get("rigor", 0)))
    red_bar.value = int(data.get("redencion", 0))
    rig_bar.value = int(data.get("rigor", 0))
    shrine_label.text = "◆  Ofrendas hundidas: %d / 2" % offerings_count
    soul_label.text = "◆  Almas escuchadas: %d / 2" % souls
    gate_label.text = "✦  Cerbero vencido · salida abierta" if boss_down else "○  Cerbero protege el umbral"
    minimap.altar_step = offerings_count
    minimap.soul_count = souls
    minimap.door_open = boss_down

func set_traicion_state(data: Dictionary, seals_count: int, souls: int, boss_down: bool) -> void:
    red_bar.max_value = maxf(9.0, float(data.get("redencion", 0)))
    rig_bar.max_value = maxf(9.0, float(data.get("rigor", 0)))
    red_bar.value = int(data.get("redencion", 0))
    rig_bar.value = int(data.get("rigor", 0))
    shrine_label.text = "◆  Juramentos rotos: %d / 2" % seals_count
    soul_label.text = "◆  Almas escuchadas: %d / 2" % souls
    gate_label.text = "✦  Lucifer vencido · salida abierta" if boss_down else "○  Lucifer guarda el centro"
    minimap.altar_step = seals_count
    minimap.soul_count = souls
    minimap.door_open = boss_down

func set_violencia_state(data: Dictionary, seals_count: int, souls: int, boss_down: bool) -> void:
    red_bar.max_value = maxf(9.0, float(data.get("redencion", 0)))
    rig_bar.max_value = maxf(9.0, float(data.get("rigor", 0)))
    red_bar.value = int(data.get("redencion", 0))
    rig_bar.value = int(data.get("rigor", 0))
    shrine_label.text = "◆  Votos encendidos: %d / 3" % seals_count
    soul_label.text = "◆  Almas escuchadas: %d / 2" % souls
    gate_label.text = "✦  Minotauro vencido · salida abierta" if boss_down else "◌  Minotauro guarda el umbral"
    minimap.altar_step = seals_count
    minimap.soul_count = souls
    minimap.door_open = boss_down

func set_boss_health(current: int, maximum: int) -> void:
    boss_frame.visible = current > 0
    if current_circle == "violencia":
        toast_frame.position = Vector2(390, 99)
    boss_bar.max_value = maxf(1.0, float(maximum))
    boss_bar.value = maxf(0.0, float(current))

func hide_boss() -> void:
    boss_frame.visible = false
    toast_frame.position = Vector2(390, 99)
