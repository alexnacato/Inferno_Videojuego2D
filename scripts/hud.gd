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
var dialogue_text: Variant
var dialogue_choices: VBoxContainer
var resume_button: Button
var pause_overlay: ColorRect
var dialogue_open: bool = false
var pause_open: bool = false
var dash_bar: ProgressBar
var chapter_subtitle: Label
var title_frame: PanelContainer
var map_title: Label
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
    p.theme_type_variation = &"PanelContainer" if parchment else &"HudPanel"
    parent.add_child(p)
    return p

func _button(text_value: String) -> Button:
    var b: Button = preload("res://scripts/inferno_button.gd").new()
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
    bar.custom_minimum_size = Vector2(98, 7)
    bar.add_theme_stylebox_override("background", _style(Color("#171d23"), Color("#6f777a"), 2, 0))
    bar.add_theme_stylebox_override("fill", _style(Color("#b4c2cb"), Color("#b4c2cb"), 2, 0))
    return bar

var objectives: PanelContainer
var objective_button: Button
var relic_status: Label
var player_panel: PanelContainer
var player_toggle: Button
var player_details: VBoxContainer
var life_detail: Label
var red_summary: Label
var rig_summary: Label
var red_detail: Label
var rig_detail: Label
var controls_row: HFlowContainer

# Place a container on one edge of the logical game viewport.
func _dock(control: Control, preset: int, shift: Vector2) -> void:
    control.reset_size()
    control.set_anchors_and_offsets_preset(preset, Control.PRESET_MODE_MINSIZE)
    control.offset_left += shift.x
    control.offset_right += shift.x
    control.offset_top += shift.y
    control.offset_bottom += shift.y

func _build_player() -> void:
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation", 6)
    stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(stack)
    _dock(stack, Control.PRESET_TOP_LEFT, Vector2(16, 16))

    player_panel = _panel(stack, Vector2.ZERO, Vector2(0, 0), true)
    var inner := VBoxContainer.new()
    inner.add_theme_constant_override("separation", 5)
    player_panel.add_child(inner)
    var line := HBoxContainer.new()
    line.add_theme_constant_override("separation", 7)
    inner.add_child(line)

    var avatar := PanelContainer.new()
    avatar.custom_minimum_size = Vector2(32, 32)
    avatar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    avatar.add_theme_stylebox_override("panel", _style(Color("#232c34"), Color("#74848b"), 16, 1))
    line.add_child(avatar)
    var portrait := TextureRect.new()
    portrait.texture = preload("res://assets/ui/retrato_dante.png")
    portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
    avatar.add_child(portrait)

    line.add_child(_label("Dante", 15, Color("#25313a")))
    heart_label = _label("", 15, Color("#8b3747"))
    line.add_child(heart_label)
    red_summary = _label("Red. 0", 12, Color("#315851"))
    rig_summary = _label("Rig. 0", 12, Color("#68455b"))
    line.add_child(red_summary)
    line.add_child(rig_summary)
    player_toggle = _button("H  ▾")
    player_toggle.custom_minimum_size = Vector2.ZERO
    player_toggle.add_theme_font_size_override("font_size", 12)
    player_toggle.focus_mode = Control.FOCUS_NONE
    player_toggle.tooltip_text = "Mostrar u ocultar el estado de Dante (H)"
    player_toggle.pressed.connect(_toggle_player_details)
    line.add_child(player_toggle)

    player_details = VBoxContainer.new()
    player_details.add_theme_constant_override("separation", 4)
    inner.add_child(player_details)
    player_details.add_child(HSeparator.new())
    life_detail = _label("", 13, Color("#25313a"))
    player_details.add_child(life_detail)
    red_bar = _progress()
    rig_bar = _progress()
    red_detail = _stat_row("Redención", red_bar, Color("#416e65"))
    rig_detail = _stat_row("Rigor", rig_bar, Color("#79546c"))
    red_bar.value_changed.connect(_refresh_morality)
    rig_bar.value_changed.connect(_refresh_morality)
    set_health(3, 3)
    _refresh_morality(0.0)
    player_details.hide()

    objective_button = _button("OBJETIVOS · TAB")
    objective_button.custom_minimum_size = Vector2(0, 32)
    objective_button.add_theme_font_size_override("font_size", 12)
    objective_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    objective_button.focus_mode = Control.FOCUS_NONE
    stack.add_child(objective_button)
    objective_button.pressed.connect(_toggle_objectives)
    objectives = _panel(stack, Vector2.ZERO, Vector2.ZERO, true)
    objectives.hide()
    var objectives_list := VBoxContainer.new()
    objectives_list.add_theme_constant_override("separation", 4)
    objectives.add_child(objectives_list)
    objectives_list.add_child(_label("OBJETIVO ACTUAL", 14, Color("#26313a")))
    objectives_list.add_child(HSeparator.new())
    shrine_label = _label("", 14, Color("#26313a"))
    soul_label = _label("", 14, Color("#26313a"))
    gate_label = _label("", 13, Color("#48585f"))
    relic_status = _label("", 13, Color("#795627"))
    for item in [shrine_label, soul_label, gate_label, relic_status]:
        objectives_list.add_child(item)

