extends CharacterBody2D

const WALK_SOLVER = preload("res://scripts/walk_solver.gd")
const FRAME_SIZE := Vector2(384, 384)
const VISUAL_SCALE := 0.57

signal defeated
signal hp_changed(current: int, maximum: int)

const MAX_HP := 54
var max_hp := MAX_HP
var hp := MAX_HP
var active := true
var dead := false
var body_radius := 68.0
var world: Variant
var hero: Variant
var cooldown := 1.5
var windup := 0.0
var pattern := 0
var flash := 0.0
var attack_direction := Vector2.DOWN
var phase := 1
var home := Vector2.ZERO
var death_time := 0.0
var hurt_left := 0.0
var move_velocity := Vector2.ZERO
var stride := 0.0

@onready var art: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
    preload("res://scripts/enemy_contrast.gd").apply(art)
    home = global_position
    art.scale = Vector2.ONE * VISUAL_SCALE
    # El punto de apoyo coincide con las patas, no con el centro del fotograma.
    art.position = Vector2(0, -(FRAME_SIZE.y * 0.5 - 7.0) * VISUAL_SCALE)
    art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    _setup_animations()
    _play("idle")
    hp_changed.emit(hp, MAX_HP)

func _physics_process(delta: float) -> void:
    if dead:
        death_time += delta
        if death_time > 0.8:
            art.modulate.a = maxf(0.0, 1.0 - (death_time - 0.8) / 0.3)
        if death_time >= 1.1:
            queue_free()
        return
    if not active or not is_instance_valid(world) or not world.game_active or not is_instance_valid(hero):
        return
    flash = maxf(0.0, flash - delta)
    art.modulate = Color(1.0, 0.65, 0.65) if flash > 0.0 else Color.WHITE
    if hurt_left > 0.0:
        hurt_left = maxf(0.0, hurt_left - delta)
        move_velocity = move_velocity.move_toward(Vector2.ZERO, 500.0 * delta)
        _play("hurt")
        queue_redraw()
        return
    var distance: float = global_position.distance_to(hero.global_position)
    if windup > 0.0:
        _play("idle")
        windup -= delta
        if windup <= 0.0:
            _release_attack()
            cooldown = 1.6 if phase == 1 else 1.05
            pattern = (pattern + 1) % 3
    else:
        cooldown -= delta
        var desired_velocity := Vector2.ZERO
        if distance > 90.0 and distance < 390.0 and hero.global_position.y < 390.0:
            desired_velocity = global_position.direction_to(hero.global_position) * (82.0 if phase == 1 else 112.0)
        elif distance <= 90.0:
            desired_velocity = global_position.direction_to(hero.global_position).orthogonal() * (70.0 if pattern % 2 == 0 else -70.0)
        elif global_position.distance_to(home) > 14.0 and distance > 430.0:
            desired_velocity = global_position.direction_to(home) * 46.0
        move_velocity = move_velocity.move_toward(desired_velocity, 240.0 * delta)
        var before_move: Vector2 = global_position
        if move_velocity.length_squared() > 1.0:
            var steps: int = maxi(1, ceili(move_velocity.length() * delta / 6.0))
            var step: Vector2 = move_velocity * delta / float(steps)
            for i in range(steps):
                global_position = WALK_SOLVER.step(global_position, step, Callable(self, "_can_step"))
        var traveled: Vector2 = global_position - before_move
        move_velocity = traveled / delta if delta > 0.0 else Vector2.ZERO
        velocity = move_velocity
        var moving: bool = traveled.length_squared() > 0.05
        if moving:
            stride += traveled.length() * 0.12
            if absf(traveled.x) > 0.3:
                art.flip_h = traveled.x < 0.0
        art.position.y = -(FRAME_SIZE.y * 0.5 - 7.0) * VISUAL_SCALE - (absf(sin(stride)) * 2.0 if moving else 0.0)
        art.speed_scale = clampf(move_velocity.length() / (48.0 if phase == 1 else 68.0), 0.75, 1.25) if moving else 1.0
        _play("walk" if moving else "idle")
        if cooldown <= 0.0 and distance < 420.0 and hero.global_position.y < 420.0:
            attack_direction = global_position.direction_to(hero.global_position)
            if attack_direction.length_squared() < 0.01:
                attack_direction = Vector2.DOWN
            windup = 0.78 if phase == 1 else 0.58
    queue_redraw()

