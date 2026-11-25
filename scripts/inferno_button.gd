extends Button

func _ready() -> void:
    text = text.to_upper()
    remove_theme_font_size_override("font_size")
    if text.begins_with("VOLVER") or text.begins_with("GUARDAR Y VOLVER"):
        theme_type_variation = &"BackButton"
        text = "‹  " + text
        custom_minimum_size.y = 44.0
    elif text == "SALIR":
        theme_type_variation = &"ExitButton"
        custom_minimum_size = Vector2(208, 44)
        size_flags_horizontal = Control.SIZE_SHRINK_CENTER
