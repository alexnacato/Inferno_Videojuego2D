extends CharacterBody2D
const WALK_SOLVER = preload("res://scripts/walk_solver.gd")
const READABILITY_SHADER = preload("res://assets/lujuria/enemies/enemy_readability.gdshader")
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
const VISUAL_SCALE := {"diablillo": 0.60, "carcelero": 0.82, "espectro": 0.72, "furia": 0.78, "minos": 0.93}
const COLORS := {
	"diablillo": Color("e9a484"),
	"carcelero": Color("aa8ec6"),
	"espectro": Color("b793e5"),
	"furia": Color("e477a5"),
	"minos": Color("d6b78a"),
}
const BODY_TINT := {
	"diablillo": Color(1.13, 0.93, 0.88),
	"carcelero": Color(1.06, 0.98, 1.15),
	"espectro": Color(1.10, 0.98, 1.20),
	"furia": Color(1.13, 0.90, 1.04),
	"minos": Color(1.10, 1.04, 0.94),
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
var attack_cooldown := 1.1
var windup := 0.0
var recovery := 0.0
var stagger := 0.0
var fade_time := 0.0
var attack_target := Vector2.DOWN
var phase := 1
var knockback := Vector2.ZERO
var body_radius := 17.0
var route: PackedVector2Array = PackedVector2Array()
var route_time := 0.0
var alert_left := 0.0
var last_seen := Vector2.ZERO
var patrol_target := Vector2.ZERO
var patrol_wait := 0.0
var patrol_index := 0
var move_velocity := Vector2.ZERO
var stride := 0.0
@onready var art: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	preload("res://scripts/enemy_contrast.gd").apply(art)
	if not STATS.has(archetype):
		archetype = "diablillo"
	max_hp = int(STATS[archetype]["hp"])
	hp = max_hp
	anchor = global_position
	last_seen = anchor
	patrol_target = anchor
	var shape := CircleShape2D.new()
	body_radius = float(STATS[archetype]["radius"])
	shape.radius = body_radius
	$CollisionShape2D.shape = shape
	var scale_factor: float = float(VISUAL_SCALE[archetype])
	art.scale = Vector2.ONE * scale_factor
	art.position.y = -(88.0 if archetype == "minos" else 72.0) * scale_factor
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_setup_animations()
	var material := ShaderMaterial.new()
	material.shader = READABILITY_SHADER
	var accent: Color = COLORS[archetype]
	accent.a = 0.60 if archetype == "espectro" else 0.52
	material.set_shader_parameter("edge_color", accent)
	material.set_shader_parameter("body_tint", BODY_TINT[archetype])
	art.material = material
	art.play("idle")
	queue_redraw()

func _physics_process(delta: float) -> void:
	if dead:
		fade_time += delta
		if fade_time > 0.75:
			queue_free()
		return
	if not active or not is_instance_valid(hero) or not is_instance_valid(world) or not world.game_active:
		return
	attack_cooldown = maxf(attack_cooldown - delta, 0.0)
	recovery = maxf(recovery - delta, 0.0)
	stagger = maxf(stagger - delta, 0.0)
	knockback = knockback.move_toward(Vector2.ZERO, 410.0 * delta)
	route_time = maxf(0.0, route_time - delta)
	alert_left = maxf(0.0, alert_left - delta)
	patrol_wait = maxf(0.0, patrol_wait - delta)
	var delta_to_hero: Vector2 = hero.global_position - global_position
	var dist: float = delta_to_hero.length()
	var stats: Dictionary = STATS[archetype]
	if archetype == "minos" and phase == 1 and hp <= max_hp / 2:
		phase = 2
		world.notify("¡Minos ha desatado la segunda tempestad!")
	var guarding: bool = archetype == "minos" and (anchor.distance_to(hero.global_position) > 370.0 or not Geometry2D.is_point_in_polygon(hero.global_position, world.upper_court))
	var can_see_hero: bool = not guarding and dist < 420.0 and world.has_clear_path(global_position, hero.global_position, 5.0)
	if can_see_hero:
		last_seen = hero.global_position
		alert_left = 2.5
	elif archetype != "minos" and dist < 505.0 and alert_left <= 0.0:
		# Un ruido puede iniciar la búsqueda; tras ello solo la vista actualiza el objetivo.
		last_seen = hero.global_position
		alert_left = 2.5
	var desired_motion := Vector2.ZERO
	if stagger > 0.0:
		windup = 0.0
	elif windup > 0.0:
		windup -= delta
		if windup <= 0.0:
			_release_attack()
	elif recovery <= 0.0:
		if can_see_hero and attack_cooldown <= 0.0 and dist <= float(stats["range"]):
			windup = 0.58 if archetype == "minos" else 0.48 if archetype == "carcelero" else 0.43 if archetype == "furia" else 0.38
			var aim: Vector2 = hero.global_position
			if archetype in ["diablillo", "espectro"]:
				aim += hero.velocity.limit_length(220.0) * (0.13 if archetype == "diablillo" else 0.20)
			attack_target = global_position.direction_to(aim)
			if attack_target.length_squared() < 0.001:
				attack_target = Vector2.DOWN
		elif archetype == "minos" and guarding:
			if global_position.distance_to(anchor) > 18.0:
				desired_motion = _steer(anchor) * float(stats["speed"])
		elif alert_left > 0.0:
			var destination: Vector2 = hero.global_position if can_see_hero else last_seen
			if archetype == "espectro" and can_see_hero:
				if dist < 125.0:
					var retreat: Vector2 = global_position - delta_to_hero.normalized() * 85.0
					if world.can_walk(retreat, body_radius) and world.has_clear_path(global_position, retreat, body_radius):
						destination = retreat
				elif dist < 185.0:
					destination = global_position
			if archetype == "diablillo" and can_see_hero and dist > 105.0 and dist < 320.0:
				var side: float = -1.0 if spawn_id.hash() % 2 == 0 else 1.0
				var flank: Vector2 = destination + delta_to_hero.normalized().orthogonal() * side * 52.0
				if world.can_walk(flank, body_radius):
					destination = flank
			if global_position.distance_to(destination) > 12.0:
				desired_motion = _steer(destination) * float(stats["speed"])
			elif not can_see_hero:
				alert_left = 0.0
		elif global_position.distance_to(anchor) > 20.0:
			desired_motion = _steer(anchor) * float(stats["speed"])
		elif archetype != "minos":
			if patrol_wait <= 0.0:
				_choose_patrol_target()
			if global_position.distance_to(patrol_target) > 12.0:
				desired_motion = _steer(patrol_target) * float(stats["speed"]) * 0.38
	var acceleration: float = 860.0 if archetype == "diablillo" else 460.0 if archetype == "carcelero" else 650.0 if archetype == "espectro" else 740.0 if archetype == "furia" else 350.0
	move_velocity = move_velocity.move_toward(desired_motion, acceleration * delta)
	var wind: Vector2 = world.wind_at(global_position) * (0.17 if archetype == "minos" else 0.35)
	var displacement: Vector2 = (move_velocity + wind + knockback) * delta
	var steps: int = maxi(1, ceili(displacement.length() / 7.0))
	var step: Vector2 = displacement / float(steps)
	var can_enter: Callable = Callable(world, "can_occupy_enemy").bind(self, body_radius)
	var before_move: Vector2 = global_position
	for i in range(steps):
		global_position = WALK_SOLVER.step(global_position, step, can_enter)
	if route.size() > 0 and global_position.distance_to(route[0]) < 18.0:
		route.remove_at(0)
	var traveled: Vector2 = global_position - before_move
	velocity = traveled / delta if delta > 0.0 else Vector2.ZERO
	move_velocity = velocity - wind - knockback
	var walking: bool = desired_motion.length_squared() > 4.0 and traveled.length_squared() > 0.08
	if walking and absf(traveled.x) > 0.2:
		art.flip_h = traveled.x < 0.0
	if walking:
		stride += traveled.length() * (0.23 if archetype == "diablillo" else 0.11 if archetype == "carcelero" else 0.19 if archetype == "espectro" else 0.17 if archetype == "furia" else 0.09)
	var base_y: float = -(88.0 if archetype == "minos" else 72.0) * art.scale.y
	art.position.y = base_y - (absf(sin(stride)) * (1.6 if archetype == "carcelero" or archetype == "minos" else 1.0) if walking else 0.0)
	art.modulate = Color(1.0, 0.70, 0.76) if stagger > 0.0 else Color(1.10, 0.86, 1.03) if archetype == "minos" and phase == 2 else Color.WHITE
	art.speed_scale = clampf(velocity.length() / maxf(float(stats["speed"]), 1.0), 0.75, 1.25) if walking else 1.0
	if stagger > 0.0:
		_play("hurt")
	elif recovery > 0.0:
		_play("attack")
	elif walking:
		_play("walk")
	else:
		_play("idle")
	queue_redraw()

func _choose_patrol_target() -> void:
	patrol_index += 1
	patrol_wait = 2.0
	var angle: float = float(posmod(spawn_id.hash(), 360)) * PI / 180.0 + float(patrol_index) * 2.3
	var patrol_radius: float = 28.0 if archetype == "carcelero" else 46.0
	patrol_target = anchor
	for attempt in range(8):
		var candidate: Vector2 = anchor + Vector2.RIGHT.rotated(angle + float(attempt) * TAU / 8.0) * patrol_radius
		if world.can_walk(candidate, body_radius) and world.has_clear_path(global_position, candidate, body_radius):
			patrol_target = candidate
			break

func _steer(destination: Vector2) -> Vector2:
	if world.has_clear_path(global_position, destination, body_radius):
		route.clear()
		return global_position.direction_to(destination)
	if route_time <= 0.0:
		route = world.route_to(global_position, destination, body_radius)
		route_time = 0.42
	while not route.is_empty() and global_position.distance_to(route[0]) < 18.0:
		route.remove_at(0)
	return global_position.direction_to(route[0]) if not route.is_empty() else Vector2.ZERO

func _release_attack() -> void:
	preload("res://scripts/combat_fx.gd").burst(self, global_position, attack_target, 70.0, Color("e6a0ff"))
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
		if is_instance_valid(hero) and global_position.distance_to(hero.global_position) < 105.0 and world.has_clear_path(global_position, hero.global_position) and attack_target.dot(global_position.direction_to(hero.global_position)) > 0.2:
			hero.take_damage(int(stats["damage"]))
			world.notify("Las cadenas de un carcelero alcanzan a Dante")
	else:
		if is_instance_valid(hero) and global_position.distance_to(hero.global_position) < float(stats["range"]) + 14.0 and world.has_clear_path(global_position, hero.global_position) and attack_target.dot(global_position.direction_to(hero.global_position)) > 0.4:
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
		alert_left = 3.0
		last_seen = hero.global_position if is_instance_valid(hero) else anchor

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
	draw_ellipse_shadow(maxf(radius + 5.0, (176.0 if archetype == "minos" else 128.0) * art.scale.x * 0.35))
	if dead:
		return
	var accent: Color = COLORS[archetype]
	if alert_left > 0.0 and archetype != "minos":
		accent.a = 0.27
		draw_arc(Vector2.ZERO, radius + 8.0, 0.0, TAU, 32, accent, 1.5)
	if archetype != "minos" and (hp < max_hp or is_instance_valid(hero) and global_position.distance_to(hero.global_position) < 310.0):
		var width: float = 96.0 if archetype == "minos" else clampf(80.0 * art.scale.x, 48.0, 68.0)
		var top: float = art.position.y - (88.0 if archetype == "minos" else 72.0) * art.scale.y - 12.0
		draw_rect(Rect2(-width / 2.0 - 2.0, top - 2.0, width + 4.0, 11.0), Color(0.06, 0.04, 0.09, 0.92))
		draw_rect(Rect2(-width / 2.0, top, width, 7.0), Color(0.30, 0.20, 0.33, 0.95))
		draw_rect(Rect2(-width / 2.0, top, width * float(hp) / float(max_hp), 7.0), COLORS[archetype])
		draw_line(Vector2(-width / 2.0, top + 1.0), Vector2(-width / 2.0 + width * float(hp) / float(max_hp), top + 1.0), Color(1.0, 0.9, 1.0, 0.55), 1.0)

func draw_ellipse_shadow(radius: float) -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.34))
	draw_circle(Vector2.ZERO, radius + 8.0, Color(0.05, 0.01, 0.08, 0.45))
	draw_set_transform(Vector2.ZERO)
