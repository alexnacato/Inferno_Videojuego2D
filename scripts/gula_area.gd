@tool
extends Polygon2D

## Polígonos editables en la vista 2D de Godot; el juego usa su geometría, no su relleno.
@export_enum("suelo", "lodo") var tipo := "suelo"

func _ready() -> void:
    if Engine.is_editor_hint():
        color = Color(0.22, 0.8, 0.3, 0.18) if tipo == "suelo" else Color(0.83, 0.55, 0.1, 0.36)
    else:
        visible = false
