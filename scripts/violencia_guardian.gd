extends "res://scripts/violencia_enemy.gd"
## Enemigos exclusivos de los pilares; conservan el contrato de daño/guardado del jefe.
const ART = preload("res://scripts/sprite_library.gd")
const CONFIG := {
    "centauro": {"hp":8,"radius":24.0,"speed":100.0,"size":Vector2i(150,146)},
    "mastin": {"hp":6,"radius":21.0,"speed":147.0,"size":Vector2i(132,106)},
    "ceniza": {"hp":9,"radius":23.0,"speed":80.0,"size":Vector2i(110,148)}
}
var facing := "down"
var attack_kind := ""
var attack_cycle := 0
var dash_hit := false
var home := Vector2.ZERO
var motion_action := "idle"

func _ready() -> void:
    motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
    collision_layer = 2
    collision_mask = 0
    boss = false
    var config: Dictionary = CONFIG[archetype]
    max_hp = config["hp"]
    hp = max_hp
    AudioManager.foe_voice(archetype, uid)
    body_radius = config["radius"]
    anchor = position
    home = position
    cooldown = 1.1
    var sprite := AnimatedSprite2D.new()
    var canvas: Vector2i = config["size"]
    var library: SpriteFrames = build_library()
    sprite.sprite_frames = library
    sprite.scale = Vector2.ONE * (1.30 if archetype in ["mastin", "ceniza"] else 1.06)
    sprite.position.y = -float(canvas.y) * sprite.scale.y / 2.0 + 4.0
    sprite.play("idle_down")
    art = sprite
    add_child(art)
    preload("res://scripts/enemy_contrast.gd").apply(art)

func _animate(action: String) -> void:
    if not is_instance_valid(art):
        return
    if action == "hurt":
        art.modulate = Color("e8ada0")
        return
    art.flip_h = archetype == "centauro" and facing == "left" and action in ["prepare","attack"]
    var key := action+"_"+facing
    if art.sprite_frames.has_animation(key) and art.animation != key:
        art.play(key)

func _face(direction: Vector2) -> void:
    if direction.length_squared() < 0.001:
        return
    facing = ("left" if direction.x < 0 else "right") if absf(direction.x)>absf(direction.y) else ("up" if direction.y<0 else "down")

func _common_tick(delta: float) -> void:
    art.modulate = Color("e8ada0") if flash>0 else Color.WHITE
    var offset: Vector2 = hero.position-position
    var distance := offset.length()
    # El objetivo queda fijado al preparar cada ataque; no se teletransporta ni gira el salto.
    if state == "windup":
        _animate("idle")
        if timer <= 0:
            _release_guardian_attack()
        return
    if state == "dash":
        _animate("attack" if archetype == "mastin" else "walk")
        var speed := 390.0 if archetype == "mastin" else 310.0
        var desired := charge_direction*speed*delta
        var old := position
        position = world.geometry.move_on_ground(position,desired,body_radius)
        if not dash_hit and position.distance_to(hero.position)<body_radius+23 and world.has_clear_path(position, hero.position):
            hero.take_damage(1)
            dash_hit = true
        if timer<=0 or position.distance_to(old)<desired.length()*0.3:
            state = "recover"
            timer = 0.65
        return
    if state == "recover":
        _animate("attack" if timer>0.45 else "idle")
        if timer<=0:
            state = "pursue"
        return
    _face(offset)
    # No persigue al jugador hasta otro recinto; vuelve hacia el pilar que custodia.
    if distance>570 or hero.position.distance_to(home)>640:
        var home_offset := home-position
        if home_offset.length()>35:
            _face(home_offset)
            position = world.geometry.move_on_ground(position,home_offset.normalized()*80*delta,body_radius)
            _animate("walk")
        else:
            _animate("idle")
        return
    var range_limit := 335.0 if archetype in ["centauro","ceniza"] else 235.0
    if cooldown<=0 and distance<range_limit and world.has_clear_path(position, hero.position):
        charge_direction = offset.normalized()
        _face(charge_direction)
        attack_kind = choose_attack(distance)
        state = "windup"
        timer = 0.65 if archetype == "mastin" else 0.85
        _animate("idle")
        return
    var preferred := 190.0 if archetype == "centauro" else 145.0 if archetype == "ceniza" else 55.0
    var direction := offset.normalized() if distance>preferred else -offset.normalized() if archetype == "centauro" and distance<105 else Vector2.ZERO
    if direction.length_squared()>0:
        position = world.geometry.move_on_ground(position,direction*float(CONFIG[archetype]["speed"])*delta,body_radius)
        _animate("walk")
    else:
        _animate("idle")

