extends Control
## Menú principal autocontenido para el primer capítulo.

func _ready() -> void:
    Game.use_campaign()
    AudioManager.enter("")
    _build()

func _panel_style(bg: Color, border: Color) -> StyleBoxFlat:
    var s: StyleBoxFlat = StyleBoxFlat.new()
    s.bg_color = bg
    s.border_color = border
    s.set_border_width_all(2)
    s.set_corner_radius_all(9)
    s.set_content_margin_all(14)
    return s

func _label(text_value: String, size_px: int, col: Color) -> Label:
    var l: Label = Label.new()
    l.text = text_value
    l.add_theme_font_size_override("font_size", size_px)
    l.add_theme_color_override("font_color", col)
    return l

func _button(text_value: String) -> Button:
    var b: Button = Button.new()
    b.text = text_value
    b.custom_minimum_size = Vector2(366, 54)
    b.add_theme_font_size_override("font_size", 17)
    return b

func _build() -> void:
    var art := TextureRect.new()
    art.texture = preload("res://assets/world/limbo_restaurado.png")
    art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    art.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(art)
    art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var shade: ColorRect = ColorRect.new()
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.color = Color(0.035, 0.045, 0.060, 0.78)
    add_child(shade)
    var frame: PanelContainer = PanelContainer.new()
    frame.custom_minimum_size = Vector2(524, 0)
    frame.add_theme_stylebox_override("panel", _panel_style(Color(0.90, 0.89, 0.86, 0.96), Color("#a7b0b5")))
    var center := CenterContainer.new()
    add_child(center)
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    center.add_child(frame)
    panel = frame
    _show_main()

var panel: PanelContainer
var content: VBoxContainer
var return_focus := -1
const LEVELS := {
    "I · LIMBO": "Limbo", "II · LUJURIA": "Lujuria", "III · GULA": "Gula",
    "VII · VIOLENCIA": "Violencia", "IX · TRAICIÓN": "Traicion"
}

func _page(title: String, back_to: int = -1) -> void:
    return_focus = back_to
    if is_instance_valid(content):
        panel.remove_child(content)
        content.queue_free()
    content = VBoxContainer.new()
    content.add_theme_constant_override("separation", 10)
    panel.add_child(content)
    var heading := _label(title, 35, Color("#29201c"))
    heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    content.add_child(heading)

func _option(label: String, action: Callable) -> Button:
    var button := _button(label)
    content.add_child(button)
    button.pressed.connect(action)
    return button

func _show_main(focus_index: int = -1) -> void:
    _page("INFERNO · EL DESCENSO")
    var buttons := [
        _option("Nueva partida", _confirm_new),
        _option("Continuar partida anterior", _resume),
        _option("Selección de niveles", _show_levels),
        _option("Configuración", _show_settings),
        _option("Salir", func() -> void: get_tree().quit()),
    ]
    buttons[1].disabled = not Game.has_save()
    if buttons[1].disabled:
        buttons[1].focus_mode = Control.FOCUS_NONE
    var initial := (0 if buttons[1].disabled else 1) if focus_index < 0 else focus_index
    buttons[initial].grab_focus()

func _unhandled_key_input(event: InputEvent) -> void:
    if return_focus >= 0 and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
        get_viewport().set_input_as_handled()
        AudioManager.cue("menu")
        _show_main(return_focus)

func _confirm_new() -> void:
    if not Game.has_save():
        _new_game()
        return
    _page("NUEVA PARTIDA", 0)
    _subtitle("Se reemplazará el progreso de la campaña.")
    _option("Volver", _show_main.bind(0)).grab_focus()
    _option("Iniciar nueva campaña", _new_game)

func _show_levels() -> void:
    _page("SELECCIÓN DE NIVELES", 2)
    _subtitle("Modo libre · el progreso de campaña se conserva")
    for label in LEVELS:
        var scene: String = LEVELS[label]
        var button := _option(label, _start_level.bind(scene))
        if scene == "Limbo":
            button.grab_focus()
    _option("Volver", _show_main.bind(2))

func _subtitle(value: String) -> void:
    var subtitle := _label(value, 17, Color("#29201c"))
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    content.add_child(subtitle)

func _show_settings() -> void:
    _page("CONFIGURACIÓN", 3)
    var audio := _button("Audio · " + ("Activado" if Game.audio_enabled else "Silenciado"))
    content.add_child(audio)
    audio.pressed.connect(func() -> void:
        Game.set_audio(not Game.audio_enabled, Game.audio_volume)
        audio.text = "Audio · " + ("Activado" if Game.audio_enabled else "Silenciado"))
    var label := _label("Volumen  %d%%" % roundi(Game.audio_volume * 100), 18, Color("#29201c"))
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    content.add_child(label)
    var slider := HSlider.new()
    slider.min_value = 0.0
    slider.max_value = 1.0
    slider.step = 0.01
    slider.value = Game.audio_volume
    slider.custom_minimum_size.y = 36.0
    content.add_child(slider)
    slider.focus_entered.connect(func() -> void:
        slider.add_theme_stylebox_override("grabber_area", slider.get_theme_stylebox("grabber_area_highlight")))
    slider.focus_exited.connect(func() -> void: slider.remove_theme_stylebox_override("grabber_area"))
    slider.value_changed.connect(func(value: float) -> void:
        label.text = "Volumen  %d%%" % roundi(value * 100)
        Game.set_audio(Game.audio_enabled, value))
    _option("Volver", _show_main.bind(3))
    audio.grab_focus()

func _new_game() -> void:
    Game.use_campaign()
    Game.new_game()
    get_tree().change_scene_to_file("res://scenes/Limbo.tscn")

func _resume() -> void:
    Game.use_campaign()
    get_tree().change_scene_to_file(Game.next_scene())

func _start_level(scene: String) -> void:
    Game.use_free_play()
    get_tree().change_scene_to_file("res://scenes/%s.tscn" % scene)