func _can_step(point: Vector2) -> bool:
    return point.distance_to(home) < 240.0 and point.y > 193.0 and point.y < 405.0 and world.can_walk(point, body_radius)

func _release_attack() -> void:
    AudioManager.cue("jefe")
    _play(_attack_key())
    preload("res://scripts/combat_fx.gd").burst(self, global_position, attack_direction, 101.0, Color("eba452"))
    if dead or not is_instance_valid(hero) or not is_instance_valid(world):
        return
    var distance: float = global_position.distance_to(hero.global_position)
    match pattern:
        0: # Mordida frontal con avance corto sobre la arena.
            var step := attack_direction * 6.0
            for i in range(5 if phase == 1 else 7):
                var next := global_position + step
                if not _can_step(next) or next.distance_to(hero.global_position) < body_radius + 10.0:
                    break
                global_position = next
            distance = global_position.distance_to(hero.global_position)
            if distance < 120.0 and world.has_clear_path(global_position, hero.global_position, 5.0) and attack_direction.dot(global_position.direction_to(hero.global_position)) > 0.25:
                hero.take_damage(2)
        1: # Aullido: tres proyectiles visibles que se pueden esquivar.
            var angles := [-0.24, 0.0, 0.24] if phase == 1 else [-0.45, -0.22, 0.0, 0.22, 0.45]
            for angle in angles:
                world.spawn_projectile(global_position, attack_direction.rotated(angle), true, 1)
        2: # Zarpazo circular, con aviso visual durante la preparación.
            if distance < 170.0 and world.has_clear_path(global_position, hero.global_position, 5.0):
                hero.take_damage(2)

func take_damage(amount: int, _direction: Vector2) -> void:
    if dead or not active or not is_instance_valid(world) or not world.game_active:
        return
    AudioManager.cue("impacto")
    hp = maxi(0, hp - maxi(0, amount))
    flash = 0.16
    hurt_left = 0.10 if windup <= 0.0 else 0.0
    cooldown = maxf(cooldown, 0.48)
    if phase == 1 and hp <= MAX_HP / 2:
        phase = 2
        cooldown = minf(cooldown, 0.6)
    hp_changed.emit(hp, MAX_HP)
    if hp == 0:
        AudioManager.cue("muerte")
        dead = true
        active = false
        collision_layer = 0
        collision_mask = 0
        _play("death")
        defeated.emit()
    else:
        _play("hurt")

func reset_encounter() -> void:
    hp = max_hp
    global_position = home
    phase = 1
    pattern = 0
    cooldown = 1.5
    windup = 0.0
    hurt_left = 0.0
    move_velocity = Vector2.ZERO
    hp_changed.emit(hp, max_hp)

func _attack_key() -> String:
    return "bite" if pattern == 0 else "howl" if pattern == 1 else "claw"

func _play(action: String) -> void:
    if art.sprite_frames == null or not art.sprite_frames.has_animation(action):
        return
    art.speed_scale = 1.3 if action in ["bite", "howl", "claw"] and phase == 2 else 1.0
    if art.animation != action or not art.is_playing():
        art.play(action)

func _setup_animations() -> void:
    var library := SpriteFrames.new()
    for action in ["idle", "walk", "bite", "howl", "claw", "hurt", "death"]:
        var path: String = "res://assets/gula/enemies/cerbero/%s.png" % action
        var texture: Texture2D = load(path)
        if texture == null:
            push_error("Falta animación de Cerbero: " + path)
            continue
        library.add_animation(action)
        library.set_animation_speed(action, 7.0 if action in ["idle", "death"] else 14.0 if action == "hurt" else 9.0 if action == "walk" else 8.0)
        library.set_animation_loop(action, action in ["idle", "walk"])
        var source := texture.get_image()
        for i in range(6):
            var region := Rect2i(i * int(FRAME_SIZE.x), 0, int(FRAME_SIZE.x), int(FRAME_SIZE.y))
            library.add_frame(action, preload("res://scripts/sprite_library.gd").isolated(texture, source, region, 6))
    art.sprite_frames = library

func _draw() -> void:
    if dead:
        return
    if phase == 2:
        draw_arc(Vector2.ZERO, 76.0, 0.0, TAU, 48, Color(0.75, 0.9, 0.18, 0.28), 3.0)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.36))
    draw_circle(Vector2.ZERO, 64.0, Color(0, 0, 0, 0.4))
    draw_set_transform(Vector2.ZERO)
