extends CharacterBody2D
const WALK_SOLVER = preload("res://scripts/walk_solver.gd")
## Dante: movement in eight directions, dash, invulnerability, melee and luminous verse.
signal health_changed(current: int, maximum: int)
signal exhausted
signal combat_action(kind: String)

@export var move_speed := 188.0
@export var dash_speed := 430.0
@export var max_health := 6
@export var dash_duration := 0.18
@export var dash_invulnerability := 0.28
@export var dash_cooldown_duration := 0.85

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
    preload("res://scripts/enemy_contrast.gd").apply(art, true)
    _install_inputs()
    _create_animations()
    if bool(Game.progress.get("dash_extended", false)):
        dash_duration = 0.25
        dash_invulnerability = 0.42
        dash_cooldown_duration = 0.65
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
        dash_time = dash_duration
        dash_recharge = dash_cooldown_duration
        invulnerable = maxf(invulnerable, dash_invulnerability)
        combat_action.emit("esquivar")
    if Input.is_action_just_pressed("strike") and strike_recharge <= 0.0:
        strike_recharge = 0.43
        pose_time = 0.23
        combat_action.emit("golpe")
        if is_instance_valid(world):
            world.melee_hit(global_position, facing)
            preload("res://scripts/combat_fx.gd").burst(self, global_position, facing, 67.0, Color("baffed"))
    if Input.is_action_just_pressed("verse") and verse_recharge <= 0.0:
        verse_recharge = 0.62
        pose_time = 0.22
        combat_action.emit("verso")
        if is_instance_valid(world):
            world.spawn_projectile(global_position + facing * 26.0, facing, false, 2)
    var wind := Vector2.ZERO
    if is_instance_valid(world):
        wind = world.wind_at(global_position)
    # El viento modifica la trayectoria sin quitarle el control al jugador.
    # En reposo no arrastra a Dante contra paredes o enemigos.
    var terrain_factor := 1.0
    if is_instance_valid(world) and world.has_method("movement_factor"):
        terrain_factor = float(world.movement_factor(global_position))
    velocity = facing * dash_speed * terrain_factor if dash_time > 0.0 else axis * move_speed * terrain_factor + (wind * 0.36 if axis.length_squared() > 0.01 else Vector2.ZERO)
    var displacement: Vector2 = velocity * delta
    var steps: int = maxi(1, ceili(displacement.length() / 7.0))
    var step: Vector2 = displacement / float(steps)
    var can_enter: Callable = Callable(world, "can_occupy_hero").bind(dash_time > 0.0) if is_instance_valid(world) else Callable()
    for i in range(steps):
        global_position = WALK_SOLVER.step(global_position, step, can_enter) if is_instance_valid(world) else global_position + step
    if is_instance_valid(world) and world.can_walk(global_position, 10.0):
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
    art.sprite_frames = preload("res://scripts/sprite_library.gd").dante()

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