func _stat_row(label: String, bar: ProgressBar, tint: Color) -> Label:
    var line := HBoxContainer.new()
    line.add_theme_constant_override("separation", 8)
    player_details.add_child(line)
    var title := _label(label, 13, Color("#25313a"))
    title.custom_minimum_size.x = 79
    line.add_child(title)
    bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    bar.add_theme_stylebox_override("fill", _style(tint, tint, 3, 0))
    line.add_child(bar)
    var count := _label("0", 13, Color("#25313a"))
    line.add_child(count)
    return count

func _refresh_morality(_value: float) -> void:
    red_summary.text = "Red. %d" % int(red_bar.value)
    rig_summary.text = "Rig. %d" % int(rig_bar.value)
    red_detail.text = str(int(red_bar.value))
    rig_detail.text = str(int(rig_bar.value))

func _toggle_player_details() -> void:
    if pause_open or dialogue_open or Game.crossing:
        return
    player_details.visible = not player_details.visible
    player_toggle.text = "H  ▴" if player_details.visible else "H  ▾"

func _set_control_legend(circle: String) -> void:
    for child in controls_row.get_children():
        controls_row.remove_child(child)
        child.queue_free()
    var entries := [["WASD", "Mover"], ["Espacio", "Esquivar / saltar" if circle == "limbo" else "Esquivar"]]
    if circle != "limbo":
        entries.append_array([["J", "Golpe"], ["K", "Verso"]])
    entries.append_array([["E", "Interactuar"], ["Q", "Pista"], ["Esc", "Pausa"]])
    for entry in entries:
        var group := HBoxContainer.new()
        group.add_theme_constant_override("separation", 5)
        group.mouse_filter = Control.MOUSE_FILTER_IGNORE
        controls_row.add_child(group)
        var key := PanelContainer.new()
        key.theme_type_variation = &"Keycap"
        key.mouse_filter = Control.MOUSE_FILTER_IGNORE
        group.add_child(key)
        key.add_child(_label(entry[0], 11, Color("#26313a")))
        group.add_child(_label(entry[1], 12, Color("#f0efea")))

