extends CharacterBody2D

## Tres criaturas de Gula con persecución, retirada, preparación y ataque legibles.
signal died(spawn_id: String)

const WALK_SOLVER = preload("res://scripts/walk_solver.gd")
const FRAME_SIZE := Vector2(192, 192)
const DATA := {
    "penitente": {"hp": 9, "speed": 73.0, "radius": 25.0, "reach": 82.0, "cooldown": 2.2},
    "rastrero": {"hp": 5, "speed": 123.0, "radius": 18.0, "reach": 102.0, "cooldown": 1.8},
    "escanciador": {"hp": 6, "speed": 86.0, "radius": 19.0, "reach": 255.0, "cooldown": 2.45},
}
const VISUAL_SCALE := {"penitente": 0.48, "rastrero": 0.40, "escanciador": 0.40}
const HEALTH_BAR_Y := {"penitente": -82.0, "rastrero": -70.0, "escanciador": -70.0}
const ATTACK_TINT := {
    "penitente": Color(0.91, 0.48, 0.30, 0.68),
    "rastrero": Color(0.40, 0.76, 0.66, 0.68),
    "escanciador": Color(0.70, 0.86, 0.28, 0.68),
}

@export_enum("penitente", "rastrero", "escanciador") var archetype := "penitente"
@export var spawn_id := "gula_0"

var world: Variant
var hero: Variant
var anchor := Vector2.ZERO
var hp := 1
var max_hp := 1
var body_radius := 20.0
var active := true
var dead := false
var state := "idle"
var cooldown := 0.8
var windup := 0.0
var recovery := 0.0
var stun := 0.0
var fade := 0.0
var attack_direction := Vector2.DOWN
var route := PackedVector2Array()
var route_clock := 0.0
var lunge_left := 0.0
var already_hit := false
var move_velocity := Vector2.ZERO
var last_seen := Vector2.ZERO
var alert_left := 0.0
var patrol_target := Vector2.ZERO
var patrol_wait := 0.0
var patrol_index := 0
var stride := 0.0

@onready var art: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
    if not DATA.has(archetype):
        archetype = "penitente"
    var data: Dictionary = DATA[archetype]
    max_hp = int(data["hp"])
    hp = max_hp
    body_radius = float(data["radius"])
    anchor = global_position
    patrol_target = anchor
    var sprite_scale: float = float(VISUAL_SCALE[archetype])
    art.scale = Vector2.ONE * sprite_scale
    # Las tiras dejan 7 px bajo los pies; el apoyo queda en el origen del actor.
    art.position.y = -(FRAME_SIZE.y * 0.5 - 7.0) * sprite_scale
    art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    _setup_animations()
    _play("idle")
    var shape := CircleShape2D.new()
    shape.radius = body_radius
    $CollisionShape2D.shape = shape
    cooldown += float(abs(spawn_id.hash()) % 7) * 0.11

