extends Node2D
## Visual + semantic wrapper: NPC, wind seal or gate.
## Paolo y Francesca se dibujan como almas etÃ©reas con el mismo diseÃ±o
## pintado del Limbo: figura encapuchada monÃ³tona, borde blanco luminoso,
## halo suave, tÃºnica con doblez arrastrado y burbuja de diÃ¡logo.
@export var uid := ""
@export_enum("virgilio", "paolo", "francesca", "sello", "puerta") var kind := "sello"
@export var caption := ""
var completed := false
var near := false
var elapsed := 0.0
@onready var art: Sprite2D = $Sprite2D

func _ready() -> void:
    var texture_path := "res://assets/lujuria/npcs/"
    match kind:
        "virgilio": texture_path += "virgilio.png"
        "paolo": texture_path += "paolo.png"
        "francesca": texture_path += "francesca.png"
        "puerta": texture_path += "gate.png"
        _: texture_path += "sello.png"
    art.texture = load(texture_path)
    if kind == "puerta":
        art.position.y = -41.0
    elif kind == "sello":
        art.position.y = -26.0
        art.scale = Vector2(0.64, 0.64)
    elif kind == "paolo" or kind == "francesca":
        art.visible = false
    else:
        art.position.y = -49.0
    queue_redraw()

func _process(delta: float) -> void:
    elapsed += delta
    if kind != "paolo" and kind != "francesca":
        art.position.y += sin(elapsed * 2.2) * delta * (3.0 if kind != "virgilio" else 0.5)
    queue_redraw()

func set_done(value: bool) -> void:
    completed = value
    art.modulate = Color("a7d7c4") if completed and kind == "sello" else Color.WHITE
    queue_redraw()

func _draw() -> void:
    if kind == "paolo" or kind == "francesca":
        # Igual que en el Limbo: el alma esta pintada en el mapa; el marcador
        # es el hotspot discreto (punto + anillo pulsante) de scripts/hotspot.gd.
        var pulse: float = sin(elapsed * 2.1) * 0.5 + 0.5
        var col: Color = Color("#d8dfeb")
        var transparency: float = 0.30 if completed else 0.74
        draw_circle(Vector2.ZERO, 19.0 + pulse * 3.0, Color(col.r, col.g, col.b, transparency * 0.11))
        draw_arc(Vector2.ZERO, 14.0 + pulse * 2.0, 0.0, TAU, 30, Color(col.r, col.g, col.b, transparency * (0.65 if near else 0.42)), 1.6, true)
        if near and not completed:
            draw_arc(Vector2.ZERO, 23.0, 0.0, TAU, 40, Color(col.r, col.g, col.b, 0.82), 1.5, true)
        draw_circle(Vector2.ZERO, 3.0, Color(col.r, col.g, col.b, 0.96))
        queue_redraw()
        return
    var glow: Color = Color("9d68ca") if not completed else Color("9bc9a1")
    draw_circle(Vector2.ZERO, 15.0, Color(glow.r, glow.g, glow.b, 0.12))
    draw_arc(Vector2.ZERO, 19.0 + 2.0 * sin(elapsed * 2.0), 0.0, TAU, 36, Color(glow.r, glow.g, glow.b, 0.55), 1.8)
    if near:
        draw_arc(Vector2.ZERO, 25.0, 0.0, TAU, 36, Color("e6d3ff"), 2.0)

