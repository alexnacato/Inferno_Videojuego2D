extends Node2D
var world
var elapsed := 0.0
var lifetime := 2.4
var radius := 38.0
func _physics_process(delta: float) -> void:
    if not is_instance_valid(world) or not world.game_active:
        return
    elapsed += delta
    if elapsed>=lifetime:
        queue_free()
        return
    if position.distance_to(world.hero.position)<radius and world.has_clear_path(position, world.hero.position):
        world.hero.take_damage(1)
    queue_redraw()
func _draw() -> void:
    # Área dañina ya activa: mancha de carbón, borde de brasas y ceniza visible.
    # No es un aviso previo ni muestra la dirección de un ataque futuro.
    var fade := clampf((lifetime-elapsed)/0.35,0,1)
    draw_circle(Vector2.ZERO,radius,Color(0.10,0.045,0.055,0.58*fade))
    var edge := PackedVector2Array()
    for i in range(49):
        var angle := TAU*float(i)/48
        var r := radius-2+sin(angle*7)*1.5
        edge.append(Vector2(cos(angle),sin(angle))*r)
    draw_polyline(edge,Color(0.97,0.53,0.16,0.80*fade),2,true)
    for i in range(19):
        var a := float(i)*2.4
        var p := Vector2(cos(a),sin(a))*fmod(float(i)*11,radius-4)
        p.y -= sin(elapsed*3+i)*2
        draw_circle(p,2.7,Color(0.10,0.04,0.04,fade))
        draw_circle(p,1.4,Color(1,0.73,0.35,0.9*fade))
