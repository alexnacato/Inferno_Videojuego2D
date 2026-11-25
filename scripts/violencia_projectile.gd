extends Node2D
var world
var direction := Vector2.RIGHT
var enemy_owned := false
var damage := 2
var speed := 400.0
var age := 0.0
var radius := 7.0
var kind := "verse"
func _physics_process(delta: float) -> void:
    if not is_instance_valid(world) or not world.game_active:
        return
    age += delta
    if age > 1.7:
        queue_free()
        return
    var displacement := direction.normalized() * speed * delta
    var steps := maxi(1, int(ceil(displacement.length()/5.0)))
    for i in range(steps):
        position += displacement / float(steps)
        if not world.can_walk(position, 3):
            queue_free()
            return
        if enemy_owned:
            if position.distance_to(world.hero.position) < 19 + radius and world.has_clear_path(position, world.hero.position):
                world.hero.take_damage(damage)
                queue_free()
                return
        else:
            for enemy in world.foes.get_children():
                if not enemy.dead and position.distance_to(enemy.position) < enemy.body_radius + radius and world.has_clear_path(position, enemy.position):
                    enemy.take_damage(damage, direction)
                    queue_free()
                    return
    queue_redraw()
func _draw() -> void:
    var forward := direction.normalized()
    var side := forward.orthogonal()
    if kind == "arrow":
        # Silueta oscura y punta marfil: legible sobre roca gris y río rojo.
        draw_line(-forward*25,forward*8,Color("#d65327"),7,true)
        draw_line(-forward*17,forward*8,Color("180d12"),6,true)
        draw_line(-forward*17,forward*8,Color("ffe6a1"),2.5,true)
        draw_colored_polygon(PackedVector2Array([forward*15,forward*3+side*6,forward*3-side*6]),Color("180d12"))
        draw_colored_polygon(PackedVector2Array([forward*12,forward*4+side*3.5,forward*4-side*3.5]),Color("fff4ce"))
        return
    var c := Color("ffac35") if kind == "ember" else Color("ff8058") if enemy_owned else Color("b5efff")
    if enemy_owned:
        var flicker := sin(age * 38.0) * 2.0
        draw_colored_polygon(PackedVector2Array([forward * 9.0, side * 7.0, -forward * (22.0 + flicker), -side * 7.0]), Color("#f46e30"))
        draw_line(-forward * 13.0, forward * 6.0, Color("#fff3a0"), 4.0, true)
        draw_circle(-forward * 24.0, 2.0, c)
        return
    draw_line(Vector2.ZERO,-forward*22,Color("180d12"),8,true)
    draw_line(Vector2.ZERO,-forward*20,Color(c,0.8),4,true)
    draw_circle(Vector2.ZERO,radius+2,Color("180d12"))
    draw_circle(Vector2.ZERO,radius,c)
    draw_circle(Vector2.ZERO,radius*0.4,Color("fff4ce") if enemy_owned else Color("efffff"))
