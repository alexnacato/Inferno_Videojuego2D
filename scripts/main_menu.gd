extends Control
## Menú principal autocontenido para el primer capítulo.

func _ready() -> void:
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
    b.add_theme_color_override("font_color", Color("#252d33"))
    b.add_theme_stylebox_override("normal", _panel_style(Color("#e4e1db"), Color("#747f86")))
    b.add_theme_stylebox_override("hover", _panel_style(Color("#c4d0d5"), Color("#a5bcc5")))
    b.add_theme_stylebox_override("pressed", _panel_style(Color("#acbdc4"), Color("#63777f")))
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
    frame.position = Vector2(378, 110)
    frame.custom_minimum_size = Vector2(524, 508)
    frame.add_theme_stylebox_override("panel", _panel_style(Color(0.90, 0.89, 0.86, 0.96), Color("#a7b0b5")))
    add_child(frame)
    var col: VBoxContainer = VBoxContainer.new()
    col.add_theme_constant_override("separation", 15)
    frame.add_child(col)
    var small_title: Label = _label("D A N T E   A L I G H I E R I", 17, Color("#60676a"))
    small_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    col.add_child(small_title)
    var title: Label = _label("INFERNO", 51, Color("#1f272b"))
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    col.add_child(title)
    var subtitle: Label = _label("— E L   D E S C E N S O —", 21, Color("#596268"))
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    col.add_child(subtitle)
    col.add_child(HSeparator.new())
    var chapter: Label = _label("ACTO I  ·  LIMBO Y LUJURIA", 17, Color("#343e44"))
    chapter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    col.add_child(chapter)
    var desc: Label = _label("Del silencio del Limbo al vendaval de Lujuria: cada elección cuenta.", 17, Color("#4a5154"))
    desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    col.add_child(desc)
    var start: Button = _button("COMENZAR UN NUEVO VIAJE")
    col.add_child(start)
    start.pressed.connect(_new_game)
    var resume: Button = _button("CONTINUAR LA PARTIDA")
    resume.disabled = not Game.has_save()
    col.add_child(resume)
    resume.pressed.connect(_resume)
    var exit_button: Button = _button("SALIR DEL JUEGO")
    col.add_child(exit_button)
    exit_button.pressed.connect(func() -> void: get_tree().quit())
    var small: Label = _label("GODOT 4  ·  VISTA CENITAL  ·  DOS CÍRCULOS", 13, Color("#626e73"))
    small.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    col.add_child(small)
    start.grab_focus()

func _new_game() -> void:
    Game.new_game()
    get_tree().change_scene_to_file("res://scenes/Limbo.tscn")

func _resume() -> void:
    Game.load_progress()
    get_tree().change_scene_to_file(Game.next_scene())
