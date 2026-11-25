extends RefCounted
## Doble borde de silueta: oscuro sobre piedra clara y cálido sobre fondos oscuros.
static func apply(sprite: CanvasItem, hero: bool = false) -> void:
    var material := ShaderMaterial.new()
    material.shader = preload("res://shaders/enemy_contrast.gdshader")
    if hero:
        material.set_shader_parameter("light_edge", Color("#fff2b8"))

    sprite.material = material