func _physics_process(delta: float) -> void:
    if dead:
        fade += delta
        if fade > 0.6:
            art.modulate.a = maxf(0.0, 1.0 - (fade - 0.6) / 0.25)
        if fade >= 0.85:
            queue_free()
        return
    if not active or not is_instance_valid(world) or not is_instance_valid(hero) or not world.game_active or not hero.control_enabled:
        return
    cooldown = maxf(0.0, cooldown - delta)
    recovery = maxf(0.0, recovery - delta)
    stun = maxf(0.0, stun - delta)
    route_clock = maxf(0.0, route_clock - delta)
    alert_left = maxf(0.0, alert_left - delta)
    patrol_wait = maxf(0.0, patrol_wait - delta)
    var to_hero: Vector2 = hero.global_position - global_position
    var distance: float = to_hero.length()
    var data: Dictionary = DATA[archetype]
    var speed: float = float(data["speed"])
    if archetype == "penitente" and hp <= max_hp / 2:
        speed *= 1.22
    if world.movement_factor(global_position) < 1.0:
        speed *= 1.2 if archetype == "rastrero" else 0.76 if archetype == "penitente" else 0.85
    var desired_velocity := Vector2.ZERO
    var can_see_hero: bool = distance < 340.0 and anchor.distance_to(hero.global_position) < 470.0 and world.has_clear_path(global_position, hero.global_position, 5.0)
    if can_see_hero:
        last_seen = hero.global_position
        alert_left = 2.4
    if stun > 0.0:
        state = "hurt"
        windup = 0.0
        lunge_left = 0.0
    elif lunge_left > 0.0:
        state = "lunge"
        lunge_left = maxf(0.0, lunge_left - delta)
        desired_velocity = attack_direction * 330.0
        if not already_hit and distance < body_radius + 15.0 and world.has_clear_path(global_position, hero.global_position, 5.0):
            hero.take_damage(1)
            already_hit = true
        if lunge_left <= 0.0:
            recovery = 0.38
            cooldown = float(data["cooldown"])
    elif windup > 0.0:
        state = "windup"
        windup -= delta
        if windup <= 0.0:
            _release_attack()
    elif recovery > 0.0:
        state = "recover"
    elif alert_left > 0.0:
        if can_see_hero and cooldown <= 0.0 and distance <= float(data["reach"]):
            state = "windup"
            windup = (0.48 if hp <= max_hp / 2 else 0.65) if archetype == "penitente" else 0.43 if archetype == "rastrero" else 0.75
            var aim: Vector2 = hero.global_position
            if archetype in ["rastrero", "escanciador"]:
                aim += hero.velocity.limit_length(230.0) * (0.16 if archetype == "rastrero" else 0.24)
            attack_direction = global_position.direction_to(aim)
            if attack_direction.length_squared() < 0.01:
                attack_direction = Vector2.DOWN
            already_hit = false
        else:
            state = "chase" if can_see_hero else "search"
            var desired: Vector2 = hero.global_position if can_see_hero else last_seen
            if archetype == "escanciador" and can_see_hero:
                if distance < 155.0:
                    var retreat: Vector2 = global_position - to_hero.normalized() * 120.0
                    desired = retreat if world.can_walk(retreat, body_radius) and world.has_clear_path(global_position, retreat, body_radius) else _sidestep(to_hero.normalized())
                elif distance < 225.0:
                    desired = _sidestep(to_hero.normalized())
                else:
                    desired = hero.global_position - to_hero.normalized() * 190.0
            if global_position.distance_to(desired) > 12.0:
                desired_velocity = _steer(desired) * speed
            elif not can_see_hero:
                alert_left = 0.0
    elif global_position.distance_to(anchor) > 20.0:
        state = "return"
        desired_velocity = _steer(anchor) * speed
    else:
        if patrol_wait <= 0.0:
            _choose_patrol_target()
        state = "patrol" if global_position.distance_to(patrol_target) > 12.0 else "idle"
        if state == "patrol":
            desired_velocity = _steer(patrol_target) * speed * 0.42
    var acceleration: float = 1100.0 if archetype == "rastrero" else 420.0 if archetype == "penitente" else 580.0
    move_velocity = desired_velocity if state == "lunge" else move_velocity.move_toward(desired_velocity, acceleration * delta)
    var before_move: Vector2 = global_position
    if move_velocity.length_squared() > 1.0:
        var steps: int = maxi(1, ceili(move_velocity.length() * delta / 7.0))
        var step: Vector2 = move_velocity * delta / float(steps)
        var can_enter: Callable = Callable(world, "can_occupy_enemy").bind(self, body_radius)
        for i in range(steps):
            global_position = WALK_SOLVER.step(global_position, step, can_enter)
    var traveled: Vector2 = global_position - before_move
    move_velocity = traveled / delta if delta > 0.0 else Vector2.ZERO
    velocity = move_velocity
    var walking: bool = traveled.length_squared() > 0.05 and state in ["chase", "search", "return", "patrol"]
    if walking and absf(traveled.x) > 0.2:
        art.flip_h = traveled.x < 0.0
    if walking:
        var stride_rate: float = 0.13 if archetype == "penitente" else 0.24 if archetype == "rastrero" else 0.18
        stride += traveled.length() * stride_rate
    var lean: float = clampf(move_velocity.x / maxf(speed, 1.0), -1.0, 1.0) * (0.07 if archetype == "rastrero" else 0.035)
    art.rotation = lerpf(art.rotation, lean if walking else 0.0, minf(1.0, delta * 8.0))
    art.position.x = sin(art.rotation) * (FRAME_SIZE.y * 0.5 - 7.0) * float(VISUAL_SCALE[archetype])
    var bob_height: float = 1.8 if archetype == "penitente" else 0.8 if archetype == "rastrero" else 1.2
    art.position.y = -(FRAME_SIZE.y * 0.5 - 7.0) * float(VISUAL_SCALE[archetype]) - (absf(sin(stride)) * bob_height if walking else 0.0)
    art.modulate = Color(1.0, 0.65, 0.55) if state == "hurt" else Color(1.0, 0.86, 0.72) if archetype == "penitente" and hp <= max_hp / 2 else Color.WHITE
    art.speed_scale = clampf(move_velocity.length() / maxf(speed, 1.0), 0.75, 1.2) if walking else 1.0
    _play("hurt" if state == "hurt" else "attack" if state in ["windup", "attack", "recover", "lunge"] else "walk" if walking else "idle")
    queue_redraw()

func _choose_patrol_target() -> void:
    patrol_index += 1
    patrol_wait = 2.2
    var angle: float = float(posmod(spawn_id.hash(), 360)) * PI / 180.0 + float(patrol_index) * 2.4
    var radius: float = 35.0 if archetype == "penitente" else 58.0 if archetype == "rastrero" else 42.0
    patrol_target = anchor
    for attempt in range(8):
        var candidate: Vector2 = anchor + Vector2.RIGHT.rotated(angle + float(attempt) * TAU / 8.0) * radius
        if world.can_walk(candidate, body_radius) and world.has_clear_path(global_position, candidate, body_radius):
            patrol_target = candidate
            break

