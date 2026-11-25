extends Node2D

signal defeated
signal hp_changed(current: int, maximum: int)

const MAX_HP := 48
var max_hp := MAX_HP
var hp := MAX_HP
var active := true
var dead := false
var body_radius := 58.0
var world: Variant
var hero: Variant
var cooldown := 1.8
var windup := 0.0
var pattern := 0
var flash := 0.0
var target := Vector2.ZERO
var breathing := 0.0
var phase := 1
var exposed := false
var home := Vector2.ZERO
var motion := Vector2.ZERO
var defeat_time := 0.0
@onready var art: Sprite2D = $Sprite2D

func _ready() -> void:
    preload("res://scripts/enemy_contrast.gd").apply(art)
    var source: Texture2D = preload("res://assets/traicion/enemies/lucifer.png")
    var sprite := source.get_image()
    sprite.generate_mipmaps()
    art.texture = ImageTexture.create_from_image(sprite)
    art.scale = Vector2(0.21, 0.21)
    art.position = Vector2(0, -104)
    art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    home = global_position
    hp_changed.emit(hp, max_hp)

func _physics_process(delta: float) -> void:
    if dead:
        defeat_time += delta
        art.rotation = defeat_time * 0.25
        art.modulate.a = maxf(0.0, 1.0 - defeat_time / 0.8)
        if defeat_time >= 0.8:
            queue_free()
        return
    if dead or not active or not is_instance_valid(world) or not world.game_active or not is_instance_valid(hero):
        return
    breathing += delta
    art.position.y = -104.0 + sin(breathing * 1.55) * 3.5
    art.scale = Vector2(0.215, 0.203) if windup > 0.0 else Vector2(0.205, 0.216) if exposed else Vector2.ONE * 0.21
    flash = maxf(0.0, flash - delta)
    art.modulate = Color("#8eeaff") if flash > 0.0 else Color("#b0e8ff") if exposed else Color("#c8caff") if phase == 2 else Color.WHITE
    var distance: float = global_position.distance_to(hero.global_position)
    if windup <= 0.0 and distance < 485.0:
        var toward: Vector2 = global_position.direction_to(hero.global_position)
        var side := 1.0 if pattern % 2 == 0 else -1.0
        var chase := toward * clampf((distance - 145.0) / 90.0, -0.7, 1.0)
        var desired: Vector2 = (chase + toward.orthogonal() * side * 0.65).limit_length() * (102.0 if phase == 2 else 77.0)
        motion = motion.move_toward(desired, delta * 330.0)
        var next := preload("res://scripts/walk_solver.gd").step(global_position, motion * delta, _can_move)
        if absf(next.x - global_position.x) > 0.4:
            art.flip_h = next.x < global_position.x
        global_position = next
    else:
        motion = Vector2.ZERO
    art.material.set_shader_parameter("pose_phase", breathing * (9.0 if windup > 0.0 else 4.0))
    art.material.set_shader_parameter("pose_strength", 0.085 if windup > 0.0 else 0.045 if motion.length_squared() > 25.0 else 0.019)
    art.rotation = lerpf(art.rotation, motion.x * 0.00065 + (sin(breathing * 6.0) * 0.034 if windup > 0.0 else 0.0), minf(1.0, delta * 6.0))
    if windup > 0.0:
        windup -= delta
        if windup <= 0.0:
            _release_attack()
            pattern = (pattern + 1) % 3
            exposed = true
            cooldown = 1.6 if phase == 1 else 1.35
    else:
        cooldown -= delta
        if cooldown <= 0.0 and distance < 480.0 and world.has_clear_path(global_position, hero.global_position):
            target = hero.global_position
            exposed = false
            windup = 0.95 if phase == 1 else 0.80
    queue_redraw()

func _can_move(point: Vector2) -> bool:
    return point.distance_to(home) <= 145.0 and point.distance_to(hero.global_position) >= body_radius + 10.0 and world.can_walk(point, body_radius)

func _release_attack() -> void:
    AudioManager.cue("jefe")
    if not is_instance_valid(hero) or not is_instance_valid(world):
        return
    var distance: float = global_position.distance_to(hero.global_position)
    match pattern:
        0: # Aliento helado: abanico visible y esquivable.
            var aim: Vector2 = global_position.direction_to(target)
            if aim.is_zero_approx():
                aim = Vector2.DOWN
            var spread: Array = [-0.51, -0.34, -0.17, 0.0, 0.17, 0.34, 0.51] if phase == 2 else [-0.35, -0.17, 0.0, 0.17, 0.35]
            for angle in spread:
                world.spawn_projectile(global_position, aim.rotated(angle), true, 1)
        1: # El hielo estalla al aplicarse el daño.
            preload("res://scripts/combat_fx.gd").burst(self, target, Vector2.ZERO, 112.0, Color("#a8ecff"))
            if hero.global_position.distance_to(target) < 112.0 and world.has_clear_path(target, hero.global_position):
                hero.take_damage(2)
        2: # Golpe cercano.
            preload("res://scripts/combat_fx.gd").burst(self, global_position, Vector2.ZERO, 145.0, Color("#e1eaff"))
            if distance < 145.0 and world.has_clear_path(global_position, hero.global_position):
                hero.take_damage(2)

func take_damage(amount: int, _direction: Vector2) -> void:
    if dead or not active or not is_instance_valid(world) or not world.game_active:
        return
    AudioManager.cue("impacto")
    hp = maxi(0, hp - maxi(0, amount) * (2 if exposed else 1))
    if hp > 0 and hp <= MAX_HP / 2 and phase == 1:
        phase = 2
        world.hud.toast("LUCIFER · Fase II. El aliento abre un abanico más amplio.", 4.0)
    flash = 0.20
    hp_changed.emit(hp, max_hp)
    if hp == 0:
        dead = true
        active = false
        AudioManager.cue("muerte")
        defeated.emit()

func reset_encounter() -> void:
    hp = max_hp
    global_position = home
    motion = Vector2.ZERO
    cooldown = 1.8
    windup = 0.0
    pattern = 0
    phase = 1
    target = Vector2.ZERO
    exposed = false
    flash = 0.0
    hp_changed.emit(hp, max_hp)
    queue_redraw()

func _draw() -> void:
    if dead:
        return
    draw_set_transform(Vector2(0, 9), 0.0, Vector2(1.0, 0.37))
    draw_circle(Vector2.ZERO, body_radius, Color(0.0, 0.02, 0.05, 0.62))
    draw_set_transform(Vector2.ZERO)
    if exposed:
        draw_arc(Vector2.ZERO, body_radius + 6.0, 0.0, TAU, 40, Color("#f6ce91"), 2.0, true)
    if windup <= 0.0:
        return
    var warning := Color(0.55, 0.90, 1.0, 0.75)
    if pattern == 0:
        var aim := global_position.direction_to(target)
        var spread := 0.51 if phase == 2 else 0.35
        for angle in [-spread, spread]:
            var ray := aim.rotated(angle)
            draw_line(ray * body_radius, ray * 155.0, warning, 2.0, true)
    else:
        var center := to_local(target) if pattern == 1 else Vector2.ZERO
        var reach := 112.0 if pattern == 1 else 145.0
        draw_circle(center, reach, Color(warning, 0.13))
        draw_arc(center, reach, 0.0, TAU, 64, warning, 2.0, true)
