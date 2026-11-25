extends Node2D
## Visual + semantic wrapper: NPC, wind seal or gate.
## Esculturas de piedra ancladas al suelo, con el lenguaje visual del Limbo.
@export var uid := ""
@export_enum("virgilio", "paolo", "francesca", "sello", "puerta") var kind := "sello"
@export var caption := ""
var completed := false
var near := false
var elapsed := 0.0
var base_art_y := 0.0
const VISUAL = preload("res://scripts/interaction_visual.gd")
@onready var art: Sprite2D = $Sprite2D

func _ready() -> void:
    var texture_path := "res://assets/lujuria/npcs/"
    match kind:
        "virgilio": texture_path += "virgilio_statue.png"
        "paolo": texture_path += "paolo_statue.png"
        "francesca": texture_path += "francesca_statue.png"
        "puerta": texture_path += "gate.png"
        _: texture_path += "sello.png"
    art.texture = load(texture_path)
    if kind == "virgilio" or kind == "paolo" or kind == "francesca":
        var scale_factor: float = 0.106 if kind == "virgilio" else 0.096
        art.scale = Vector2.ONE * scale_factor
        VISUAL.spirit(art, kind == "virgilio")
        art.position.y = -768.0 * scale_factor
        art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
        if kind != "virgilio":
            art.modulate = Color(0.94, 0.91, 1.0, 1.0)
    elif kind == "puerta":
        art.position.y = -41.0
    elif kind == "sello":
        art.position.y = -26.0
        art.scale = Vector2(0.64, 0.64)
    base_art_y = art.position.y
    queue_redraw()

func _process(delta: float) -> void:
    elapsed += delta
    art.position.y = base_art_y + sin(elapsed * 2.2) * (2.0 if kind in ["sello", "puerta"] else 6.0)
    queue_redraw()

func set_done(value: bool) -> void:
    completed = value
    if kind == "sello":
        art.modulate = Color("a7d7c4") if completed else Color.WHITE
    elif kind == "paolo" or kind == "francesca":
        art.modulate = Color(0.94, 0.91, 1.0, 0.74 if completed else 1.0)
    queue_redraw()

func _draw() -> void:
    if completed and kind != "puerta":
        VISUAL.seen(self)
    if kind == "paolo" or kind == "francesca" or kind == "virgilio":
        draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.32))
        draw_circle(Vector2.ZERO, 21.0, Color(0.02, 0.01, 0.04, 0.32))
        draw_set_transform(Vector2.ZERO)
        if near:
            draw_arc(Vector2.ZERO, 23.0, 0.0, TAU, 36, Color(0.90, 0.83, 1.0, 0.54), 1.3)
        return
    var glow: Color = Color("9d68ca") if not completed else Color("9bc9a1")
    draw_circle(Vector2.ZERO, 15.0, Color(glow.r, glow.g, glow.b, 0.12))
    draw_arc(Vector2.ZERO, 19.0 + 2.0 * sin(elapsed * 2.0), 0.0, TAU, 36, Color(glow.r, glow.g, glow.b, 0.55), 1.8)
    if near:
        draw_arc(Vector2.ZERO, 25.0, 0.0, TAU, 36, Color("e6d3ff"), 2.0)

