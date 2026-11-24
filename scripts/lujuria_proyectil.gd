extends Node2D
## Projectile is simulated without collision layers to ensure exact hit behavior.
var direction := Vector2.RIGHT
var speed := 320.0
var enemy_owned := false
var damage := 1
var world
var travel := 0.0
var elapsed := 0.0
var consumed := false

func _process(delta: float) -> void:
    if consumed or not is_instance_valid(world) or not world.game_active:
        return
    elapsed += delta
    var displacement: Vector2 = direction.normalized() * speed * delta
    var steps: int = maxi(1, ceili(displacement.length() / 7.0))
    var step: Vector2 = displacement / float(steps)
    for i in range(steps):
        position += step
        travel += step.length()
        if travel > 530.0 or elapsed > 2.4 or not world.can_walk(global_position, 5.0):
            consumed = true
            queue_free()
            return
        if enemy_owned:
            if is_instance_valid(world.hero) and world.hero.global_position.distance_to(global_position) < 19.0:
                world.hero.take_damage(damage)
                consumed = true
                queue_free()
                return
        else:
            for foe in world.foes.get_children():
                if is_instance_valid(foe) and not foe.dead and foe.active and foe.global_position.distance_to(global_position) < foe.body_radius + 6.0:
                    foe.take_damage(damage, direction)
                    consumed = true
                    queue_free()
                    return
    queue_redraw()

func _draw() -> void:
    var in_gula: bool = is_instance_valid(world) and str(world.name) == "Gula"
    var in_traicion: bool = is_instance_valid(world) and str(world.name) == "Traicion"
    var color := Color("80e8ff") if enemy_owned and in_traicion else Color("b5dd73") if enemy_owned and in_gula else Color("ba80df") if enemy_owned else Color("fff1bc")
    draw_circle(Vector2.ZERO, 9.0, Color(color.r, color.g, color.b, 0.20))
    draw_circle(Vector2.ZERO, 4.7, color)
    draw_line(-direction.normalized() * 13.0, Vector2.ZERO, Color(color.r, color.g, color.b, 0.63), 3.0)
