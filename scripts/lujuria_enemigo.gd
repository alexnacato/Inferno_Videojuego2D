extends CharacterBody2D
## Reusable combat controller: 5 enemy archetypes, telegraphed attacks and boss phases.
signal died(spawn_id: String, archetype: String)
signal hp_changed(current: int, maximum: int)

const STATS := {
	"diablillo": {"hp": 5, "speed": 116.0, "range": 63.0, "cooldown": 1.65, "damage": 1, "radius": 16.0, "name": "Diablillo del Vendaval"},
	"carcelero": {"hp": 10, "speed": 74.0, "range": 85.0, "cooldown": 2.25, "damage": 2, "radius": 23.0, "name": "Carcelero de las Cadenas"},
	"espectro": {"hp": 6, "speed": 103.0, "range": 230.0, "cooldown": 2.1, "damage": 1, "radius": 17.0, "name": "Espectro del Remolino"},
	"furia": {"hp": 13, "speed": 107.0, "range": 77.0, "cooldown": 1.85, "damage": 2, "radius": 22.0, "name": "Furia del Anhelo"},
	"minos": {"hp": 38, "speed": 55.0, "range": 250.0, "cooldown": 2.9, "damage": 2, "radius": 35.0, "name": "Minos, juez de los deseos"},
}
@export_enum("diablillo", "carcelero", "espectro", "furia", "minos") var archetype := "diablillo"
@export var spawn_id := "foe_0"
var world
var hero
var anchor := Vector2.ZERO
var hp := 1
var max_hp := 1
var active := false
var dead := false
var move_dir := Vector2.DOWN
var attack_cooldown := 1.1
var windup := 0.0
var recovery := 0.0
var stagger := 0.0
var fade_time := 0.0
var attack_target := Vector2.DOWN
var phase := 1
var knockback := Vector2.ZERO
var ai_time := 0.0
var roaming_offset := Vector2.ZERO
@onready var art: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	if not STATS.has(archetype):
		archetype = "diablillo"
	max_hp = int(STATS[archetype]["hp"])
	hp = max_hp
	anchor = global_position
	var shape := CircleShape2D.new()
	shape.radius = float(STATS[archetype]["radius"])
	$CollisionShape2D.shape = shape
	art.position.y = -82.0 if archetype == "minos" else -67.0
	art.scale = Vector2(1.05, 1.05) if archetype == "minos" else Vector2(0.83, 0.83)
	_setup_animations()
	art.play("idle")
	queue_redraw()

func _physics_process(delta: float) -> void:
	if dead:
		fade_time += delta
		if fade_time > 0.68:
			queue_free()
		return
	if not active or not is_instance_valid(hero) or not is_instance_valid(world) or not world.game_active:
		return
	attack_cooldown = maxf(attack_cooldown - delta, 0.0)
	recovery = maxf(recovery - delta, 0.0)
	stagger = maxf(stagger - delta, 0.0)
	knockback = knockback.move_toward(Vector2.ZERO, 410.0 * delta)
	ai_time += delta
	var delta_to_hero: Vector2 = hero.global_position - global_position
	var dist: float = delta_to_hero.length()
	var stats: Dictionary = STATS[archetype]
	var motion := Vector2.ZERO
	if dist < 505.0 and stagger <= 0.0 and recovery <= 0.0:
		if windup > 0.0:
			windup -= delta
			if windup <= 0.0:
				_release_attack()
		elif attack_cooldown <= 0.0 and dist <= float(stats["range"]):
			windup = 0.58 if archetype == "minos" else 0.37
			attack_target = delta_to_hero.normalized()
			if attack_target.length_squared() < 0.001:
				attack_target = Vector2.DOWN
		elif dist > float(stats["range"]) * (0.77 if archetype == "espectro" else 0.72):
			motion = delta_to_hero.normalized() * float(stats["speed"])
		elif archetype == "espectro" and dist < 115.0:
			motion = -delta_to_hero.normalized() * 57.0
	var wind: Vector2 = world.wind_at(global_position) * (0.27 if archetype == "minos" else 0.50)
	velocity = motion + wind + knockback
	var old := global_position
	var target := old + velocity * delta
	var radius: float = float(stats["radius"])
	if world.can_walk(Vector2(target.x, old.y), radius):
		global_position.x = target.x
	if world.can_walk(Vector2(global_position.x, target.y), radius):
		global_position.y = target.y
	if motion.length_squared() > 1.0:
		move_dir = motion.normalized()
	if stagger > 0.0:
		_play("hurt")
	elif windup > 0.0 or recovery > 0.0:
		_play("attack")
	elif motion.length_squared() > 10.0:
		_play("walk")
	else:
		_play("idle")
	if archetype == "minos" and phase == 1 and hp <= max_hp / 2:
		phase = 2
		world.notify("¡Minos ha desatado la segunda tempestad!")
	queue_redraw()