func choose_attack(distance: float) -> String:
    var pattern := attack_cycle%3
    if archetype == "centauro":
        return "spear" if distance<115 else "charge" if pattern==2 else "arrows"
    if archetype == "mastin":
        return "bite" if distance<80 else "leap"
    return "sweep" if distance<120 else "ash" if pattern==2 else "fire"

func _release_guardian_attack() -> void:
    AudioManager.foe_voice(archetype)
    preload("res://scripts/combat_fx.gd").burst(self, global_position, charge_direction, 74.0, Color("ffc17b"))
    attack_cycle += 1
    _animate("attack")
    cooldown = 1.5 if archetype == "mastin" else 2.0
    if attack_kind in ["charge","leap"]:
        state = "dash"
        timer = 0.48 if archetype == "mastin" else 0.55
        dash_hit = false
        return
    if attack_kind == "arrows":
        for angle in [-0.17,0.0,0.17]:
            world.spawn_projectile(position,charge_direction.rotated(angle),true,1,"arrow")
    elif attack_kind == "fire":
        for angle in [-0.3,0.0,0.3]:
            world.spawn_projectile(position,charge_direction.rotated(angle),true,1,"ember")
    elif attack_kind == "ash":
        world.spawn_ash(position)
        for i in range(6):
            world.spawn_projectile(position,Vector2.RIGHT.rotated(TAU*float(i)/6),true,1,"ember")
    else:
        var to_hero: Vector2 = hero.position-position
        var reach := 120.0 if attack_kind in ["sweep","spear"] else 86.0
        if to_hero.length()<reach and (to_hero.length()<30 or charge_direction.dot(to_hero.normalized())>0.15) and world.has_clear_path(position, hero.position):
            hero.take_damage(1)
        if attack_kind == "sweep":
            world.spawn_ash(position+charge_direction*55)
    state = "recover"
    timer = 0.7
    world.play_sound("golpe" if attack_kind in ["bite","spear","sweep"] else "verso")

func _draw() -> void:
    draw_set_transform(Vector2.ZERO,0,Vector2(1,0.34))
    draw_circle(Vector2.ZERO,body_radius+7,Color(0,0,0,0.35))
    draw_set_transform(Vector2.ZERO)
    if not dead:
        var y: float = art.position.y * 2.0 - 10.0
        draw_rect(Rect2(-26,y,52,4),Color(0.10,0.07,0.07,0.7))
        draw_rect(Rect2(-26,y,52*float(hp)/max_hp,4),Color("b8887c"))

func build_library() -> SpriteFrames:
    var library := SpriteFrames.new()
    var config: Dictionary = CONFIG[archetype]
    var sheet: Texture2D = load("res://assets/violencia/enemies/%s_limpio.png" % archetype)
    var source := sheet.get_image()
    var canvas: Vector2i = config["size"]
    for row in range(4):
        var direction: String = ["down","left","up","right"][row]
        for action in ["idle","walk","prepare","attack","death"]:
            var key: String = action+"_"+direction
            library.add_animation(key)
            library.set_animation_speed(key,9 if action == "walk" else 7)
            library.set_animation_loop(key,action in ["idle","walk"])
            var columns: Array = [0] if action == "idle" else [1,2] if action == "walk" else [3] if action == "prepare" else [4] if action == "attack" else [5]
            for column in columns:
                var source_row := 3 if archetype == "centauro" and row == 1 and action in ["prepare","attack"] else row
                var region := Rect2i(Vector2i(column * canvas.x, source_row * canvas.y), canvas)
                library.add_frame(key, ART.isolated(sheet, source, region))
    return library
