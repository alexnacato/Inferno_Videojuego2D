extends SceneTree
var failures := 0
func _initialize() -> void:
    call_deferred("run_checks")
func check(ok: bool, label: String) -> void:
    print(("PASS " if ok else "FAIL ") + label)
    if not ok:
        failures += 1
func run_checks() -> void:
    var ground = load("res://scripts/lujuria_ground.gd").new()
    check(ground.can_walk(Vector2(723, 977), 14), "Lujuria: inicio libre")
    check(not ground.can_walk(Vector2(724, 565), 14), "Lujuria: pedestal solido")
    check(not ground.can_walk(Vector2(50, 550), 14), "Lujuria: abismo bloqueado")
    # Flood fill sobre posiciones válidas y segmentos barridos, no solo extremos.
    var start := Vector2i(72, 98)
    var seen := {start: true}
    var queue: Array[Vector2i] = [start]
    var cursor := 0
    while cursor < queue.size():
        var cell := queue[cursor]
        cursor += 1
        for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
            var next: Vector2i = cell + offset
            if seen.has(next):
                continue
            var target := Vector2(next) * 10.0
            if ground.can_walk(target, 14) and ground.move_on_ground(Vector2(cell)*10, Vector2(offset)*10, 14).distance_to(target) < 0.01:
                seen[next] = true
                queue.append(next)
    var points := {"virgilio": Vector2(858,877), "paolo": Vector2(293,532), "francesca": Vector2(1153,529), "sello_inicio": Vector2(722,689), "sello_izquierdo": Vector2(387,422), "sello_derecho": Vector2(1052,420), "puerta": Vector2(720,179)}
    for key in points:
        var distance := INF
        for cell in queue:
            distance = minf(distance, (Vector2(cell)*10).distance_to(points[key]))
        check(distance < 95, "Lujuria: acceso " + key + " (%.1f px)" % distance)
    var origin := Vector2(724, 670)
    var stopped: Vector2 = ground.move_on_ground(origin, Vector2(0, -230), 14)
    check(stopped.y > 620, "Lujuria: barrido largo no atraviesa estatua")
    # Escena real del Limbo: consultas contra cuerpos físicos generados.
    var limbo = load("res://scenes/Limbo.tscn").instantiate()
    root.add_child(limbo)
    await physics_frame
    await physics_frame
    var space = limbo.get_world_2d().direct_space_state
    var shape := CircleShape2D.new()
    shape.radius = 14
    var query := PhysicsShapeQueryParameters2D.new()
    query.shape = shape
    query.collision_mask = 1
    var samples := {"escalera baja": [Vector2(770,350),false], "escalera alta": [Vector2(770,250),false], "fuente izquierda": [Vector2(300,570),true], "fuente derecha": [Vector2(1240,570),true], "pedestal": [Vector2(770,600),true], "muro": [Vector2(100,100),true], "entrada": [Vector2(770,834),false]}
    for key in samples:
        query.transform = Transform2D(0, samples[key][0])
        check(not space.intersect_shape(query).is_empty() == samples[key][1], "Limbo: " + key)
    # Acceso a todos los hotspots usando las colisiones físicas del Limbo.
    var reachable := {Vector2i(77,83): true}
    var cells: Array[Vector2i] = [Vector2i(77,83)]
    var index := 0
    while index < cells.size():
        var cell := cells[index]
        index += 1
        for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
            var next: Vector2i = cell + offset
            if reachable.has(next) or next.x < 0 or next.x > 154 or next.y < 0 or next.y > 98:
                continue
            query.transform = Transform2D(0, Vector2(next)*10)
            if space.intersect_shape(query).is_empty():
                reachable[next] = true
                cells.append(next)
    for point in limbo.POINTS:
        var distance := INF
        for cell in cells:
            distance = minf(distance, (Vector2(cell)*10).distance_to(point["pos"]))
        check(distance <= float(point["radius"]), "Limbo: acceso " + str(point["id"]))
    limbo.queue_free()
    await process_frame
    var lujuria = load("res://scenes/Lujuria.tscn").instantiate()
    root.add_child(lujuria)
    for wave in lujuria.SPAWNS.values():
        for spec in wave:
            var enemy = lujuria._spawn_enemy(spec["type"], spec["id"], spec["pos"])
            check(lujuria.can_walk(enemy.position, float(enemy.STATS[enemy.archetype]["radius"])), "Enemigo sobre suelo: " + str(spec["id"]))
    var boss = lujuria._spawn_enemy("minos", "test_minos", Vector2(716,317))
    check(lujuria.can_walk(boss.position, 35), "Minos sobre suelo")
    await physics_frame
    await physics_frame
    lujuria.ambient.stop()
    await create_timer(0.15).timeout
    lujuria.queue_free()
    await process_frame
    print("RESULTADO: %d fallos" % failures)
    ground = null
    call_deferred("quit", 1 if failures else 0)