func _sidestep(direction: Vector2) -> Vector2:
    var side: float = -1.0 if spawn_id.hash() % 2 == 0 else 1.0
    for length in [75.0, 40.0]:
        for sign_value in [side, -side]:
            var candidate: Vector2 = global_position + direction.orthogonal() * sign_value * length
            if world.can_walk(candidate, body_radius) and world.has_clear_path(global_position, candidate, body_radius):
                return candidate
    return global_position

func _steer(destination: Vector2) -> Vector2:
    if world.has_clear_path(global_position, destination, body_radius):
        route.clear()
        return global_position.direction_to(destination)
    if route_clock <= 0.0:
        route = world.route_to(global_position, destination, body_radius)
        route_clock = 0.55
    while not route.is_empty() and global_position.distance_to(route[0]) < 23.0:
        route.remove_at(0)
    return global_position.direction_to(route[0]) if not route.is_empty() else Vector2.ZERO

func _release_attack() -> void:
    if dead or not is_instance_valid(hero) or not is_instance_valid(world):
        return
    state = "attack"
    if archetype == "rastrero":
        lunge_left = 0.32
        return
    cooldown = float(DATA[archetype]["cooldown"])
    recovery = 0.35
    if archetype == "escanciador":
        world.spawn_projectile(global_position + attack_direction * 24.0, attack_direction, true, 1)
    elif global_position.distance_to(hero.global_position) <= 92.0 and world.has_clear_path(global_position, hero.global_position, 5.0) and attack_direction.dot(global_position.direction_to(hero.global_position)) > 0.25:
        hero.take_damage(2)

func take_damage(amount: int, _direction: Vector2 = Vector2.DOWN) -> void:
    if dead or not active:
        return
    hp = maxi(0, hp - maxi(0, amount))
    if hp == 0:
        dead = true
        active = false
        collision_layer = 0
        collision_mask = 0
        _play("death")
        died.emit(spawn_id)
    else:
        stun = 0.38
        alert_left = 3.0
        last_seen = hero.global_position if is_instance_valid(hero) else anchor
        _play("hurt")
    queue_redraw()

func _play(action: String) -> void:
    if art.sprite_frames == null or not art.sprite_frames.has_animation(action):
        return
    if art.animation != action or not art.is_playing():
        art.play(action)

func _setup_animations() -> void:
    var library := SpriteFrames.new()
    for action in ["idle", "walk", "attack", "hurt", "death"]:
        var path: String = "res://assets/gula/enemies/%s/%s.png" % [archetype, action]
        var texture: Texture2D = load(path)
        if texture == null:
            push_error("Falta animación de Gula: " + path)
            continue
        library.add_animation(action)
        var fps: float = 8.0 if action == "idle" else 10.0 if action == "walk" else 16.0 if action == "hurt" else 8.0 if action == "death" else 9.0 if archetype == "penitente" else 8.0
        library.set_animation_speed(action, fps)
        library.set_animation_loop(action, action in ["idle", "walk"])
        for i in range(6):
            var atlas := AtlasTexture.new()
            atlas.atlas = texture
            atlas.region = Rect2(i * FRAME_SIZE.x, 0.0, FRAME_SIZE.x, FRAME_SIZE.y)
            library.add_frame(action, atlas)
    art.sprite_frames = library

func _draw() -> void:
    draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.35))
    draw_circle(Vector2.ZERO, body_radius + 9.0, Color(0.02, 0.04, 0.02, 0.48))
    draw_set_transform(Vector2.ZERO)
    if dead:
        return
    if is_instance_valid(world) and move_velocity.length_squared() > 25.0 and world.movement_factor(global_position) < 1.0:
        draw_arc(Vector2.ZERO, body_radius + 6.0 + absf(sin(stride)) * 3.0, 0.0, TAU, 32, Color(0.46, 0.58, 0.20, 0.42), 1.5)
    if windup > 0.0:
        var tint: Color = ATTACK_TINT[archetype]
        if archetype == "penitente":
            draw_arc(Vector2.ZERO, 87.0, attack_direction.angle() - 0.8, attack_direction.angle() + 0.8, 24, tint, 4.0)
        elif archetype == "rastrero":
            draw_line(Vector2.ZERO, attack_direction * 116.0, tint, 6.0)
        else:
            draw_line(Vector2.ZERO, attack_direction * 235.0, tint, 3.0)
            draw_circle(Vector2.ZERO, 23.0, Color(0.72, 0.92, 0.22, 0.17))
    if hp < max_hp:
        var bar_y: float = float(HEALTH_BAR_Y[archetype])
        draw_rect(Rect2(-25.0, bar_y, 50.0, 6.0), Color(0.08, 0.07, 0.06, 0.9))
        var health_tint: Color = ATTACK_TINT[archetype]
        health_tint.a = 1.0
        draw_rect(Rect2(-24.0, bar_y + 1.0, 48.0 * float(hp) / float(max_hp), 4.0), health_tint)
