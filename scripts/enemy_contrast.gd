extends RefCounted
## Doble borde de silueta: oscuro sobre piedra clara y cálido sobre fondos oscuros.
static func apply(sprite: CanvasItem) -> void:
    var material := ShaderMaterial.new()
    material.shader = preload("res://shaders/enemy_contrast.gdshader")
    sprite.material = material
