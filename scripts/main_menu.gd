extends Control
## Menú principal autocontenido para el primer capítulo.

func _ready() -> void:
    Game.use_campaign()
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
    var art: Sprite2D = Sprite2D.new()
    art.texture = load("res://assets/world/limbo_master.png")
    art.position = Vector2(640, 360)
    art.scale = Vector2(0.92, 0.92)
    add_child(art)
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
const LEVELS := {
    "I · LIMBO": "Limbo", "II · LUJURIA": "Lujuria", "III · GULA": "Gula",
    "VII · VIOLENCIA": "Violencia", "IX · TRAICIÓN": "Traicion"
}

func _page(title: String) -> void:
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

func _show_main() -> void:
    _page("INFERNO · EL DESCENSO")
    _option("Nueva partida", _confirm_new).grab_focus()
    _option("Continuar partida anterior", _resume).disabled = not Game.has_save()
    _option("Selección de niveles", _show_levels)
    _option("Configuración", _show_settings)
    _option("Salir", func() -> void: get_tree().quit())

func _confirm_new() -> void:
    if not Game.has_save():
        _new_game()
        return
    _page("NUEVA PARTIDA")
    content.add_child(_label("Se reemplazará el progreso de la campaña.", 17, Color("#29201c")))
    _option("Volver", _show_main).grab_focus()
    _option("Iniciar nueva campaña", _new_game)

func _show_levels() -> void:
    _page("SELECCIÓN DE NIVELES")
    content.add_child(_label("Modo libre · guardado independiente", 17, Color("#29201c")))
    for label in LEVELS:
        var scene: String = LEVELS[label]
        var button := _option(label, _start_level.bind(scene))
        if scene == "Limbo":
            button.grab_focus()
    _option("Volver", _show_main)

func _show_settings() -> void:
    _page("CONFIGURACIÓN")
    var mute := CheckButton.new()
    mute.text = "Audio activado"
    mute.button_pressed = Game.audio_enabled
    mute.add_theme_color_override("font_color", Color("#29201c"))
    mute.add_theme_color_override("font_hover_color", Color("#29201c"))
    mute.add_theme_color_override("font_pressed_color", Color("#29201c"))
    mute.add_theme_color_override("font_focus_color", Color("#29201c"))
    content.add_child(mute)
    mute.toggled.connect(func(enabled: bool) -> void: Game.set_audio(enabled, Game.audio_volume))
    var label := _label("Volumen  %d%%" % roundi(Game.audio_volume * 100), 18, Color("#29201c"))
    content.add_child(label)
    var slider := HSlider.new()
    slider.min_value = 0.0
    slider.max_value = 1.0
    slider.step = 0.01
    slider.value = Game.audio_volume
    slider.custom_minimum_size.y = 36.0
    content.add_child(slider)
    slider.value_changed.connect(func(value: float) -> void:
        label.text = "Volumen  %d%%" % roundi(value * 100)
        Game.set_audio(Game.audio_enabled, value))
    _option("Volver", _show_main)
    mute.grab_focus()

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
