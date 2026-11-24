@tool
extends Polygon2D

@export_enum("suelo", "hielo_fino") var tipo := "suelo"

func _ready() -> void:
    if Engine.is_editor_hint():
        color = Color(0.2, 0.8, 0.95, 0.20) if tipo == "suelo" else Color(0.9, 0.36, 0.25, 0.33)
    else:
        visible = false