func _build() -> void:
    root = Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(root)

    _build_player()

    title_frame = _panel(root, Vector2.ZERO, Vector2(0, 26), true)
    title_frame.theme_type_variation = &"CircleBadge"
    chapter_subtitle = _label("I · LIMBO", 13, Color("#25313a"))
    chapter_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title_frame.add_child(chapter_subtitle)
    _dock(title_frame, Control.PRESET_TOP_RIGHT, Vector2(-16, 16))

    var map_panel: PanelContainer = _panel(root, Vector2.ZERO, Vector2(151, 0))
    map_panel.add_theme_stylebox_override("panel", _style(Color("#1f1b18"), Color("#b89052"), 5, 9))
    var map_v: VBoxContainer = VBoxContainer.new()
    map_v.add_theme_constant_override("separation", 0)
    map_panel.add_child(map_v)
    var ornament := _label("◆ ───── ✦ ───── ◆", 11, Color("#d8b476"))
    ornament.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    map_v.add_child(ornament)
    map_title = _label("✧  PLANO DEL LIMBO", 11, Color("#e1e3e3"))
    map_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    map_v.add_child(map_title)
    minimap = Control.new()
    minimap.set_script(load("res://scripts/minimap.gd"))
    minimap.custom_minimum_size = Vector2(130, 97)
    minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
    map_v.add_child(minimap)
    _dock(map_panel, Control.PRESET_BOTTOM_RIGHT, Vector2(-16, -14))

    var control_panel := _panel(root, Vector2.ZERO, Vector2.ZERO)
    control_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
    control_panel.anchor_right = 0.54
    control_panel.offset_left = 16
    control_panel.offset_right = 0
    control_panel.offset_top = -48
    control_panel.offset_bottom = -14
    control_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
    var control_margin := VBoxContainer.new()
    control_panel.add_child(control_margin)
    controls_row = HFlowContainer.new()
    controls_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    controls_row.add_theme_constant_override("h_separation", 13)
    controls_row.add_theme_constant_override("v_separation", 5)
    control_margin.add_child(controls_row)
    _set_control_legend("limbo")

    var dash_frame := _panel(root, Vector2.ZERO, Vector2(140, 0))
    var dash_v: VBoxContainer = VBoxContainer.new()
    dash_frame.add_child(dash_v)
    dash_v.add_child(_label("ESQUIVA", 12, Color("#dfe4e7")))
    dash_bar = _progress()
    dash_bar.max_value = 1.0
    dash_bar.value = 1.0
    dash_v.add_child(dash_bar)
    _dock(dash_frame, Control.PRESET_BOTTOM_RIGHT, Vector2(-176, -14))

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
    _dock(boss_frame, Control.PRESET_CENTER_TOP, Vector2(0, 16))
    boss_frame.visible = false

    nearby_frame = _panel(root, Vector2(390, 602), Vector2(500, 52), true)
    nearby_label = _label("E  ·  INTERACTUAR", 16, Color("#222a2e"))
    nearby_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    nearby_frame.add_child(nearby_label)
    _dock(nearby_frame, Control.PRESET_CENTER_BOTTOM, Vector2(0, -67))
    nearby_frame.visible = false

    toast_frame = _panel(root, Vector2(390, 99), Vector2(500, 65))
    toast_frame.add_theme_stylebox_override("panel", _style(Color("#172027"), Color("#ac9d82"), 8, 10))
    toast_label = _label("", 18, Color("#fff7e5"))
    toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    toast_frame.add_child(toast_label)
    _dock(toast_frame, Control.PRESET_CENTER_TOP, Vector2(0, 84))
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
    dialogue_frame = _panel(dialogue_dock, Vector2.ZERO, Vector2(0, 0), true)
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
    dialogue_text = preload("res://scripts/ink_text.gd").new()
    dialogue_text.add_theme_font_size_override("font_size", 18)
    dialogue_text.add_theme_color_override("font_color", Color("#272b2b"))
    dialogue_text.revealed.connect(_reveal_choices)
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
    var pv: VBoxContainer = VBoxContainer.new()
    pv.add_theme_constant_override("separation", 16)
    pause_frame.add_child(pv)
    var pause_title := _label("PARTIDA EN PAUSA", 28, Color("#27313a"))
    pause_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    pv.add_child(_label("I N F E R N O   ·   E L   D E S C E N S O", 13, Color("#59656b")))
    (pv.get_child(0) as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    pv.add_child(pause_title)
    pv.add_child(HSeparator.new())
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
    set_health(3, 3)
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
    elif current_circle == "traicion" and (speaker.contains("JUDAS") or speaker.contains("HITLER")):
        dialogue_portrait.texture = preload("res://scripts/traicion_marker.gd").portrait_for("alma_ugolino" if speaker.contains("JUDAS") else "alma_bocca")
    elif speaker.contains("VIRGILIO"):
        dialogue_portrait.texture = load("res://assets/ui/retrato_virgilio.png")
    elif speaker.contains("ALMA") or speaker.contains("PAOLO") or speaker.contains("FRANCESCA"):
        dialogue_portrait.texture = load("res://assets/ui/retrato_alma.png")
    else:
        dialogue_portrait.texture = load("res://assets/ui/retrato_piedra.png")
    dialogue_choices.hide()
    dialogue_text.begin(body)
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
        b.custom_minimum_size = Vector2(0, 37.0)
        b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
        b.text = _wrap_choice(b.text.to_upper())
        dialogue_choices.add_child(b)
        var captured_index: int = index
        b.pressed.connect(func() -> void: _select(captured_index))
        index += 1
    if not dialogue_text.writing:
        _reveal_choices()

func _reveal_choices() -> void:
    dialogue_choices.show()
    if dialogue_choices.get_child_count() > 0:
        dialogue_choices.get_child(0).grab_focus()

func _wrap_choice(value: String) -> String:
    var font := get_viewport().gui_get_focus_owner()
    var face: Font = ThemeDB.fallback_font if font == null else font.get_theme_default_font()
    var limit := minf(545.0, get_viewport().get_visible_rect().size.x * 0.43)
    var lines := PackedStringArray()
    var current := ""
    for word in value.split(" ", false):
        var next := word if current.is_empty() else current + " " + word
        if not current.is_empty() and face.get_string_size(next, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x > limit:
            lines.append(current)
            current = word
        else:
            current = next
    lines.append(current)
    return "\\n".join(lines)

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
    dialogue_text.writing = false
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
    if dialogue_open and dialogue_text.writing and event.is_pressed() and ((event.is_action_pressed("ui_accept") and not (event is InputEventKey and event.keycode == KEY_SPACE)) or (event is InputEventKey and event.keycode in [KEY_1, KEY_2, KEY_KP_1, KEY_KP_2]) or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT)):
        dialogue_text.finish()
        get_viewport().set_input_as_handled()
        return
    # Tab normally moves focus before _unhandled_key_input can receive it.
    if event is InputEventKey and not pause_open and not dialogue_open and not Game.crossing and event.keycode in [KEY_TAB, KEY_H]:
        if event.pressed and not event.echo:
            if event.keycode == KEY_H:
                _toggle_player_details()
            else:
                _toggle_objectives()
        get_viewport().set_input_as_handled()
        return
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
    if ke.keycode == KEY_ESCAPE:
        pause_requested.emit()
        get_viewport().set_input_as_handled()

# Lujuria shares precisely the same parchment HUD, portraits and moral dialogue frame.
func configure_chapter(circle: String, player_node: Node2D) -> void:
    current_circle = circle
    update_relic_indicator()
    preload("res://scripts/boss_remains.gd").restore(get_parent(), circle)
    preload("res://scripts/chapter_relic.gd").install(get_parent(), circle, player_node, self)
    AudioManager.enter(circle)
    set_player(player_node)
    minimap.mode = circle
    var titles := {"limbo": "I · LIMBO", "lujuria": "II · LUJURIA", "gula": "III · GULA",
        "violencia": "VII · VIOLENCIA", "traicion": "IX · TRAICIÓN"}
    chapter_subtitle.text = titles.get(circle, titles["limbo"])
    _dock(title_frame, Control.PRESET_TOP_RIGHT, Vector2(-16, 16))
    map_title.text = "PLANO"
    _set_control_legend(circle)
    red_bar.max_value = 2.0 if circle == "limbo" else 9.0
    rig_bar.max_value = red_bar.max_value
    minimap.queue_redraw()

func update_relic_indicator() -> void:
    relic_status.text = "✦  Reliquia encontrada" if Game.has_relic(current_circle) else "◇  Reliquia opcional por descubrir"

func set_health(current: int, maximum: int) -> void:
    heart_label.text = "♥".repeat(maxi(0, current)) + "♡".repeat(maxi(0, maximum - current)) if maximum <= 6 else "♥ %d/%d" % [current, maximum]
    life_detail.text = "Vida  %d / %d" % [current, maximum]

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
    soul_label.text = "◆  Judas e Hitler: %d / 2" % souls
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
    boss_bar.max_value = maxf(1.0, float(maximum))
    boss_bar.value = maxf(0.0, float(current))

func hide_boss() -> void:
    boss_frame.visible = false
