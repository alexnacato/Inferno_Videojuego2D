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
    if consumed or is_queued_for_deletion() or not is_instance_valid(world) or not world.game_active:
        return
    elapsed += delta
    var displacement: Vector2 = direction.normalized() * speed * delta
    var steps: int = maxi(1, ceili(displacement.length() / 7.0))
    var step: Vector2 = displacement / float(steps)
    for i in range(steps):
        position += step
        travel += step.length()
        if travel > 530.0 or elapsed > 2.4 or not world.can_walk(global_position, 5.0):
            _finish()
            return
        if enemy_owned:
            if is_instance_valid(world.hero) and world.hero.global_position.distance_to(global_position) < 19.0 and world.has_clear_path(global_position, world.hero.global_position):
                world.hero.take_damage(damage)
                _finish()
                return
        else:
            for foe in world.foes.get_children():
                if is_instance_valid(foe) and not foe.dead and foe.active and foe.global_position.distance_to(global_position) < foe.body_radius + 6.0 and world.has_clear_path(global_position, foe.global_position):
                    foe.take_damage(damage, direction)
                    consumed = true
                    queue_free()
                    return
    queue_redraw()

func _finish() -> void:
    consumed = true
    if enemy_owned:
        if world.has_method("spawn_residue"):
            world.spawn_residue(global_position - direction.normalized() * 8.0)
        var ice := str(world.name) == "Traicion"
        var tint := Color("#a8ebff") if ice else Color("#c2e98a") if str(world.name) == "Gula" else Color("#d4a9ff")
        preload("res://scripts/combat_fx.gd").burst(world, global_position, -direction, 22.0, tint)
    queue_free()

func _draw() -> void:
    var forward := direction.normalized()
    var side := forward.orthogonal()
    var circle := str(world.name) if is_instance_valid(world) else ""
    if not enemy_owned:
        var pulse_color := Color("#bdefff") if circle == "Traicion" else Color("#eafb9f") if circle == "Gula" else Color("#f3c8ff")
        draw_line(-forward * 19.0, forward * 9.0, pulse_color, 3.0, true)
        draw_line(-side * 5.0, side * 5.0, Color("#fff8e2"), 2.0, true)
        return
    match circle:
        "Gula":
            draw_colored_polygon(PackedVector2Array([forward * 10.0, side * 5.0, -forward * 19.0, -side * 6.0]), Color("#a3c65a"))
            draw_line(-forward * 10.0, forward * 5.0, Color("#ecf4a3"), 2.0, true)
            draw_circle(-forward * 22.0 + side * 3.0, 2.0, Color("#cbd578"))
        "Traicion":
            draw_colored_polygon(PackedVector2Array([forward * 12.0, side * 5.0, -forward * 9.0, -side * 4.0]), Color("#91e6ff"))
            draw_line(-forward * 8.0, forward * 9.0, Color("#effdff"), 2.0, true)
            for i in range(3):
                draw_circle(-forward * (12.0 + i * 5.0) + side * sin(elapsed * 18.0 + i) * 5.0, 1.7, Color("#cceeff"))
        _:
            for i in range(3):
                var turn := elapsed * 14.0 + i * TAU / 3.0
                draw_arc(-forward * float(i * 6), 7.0 + i * 2.0, turn, turn + 2.4, 12, Color("#e2b0ff"), 2.0, true)
            draw_polyline(PackedVector2Array([-forward * 17.0, -side * 4.0, forward * 3.0 + side * 3.0, forward * 11.0]), Color("#f8e7ff"), 2.0, true)