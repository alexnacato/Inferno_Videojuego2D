extends CharacterBody2D
## Dante: movement in eight directions, dash, invulnerability, melee and luminous verse.
signal health_changed(current: int, maximum: int)
signal exhausted
signal combat_action(kind: String)

const ACTIONS := {"idle": 4, "walk": 8, "dash": 4, "ready": 4}
const DIRECTIONS := ["down", "left", "up", "right"]
const FRAME := Vector2(80, 96)
@export var move_speed := 188.0
@export var dash_speed := 430.0
@export var max_health := 6

var health := 6
var world
var control_enabled := false
var facing := Vector2.DOWN
var face_name := "down"
var dash_time := 0.0
var dash_recharge := 0.0
var strike_recharge := 0.0
var verse_recharge := 0.0
var invulnerable := 0.0
var pose_time := 0.0
var last_safe_position := Vector2(723, 977)
@onready var art: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
    _install_inputs()
    _create_animations()
    health = max_health
    art.play("idle_down")
    health_changed.emit(health, max_health)

func _physics_process(delta: float) -> void:
    dash_time = maxf(0.0, dash_time - delta)
    dash_recharge = maxf(0.0, dash_recharge - delta)
    strike_recharge = maxf(0.0, strike_recharge - delta)
    verse_recharge = maxf(0.0, verse_recharge - delta)
    invulnerable = maxf(0.0, invulnerable - delta)
    pose_time = maxf(0.0, pose_time - delta)
    if not control_enabled:
        velocity = Vector2.ZERO
        _play("idle")
        return
    var axis: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    if axis.length_squared() > 0.005 and dash_time <= 0.0:
        facing = axis.normalized()
        face_name = _facing_key(facing)
    if Input.is_action_just_pressed("dodge") and dash_recharge <= 0.0:
        if axis.length_squared() > 0.001:
            facing = axis.normalized()
        dash_time = 0.18
        dash_recharge = 0.85
        invulnerable = maxf(invulnerable, 0.28)
        combat_action.emit("esquivar")
    if Input.is_action_just_pressed("strike") and strike_recharge <= 0.0:
        strike_recharge = 0.43
        pose_time = 0.23
        combat_action.emit("golpe")
        if is_instance_valid(world):
            world.melee_hit(global_position, facing)
    if Input.is_action_just_pressed("verse") and verse_recharge <= 0.0:
        verse_recharge = 0.62
        pose_time = 0.22
        combat_action.emit("verso")
        if is_instance_valid(world):
            world.spawn_projectile(global_position + facing * 26.0, facing, false, 2)
    var wind := Vector2.ZERO
    if is_instance_valid(world):
        wind = world.wind_at(global_position)
    velocity = facing * dash_speed if dash_time > 0.0 else axis * move_speed + wind
    # World walk mask prevents falling into painted chasms while allowing axis sliding.
    var start := global_position
    var target := start + velocity * delta
    if not is_instance_valid(world):
        global_position = target
    else:
        if world.can_walk(Vector2(target.x, start.y), 12.0):
            global_position.x = target.x
        if world.can_walk(Vector2(global_position.x, target.y), 12.0):
            global_position.y = target.y
        if world.can_walk(global_position, 12.0):
            last_safe_position = global_position
    if dash_time > 0.0:
        _play("dash")
    elif pose_time > 0.0:
        _play("ready")
    elif axis.length_squared() > 0.01:
        _play("walk")
    else:
        _play("idle")
    art.modulate = Color(1.0, 0.67, 0.86, 0.82) if invulnerable > 0.0 else Color.WHITE

func take_damage(damage: int) -> void:
    if invulnerable > 0.0 or health <= 0:
        return
    health = maxi(health - maxi(damage, 0), 0)
    invulnerable = 0.85
    health_changed.emit(health, max_health)
    if health <= 0:
        control_enabled = false
        exhausted.emit()

func restore(new_health: int, checkpoint: Vector2) -> void:
    health = clampi(new_health, 1, max_health)
    global_position = checkpoint
    last_safe_position = checkpoint
    invulnerable = 1.25
    dash_time = 0.0
    health_changed.emit(health, max_health)

func heal(amount: int) -> void:
    health = mini(max_health, health + amount)
    health_changed.emit(health, max_health)

func _facing_key(v: Vector2) -> String:
    if absf(v.x) > absf(v.y):
        return "right" if v.x > 0.0 else "left"
    return "down" if v.y > 0.0 else "up"

func _play(state: String) -> void:
    var anim: String = state + "_" + face_name
    if art.sprite_frames != null and art.sprite_frames.has_animation(anim):
        if art.animation != anim or not art.is_playing():
            art.play(anim)

func _create_animations() -> void:
    var frames := SpriteFrames.new()
    for action in ACTIONS.keys():
        var texture: Texture2D = load("res://assets/dante/%s.png" % action)
        if texture == null:
            continue
        for direction_i in range(4):
            var anim: String = str(action) + "_" + DIRECTIONS[direction_i]
            frames.add_animation(anim)
            frames.set_animation_speed(anim, 9.0 if str(action) == "walk" else 7.0)
            frames.set_animation_loop(anim, str(action) == "idle" or str(action) == "walk")
            for i in range(int(ACTIONS[action])):
                var piece := AtlasTexture.new()
                piece.atlas = texture
                piece.region = Rect2(i * FRAME.x, direction_i * FRAME.y, FRAME.x, FRAME.y)
                frames.add_frame(anim, piece)
    art.sprite_frames = frames

func _install_inputs() -> void:
    var bindings := {
        "move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
        "move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
        "dodge": [KEY_SPACE], "strike": [KEY_J], "verse": [KEY_K],
        "interact": [KEY_E], "hint": [KEY_Q], "pause": [KEY_ESCAPE]
    }
    for action in bindings.keys():
        if not InputMap.has_action(action):
            InputMap.add_action(action)
        for code in bindings[action]:
            var event := InputEventKey.new()
            event.physical_keycode = int(code)
            if not InputMap.action_has_event(action, event):
                InputMap.action_add_event(action, event)
