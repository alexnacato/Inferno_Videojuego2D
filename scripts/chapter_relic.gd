extends Node2D

const RELICS := {
    "limbo": [Vector2(687, 720), "Pluma del guía", "la esquiva recarga un 10 % antes"],
    "lujuria": [Vector2(1105, 490), "Fragmento del vendaval", "el último verso de una ráfaga completa hace un punto extra de daño"],
    "gula": [Vector2(331, 556), "Cáliz de la templanza", "obtienes un corazón adicional"],
    "violencia": [Vector2(352, 468) * (2304.0 / 850.0), "Ascua de la tregua", "la recarga de esquiva se acorta un 15 %"],
    "traicion": [Vector2(768, 810), "Cristal de Cocito", "el hielo frágil tarda más en romperse"],
}
var circle := ""
var hero: Node2D
var hud: Variant
var elapsed := 0.0
var collected := false

static func install(level: Node, chapter: String, actor: Node2D, interface: CanvasLayer) -> void:
    if not RELICS.has(chapter) or Game.has_relic(chapter):
        return
    var item := new()
    item.circle = chapter
    item.hero = actor
    item.hud = interface
    item.position = RELICS[chapter][0]
    item.z_index = 4
    level.add_child.call_deferred(item)

func _process(delta: float) -> void:
    if not is_instance_valid(hero):
        queue_free()
        return
    elapsed += delta
    queue_redraw()
    if collected or hud.dialogue_open or hud.pause_open or hero.global_position.distance_to(global_position) > 23.0:
        return
    collected = true
    Game.progress["relics"][circle] = true
    if hero.has_method("apply_relics"):
        hero.apply_relics()
    Game.save_progress()
    hud.update_relic_indicator()
    AudioManager.cue("reliquia")
    hud.toast("RELIQUIA OPCIONAL · %s. %s." % [RELICS[circle][1], RELICS[circle][2].capitalize()], 5.5)
    create_tween().tween_property(self, "scale", Vector2.ZERO, 0.45).set_trans(Tween.TRANS_BACK)
    await get_tree().create_timer(0.46).timeout
    queue_free()

func _draw() -> void:
    var offset := Vector2(0, -15.0 + sin(elapsed * 2.2) * 3.0)
    draw_circle(offset, 18, Color(0.82, 0.57, 0.23, 0.2))
    var diamond := PackedVector2Array([offset + Vector2(0,-11), offset + Vector2(8,0), offset + Vector2(0,11), offset + Vector2(-8,0)])
    draw_colored_polygon(diamond, Color("#e5b979"))
    diamond.append(diamond[0])
    draw_polyline(diamond, Color("#392615"), 2.0, true)