func _release_attack() -> void:
	if dead or not is_instance_valid(world):
		return
	var stats: Dictionary = STATS[archetype]
	var cooldown_scale := 0.72 if archetype == "minos" and phase == 2 else 1.0
	attack_cooldown = float(stats["cooldown"]) * cooldown_scale
	recovery = 0.34
	var toward: Vector2 = attack_target.normalized()
	if archetype == "espectro":
		world.spawn_projectile(global_position + toward * 28.0, toward, true, 1)
	elif archetype == "minos":
		var count := 7 if phase == 2 else 5
		for i in range(count):
			var arc: float = lerpf(-0.69, 0.69, float(i) / float(count - 1))
			world.spawn_projectile(global_position + toward * 34.0, toward.rotated(arc), true, int(stats["damage"]))
		if phase == 2:
			world.pulse_wind(global_position, 290.0)
	elif archetype == "carcelero":
		if is_instance_valid(hero) and global_position.distance_to(hero.global_position) < 105.0:
			hero.take_damage(int(stats["damage"]))
			world.notify("Las cadenas de un carcelero alcanzan a Dante")
	else:
		if is_instance_valid(hero) and global_position.distance_to(hero.global_position) < float(stats["range"]) + 14.0:
			hero.take_damage(int(stats["damage"]))
		if archetype == "furia":
			world.pulse_wind(global_position, 120.0)

func take_damage(amount: int, from_direction: Vector2 = Vector2.DOWN) -> void:
	if dead or not active:
		return
	hp = maxi(0, hp - maxi(0, amount))
	stagger = 0.19
	knockback = from_direction.normalized() * (90.0 if archetype == "minos" else 175.0)
	hp_changed.emit(hp, max_hp)
	if hp <= 0:
		dead = true
		collision_layer = 0
		collision_mask = 0
		_play("death")
		died.emit(spawn_id, archetype)
	else:
		_play("hurt")

func _play(name: String) -> void:
	if art.sprite_frames != null and art.sprite_frames.has_animation(name):
		if art.animation != name or not art.is_playing():
			art.play(name)

func _setup_animations() -> void:
	var lib := SpriteFrames.new()
	var size := Vector2(176.0, 176.0) if archetype == "minos" else Vector2(128.0, 144.0)
	for action in ["idle", "walk", "attack", "hurt", "death"]:
		var path: String = "res://assets/lujuria/enemies/%s/%s.png" % [archetype, action]
		var texture: Texture2D = load(path)
		if texture == null:
			continue
		lib.add_animation(action)
		lib.set_animation_speed(action, 7.0 if action != "walk" else 9.0)
		lib.set_animation_loop(action, action == "idle" or action == "walk")
		var count: int = maxi(1, int(texture.get_width() / size.x))
		for i in range(count):
			var frame := AtlasTexture.new()
			frame.atlas = texture
			frame.region = Rect2(i * size.x, 0.0, size.x, size.y)
			lib.add_frame(action, frame)
	art.sprite_frames = lib

func _draw() -> void:
	var radius: float = float(STATS[archetype]["radius"])
	draw_ellipse_shadow(radius)
	if dead:
		return
	if windup > 0.0:
		draw_arc(Vector2.ZERO, float(STATS[archetype]["range"]) * (0.8 if archetype == "minos" else 0.55), 0, TAU, 42, Color(0.82, 0.42, 0.94, 0.45), 2.4)
		draw_line(Vector2.ZERO, attack_target * 65.0, Color(0.85, 0.47, 0.94, 0.75), 3.0)
	if hp < max_hp:
		var width := 70.0 if archetype == "minos" else 46.0
		draw_rect(Rect2(-width / 2.0, -112.0 if archetype == "minos" else -88.0, width, 6), Color(0.14, 0.07, 0.16, 0.9))
		draw_rect(Rect2(-width / 2.0, -112.0 if archetype == "minos" else -88.0, width * float(hp) / float(max_hp), 6), Color("b77dcf"))

func draw_ellipse_shadow(radius: float) -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.34))
	draw_circle(Vector2.ZERO, radius + 8.0, Color(0.05, 0.01, 0.08, 0.45))
	draw_set_transform(Vector2.ZERO)
