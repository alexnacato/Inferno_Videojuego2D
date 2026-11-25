extends CharacterBody2D
const WALK_SOLVER = preload("res://scripts/walk_solver.gd")
## Dante: controlador reutilizable de 8 direcciones con animación en 4 ángulos.
signal interaction_requested
signal hint_requested
signal message_requested(message: String)
signal health_changed(current: int, maximum: int)
signal dash_started

@export var speed: float = 196.0
@export var dash_speed: float = 475.0
@export var dash_duration: float = 0.16
@export var dash_cooldown: float = 0.80
@export var combat_enabled: bool = false
var input_locked: bool = false
var step_travel := 0.0
var max_health: int = 3
var health: int = 3
var face: String = "up"
var last_motion: Vector2 = Vector2.UP
var dash_time_left: float = 0.0
var dash_cooldown_left: float = 0.0
var action_time_left: float = 0.0
var action_name: String = ""
var blocked_attack_notified: bool = false
var navigation: Node = null
var lake_jump_elapsed: float = 0.0
var lake_jump_from: Vector2 = Vector2.ZERO
var lake_jump_to: Vector2 = Vector2.ZERO
const LAKE_JUMP_DURATION: float = 0.43
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
    preload("res://scripts/enemy_contrast.gd").apply(sprite, true)
    _register_inputs()
    _build_animations()
    sprite.play("idle_up")
    health_changed.emit(health, max_health)

func _physics_process(delta: float) -> void:
    dash_cooldown_left = maxf(0.0, dash_cooldown_left - delta)
    action_time_left = maxf(0.0, action_time_left - delta)
    if input_locked:
        if lake_jump_elapsed > 0.0:
            global_position = lake_jump_from
            lake_jump_elapsed = 0.0
            sprite.position.y = -58.0
            $Shadow.visible = true
        velocity = Vector2.ZERO
        dash_time_left = 0.0
        _play("idle")
        return

    if lake_jump_elapsed > 0.0:
        lake_jump_elapsed = minf(LAKE_JUMP_DURATION, lake_jump_elapsed + delta)
        var fraction: float = lake_jump_elapsed / LAKE_JUMP_DURATION
        global_position = lake_jump_from.lerp(lake_jump_to, fraction)
        sprite.position.y = -58.0 - sin(fraction * PI) * 46.0
        velocity = Vector2.ZERO
        _play("dash")
        if fraction >= 1.0:
            lake_jump_elapsed = 0.0
            sprite.position.y = -58.0
            $Shadow.visible = true
        return

    var input_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    if input_vector.length_squared() > 0.005 and dash_time_left <= 0.0:
        last_motion = input_vector.normalized()
        face = _direction(last_motion)

    if Input.is_action_just_pressed("interact"):
        _start_action("interact", 0.27)
        interaction_requested.emit()
    if Input.is_action_just_pressed("hint"):
        hint_requested.emit()
    if Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("verse"):
        if not combat_enabled:
            if not blocked_attack_notified:
                message_requested.emit("En el Limbo no se combate. Aquí importan la memoria y las decisiones.")
                blocked_attack_notified = true
        else:
            _start_action("ready", 0.26)
            message_requested.emit("Los ataques de Dante están reservados para los siguientes círculos.")
    if Input.is_action_just_pressed("dash") and dash_cooldown_left <= 0.0 and dash_time_left <= 0.0:
        if input_vector.length_squared() > 0.01:
            last_motion = input_vector.normalized()
        if is_instance_valid(navigation):
            var landing: Vector2 = navigation.lake_jump_target(global_position, last_motion)
            if landing != global_position:
                lake_jump_from = global_position
                lake_jump_to = landing
                lake_jump_elapsed = 0.0001
                dash_started.emit()
                dash_cooldown_left = dash_cooldown * (0.90 if Game.has_relic("limbo") else 1.0)
                face = _direction(last_motion)
                $Shadow.visible = false
                _play("dash", true)
                return
        dash_time_left = dash_duration
        dash_started.emit()
        dash_cooldown_left = dash_cooldown * (0.90 if Game.has_relic("limbo") else 1.0)
        face = _direction(last_motion)

    if dash_time_left > 0.0:
        velocity = last_motion * dash_speed
        dash_time_left = maxf(0.0, dash_time_left - delta)
        _play("dash")
    elif action_time_left > 0.0:
        velocity = input_vector * (speed * 0.44)
        _play(action_name)
    else:
        velocity = input_vector * speed
        _play("walk" if input_vector.length_squared() > 0.005 else "idle")
    var before := global_position
    if is_instance_valid(navigation):
        # Substeps keep the dash from crossing a pond or a thin map boundary.
        var displacement: Vector2 = velocity * delta
        var steps: int = maxi(1, ceili(displacement.length() / 7.0))
        var step: Vector2 = displacement / float(steps)
        var can_enter: Callable = Callable(navigation, "can_walk").bind(10.0)
        for i in range(steps):
            global_position = WALK_SOLVER.step(global_position, step, can_enter)
    else:
        move_and_slide()
    step_travel += before.distance_to(global_position)
    if step_travel >= 31.0:
        step_travel = 0.0
        AudioManager.cue("paso")

func _start_action(name: String, seconds: float) -> void:
    action_name = name
    action_time_left = seconds
    _play(name, true)

func _direction(direction: Vector2) -> String:
    if absf(direction.x) >= absf(direction.y):
        return "right" if direction.x > 0.0 else "left"
    return "down" if direction.y > 0.0 else "up"

func _play(name: String, force_restart: bool = false) -> void:
    var key: String = name + "_" + face
    if sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(key):
        return
    if force_restart or sprite.animation != key or not sprite.is_playing():
        sprite.play(key)

func dash_ready_fraction() -> float:
    return 1.0 - clampf(dash_cooldown_left / dash_cooldown, 0.0, 1.0)

func _build_animations() -> void:
    sprite.sprite_frames = preload("res://scripts/sprite_library.gd").dante()

func _register_inputs() -> void:
    _key("move_left", KEY_A)
    _key("move_left", KEY_LEFT)
    _key("move_right", KEY_D)
    _key("move_right", KEY_RIGHT)
    _key("move_up", KEY_W)
    _key("move_up", KEY_UP)
    _key("move_down", KEY_S)
    _key("move_down", KEY_DOWN)
    _key("interact", KEY_E)
    _key("hint", KEY_Q)
    _key("dash", KEY_SPACE)
    _key("attack", KEY_J)
    _key("verse", KEY_K)

func _key(action: String, code: int) -> void:
    if not InputMap.has_action(action):
        InputMap.add_action(action)
    var event: InputEventKey = InputEventKey.new()
    event.physical_keycode = code
    if not InputMap.action_has_event(action, event):
        InputMap.action_add_event(action, event)
