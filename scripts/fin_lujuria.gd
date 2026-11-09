extends Control
## Conclusión del Círculo II. Dicta el veredicto del jugador según sus decisiones.

const VEREDICTOS: Dictionary = {
    "alma_elio": ["Elio  ·  Recordado", "Elio  ·  Silenciado"],
    "alma_livia": ["Livia  ·  Consolada", "Livia  ·  Juzgada"],
    "alma_paolo": ["Paolo  ·  Comprendido", "Paolo  ·  Condenado"],
    "alma_francesca": ["Francesca  ·  Guiada", "Francesca  ·  Negada"]
}

func _ready() -> void:
    var bg: TextureRect = TextureRect.new()
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.texture = load("res://assets/lujuria/world/lujuria_base.png")
    bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    add_child(bg)
    var shade: ColorRect = ColorRect.new()
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.color = Color(0.035, 0.020, 0.05, 0.86)
    add_child(shade)
    var panel: PanelContainer = PanelContainer.new()
    panel.position = Vector2(302, 115)
    panel.custom_minimum_size = Vector2(676, 497)
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = Color("#e8e3df")
    style.border_color = Color("#7b3f9e")
    style.set_border_width_all(3)
    style.set_corner_radius_all(10)
    style.set_content_margin_all(22)
    panel.add_theme_stylebox_override("panel", style)
    add_child(panel)
    var stack: VBoxContainer = VBoxContainer.new()
    stack.add_theme_constant_override("separation", 19)
    panel.add_child(stack)
    stack.add_child(_label("INFERNO  ·  EL DESCENSO", 31))
    stack.add_child(HSeparator.new())
    stack.add_child(_label("CÍRCULO II  ·  LUJURIA COMPLETADO", 24))
    var description: Label = _label("La tempestad pierde su dominio. Has escuchado las voces de Paolo y Francesca y has vencido la custodia de Minos.", 19)
    description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    stack.add_child(description)
    var red: int = int(Game.progress["redencion"])
    var rig: int = int(Game.progress["rigor"])
    var path_title: String
    var path_text: String
    var path_color: String
    if red > rig:
        path_title = "TU VÍA: LA MISERICORDIA"
        path_text = "Tu compasión pesó más que tu severidad. Las almas a las que diste nombre y respiro caminarán contigo: en la Gula, los vientos se mostrarán menos crueles con quien comprendió al caído."
        path_color = "#7b9e6b"
    elif rig > red:
        path_title = "TU VÍA: EL JUICIO"
        path_text = "Tu severidad pesó más que tu compasión. Las almas cargan tu veredicto como plomo: en la Gula, Dante descenderá con el peso de haber condenado, y ningún consuelo lo aliviará."
        path_color = "#9e6b4f"
    else:
        path_title = "TU VÍA: LA BALANZA EQUILIBRADA"
        path_text = "Ni misericordia firme ni juicio firme: tu balanza quedó pareja. Las almas te recordarán como un peregrino que dudo, y la duda también deja huella en los círculos que aguardan."
        path_color = "#7b6b9e"
    var path_label: Label = _label(path_title, 26)
    path_label.add_theme_color_override("font_color", Color(path_color))
    stack.add_child(path_label)
    var path_body: Label = _label(path_text, 17)
    path_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    stack.add_child(path_body)
    var verdicts: VBoxContainer = VBoxContainer.new()
    verdicts.add_theme_constant_override("separation", 4)
    for soul_id in VEREDICTOS.keys():
        var decided_text: String = str(Game.progress.get(soul_id, ""))
        var line: String = VEREDICTOS[soul_id][0] if decided_text == "redencion" else VEREDICTOS[soul_id][1] if not decided_text.is_empty() else VEREDICTOS[soul_id][0]
        var row: Label = _label(line, 16)
        row.add_theme_color_override("font_color", Color("#5a3f68"))
        verdicts.add_child(row)
    stack.add_child(verdicts)
    stack.add_child(_label("Redención total: %d     Rigor total: %d" % [red, rig], 19))
    stack.add_child(_label("PRÓXIMO CÍRCULO: GULA · PENDIENTE DE DESARROLLO", 15))
    var menu: Button = Button.new()
    menu.text = "VOLVER AL MENÚ PRINCIPAL"
    menu.custom_minimum_size = Vector2(340, 52)
    menu.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/MenuPrincipal.tscn"))
    stack.add_child(menu)
    menu.grab_focus()

func _label(value: String, font_size: int) -> Label:
    var node: Label = Label.new()
    node.text = value
    node.add_theme_font_size_override("font_size", font_size)
    node.add_theme_color_override("font_color", Color("#342c3a"))
    node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    return node
