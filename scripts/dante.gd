extends CharacterBody2D
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
var max_health: int = 3
var health: int = 3
var face: String = "up"
var last_motion: Vector2 = Vector2.UP
var dash_time_left: float = 0.0
var dash_cooldown_left: float = 0.0
var action_time_left: float = 0.0
var action_name: String = ""
var blocked_attack_notified: bool = false
const DIRS = ["down", "left", "up", "right"]
const COUNTS: Dictionary = {"idle": 4, "walk": 8, "dash": 4, "interact": 4, "ready": 4}
const FRAME_WIDTH: int = 80
const FRAME_HEIGHT: int = 96
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
    _register_inputs()
    _build_animations()
    sprite.play("idle_up")
    health_changed.emit(health, max_health)

func _physics_process(delta: float) -> void:
    dash_cooldown_left = maxf(0.0, dash_cooldown_left - delta)
    action_time_left = maxf(0.0, action_time_left - delta)
    if input_locked:
        velocity = Vector2.ZERO
        _play("idle")
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
        dash_time_left = dash_duration
        dash_started.emit()
        dash_cooldown_left = dash_cooldown
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
    move_and_slide()

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
    var library: SpriteFrames = SpriteFrames.new()
    for state in COUNTS.keys():
        var texture: Texture2D = load("res://assets/dante/" + str(state) + ".png") as Texture2D
        if texture == null:
            push_error("Falta spritesheet: " + str(state))
            continue
        var count: int = int(COUNTS[state])
        for direction_index in range(4):
            var key: String = str(state) + "_" + DIRS[direction_index]
            library.add_animation(key)
            library.set_animation_speed(key, 10.0 if state == "walk" else 8.0)
            library.set_animation_loop(key, state == "walk" or state == "idle")
            for column in range(count):
                var atlas: AtlasTexture = AtlasTexture.new()
                atlas.atlas = texture
                atlas.region = Rect2(column * FRAME_WIDTH, direction_index * FRAME_HEIGHT, FRAME_WIDTH, FRAME_HEIGHT)
                library.add_frame(key, atlas)
    sprite.sprite_frames = library

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
