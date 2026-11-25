extends "res://scripts/gula_enemigo.gd"

const ICE_TINTS := {
    "penitente": Color("#cb99ff"),
    "rastrero": Color("#78b7ff"),
    "escanciador": Color("#a4fff4"),
}
const ICE_BAR_Y := {"penitente": -152.0, "rastrero": -142.0, "escanciador": -153.0}
const ICE_ART := {
    "penitente": "custodio",
    "rastrero": "sabueso",
    "escanciador": "espectro",
}

static var animation_cache: Dictionary = {}
var uses_ice_art := false
var facing_motion := 0.0

func _steer(destination: Vector2) -> Vector2:
    if world.has_clear_path(global_position, destination, body_radius):
        route.clear()
        return global_position.direction_to(destination)
    if route_clock <= 0.0:
        route = world.route_to(global_position, destination, body_radius)
        route_clock = 0.55
    while route.size() > 1 and world.has_clear_path(global_position, route[1], body_radius):
        route.remove_at(0)
    if route.is_empty() or global_position.distance_squared_to(route[0]) < 9.0:
        return Vector2.ZERO
    return global_position.direction_to(route[0])

func _setup_animations() -> void:
    var path := "res://assets/traicion/enemies/%s.png" % ICE_ART[archetype]
    if not ResourceLoader.exists(path):
        super._setup_animations()
        return
    if not animation_cache.has(archetype):
        var texture := load(path) as Texture2D
        animation_cache[archetype] = _ice_frames(texture.get_image())
    art.sprite_frames = animation_cache[archetype]
    uses_ice_art = true

func _ice_frames(source: Image) -> SpriteFrames:
    source.convert(Image.FORMAT_RGBA8)
    var frames := SpriteFrames.new()
    var size := source.get_size()
    for action in ["idle", "walk", "attack", "hurt", "death"]:
        frames.add_animation(action)
        frames.set_animation_loop(action, action in ["idle", "walk"])
        frames.set_animation_speed(action, 12.0 if action in ["walk", "attack"] else 8.0)
        for i in range(6):
            var frame := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
            var cycle := sin(TAU * i / 6.0)
            for y in range(size.y):
                var height := float(y) / size.y
                var wave := sin(PI * height) * cycle
                var shift := roundi(wave * (2.0 if action == "idle" else 6.0 if action == "walk" else 10.0))
                if action == "death":
                    shift = roundi(height * height * i * 2.0)
                frame.blit_rect(source, Rect2i(maxi(0, -shift), y, size.x - absi(shift), 1), Vector2i(maxi(0, shift), y))
            frames.add_frame(action, ImageTexture.create_from_image(frame))
    return frames

func _physics_process(delta: float) -> void:
    var before := global_position
    var previous_flip := art.flip_h
    super._physics_process(delta)
    facing_motion = lerpf(facing_motion, (global_position.x - before.x) / maxf(delta, 0.001), minf(1.0, delta * 8.0))
    art.flip_h = facing_motion < -12.0 or (absf(facing_motion) <= 12.0 and previous_flip)
    if not is_instance_valid(world) or not world.game_active or not is_instance_valid(hero):
        return
    var tint: Color = ICE_TINTS[archetype]
    var opacity := art.modulate.a
    art.modulate = Color("#ffffff") if state == "hurt" else tint.lerp(Color.WHITE, 0.68 if uses_ice_art else 0.25)
    art.modulate.a = opacity
    if uses_ice_art and not dead and hero.control_enabled:
        var original: float = VISUAL_SCALE[archetype]
        var base: float = 0.85 if archetype == "rastrero" else 0.76
        var gait := absf(sin(stride)) if velocity.length_squared() > 1.0 else 0.0
        var stretch := 1.12 if state in ["attack", "lunge"] else 0.90 if state == "windup" else 1.0 + gait * 0.035
        art.scale = Vector2(base / stretch, base * stretch)
        art.position.y -= (base * stretch - original) * 89.0
        if archetype == "escanciador":
            art.position.y -= 5.0

func _draw() -> void:
    draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.40))
    draw_circle(Vector2.ZERO, body_radius, Color(0.02, 0.06, 0.12, 0.65))
    draw_set_transform(Vector2.ZERO)
    if dead:
        return
    var tint: Color = ICE_TINTS[archetype]
    var bar_y: float = ICE_BAR_Y[archetype]
    draw_rect(Rect2(-16.0, bar_y, 32.0, 4.0), Color("#172439"))
    draw_rect(Rect2(-16.0, bar_y, 32.0 * float(hp) / max_hp, 4.0), tint)
    if windup <= 0.0:
        return
    if archetype == "penitente":
        var angle := attack_direction.angle()
        draw_arc(Vector2.ZERO, 92.0, angle - 1.31, angle + 1.31, 24, tint, 2.0, true)
    else:
        var reach := 105.0 if archetype == "rastrero" else 145.0
        draw_line(attack_direction * body_radius, attack_direction * reach, tint, 3.0, true)
