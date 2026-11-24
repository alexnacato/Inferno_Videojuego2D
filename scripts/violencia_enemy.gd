extends CharacterBody2D
## IA común y Minotauro con dirección fijada durante el aviso de carga.
signal died(uid: String)
signal hp_changed(current: int, maximum: int)
var world
var hero
var uid := ""
var archetype := "guardia"
var dead := false
var hp := 6
var max_hp := 6
var body_radius := 19.0
var clock := 0.0
var cooldown := 1.2
var timer := 0.0
var state := "pursue"
var charge_direction := Vector2.DOWN
var charge_count := 0
var phase := 1
var flash := 0.0
var anchor := Vector2.ZERO
var art: Node2D
var boss := false
var knockback := Vector2.ZERO
var attack_index := 0
var burst_left := 0
var burst_timer := 0.0
var look_direction := Vector2.DOWN

func _ready() -> void:
    motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
    collision_layer = 2
    collision_mask = 0
    boss = archetype == "minotauro"
    max_hp = 48 if boss else 7 if archetype == "centauro" else 5
    hp = max_hp
    body_radius = 31.0 if boss else 19.0
    anchor = position
    if boss:
        var sprite := AnimatedSprite2D.new()
        var library := SpriteFrames.new()
        for facing in ["down", "up", "left", "right"]:
            var sheet := "res://assets/violencia/minotauro_frente_espalda_limpio.png" if facing in ["down","up"] else "res://assets/violencia/minotauro_lados_limpio.png"
            var texture: Texture2D = load(sheet)
            var source_image := texture.get_image()
            var row := 0 if facing in ["down","left"] else 1
            for action in ["idle","walk","attack"]:
                var key: String = action+"_"+facing
                library.add_animation(key)
                library.set_animation_speed(key,7)
                library.set_animation_loop(key,true)
                var columns: Array = [0] if action == "idle" else [1,2] if action == "walk" else [3,0]
                for column in columns:
                    var region := Rect2i(column * 190, row * 210, 190, 210)
                    library.add_frame(key, preload("res://scripts/sprite_library.gd").isolated(texture, source_image, region))
        sprite.sprite_frames = library
        sprite.position.y = -101
        sprite.play("idle_down")
        art = sprite
    else:
        var sprite := AnimatedSprite2D.new()
        var library := SpriteFrames.new()
        var source := "carcelero" if archetype == "centauro" else "espectro"
        for action in ["idle", "walk", "attack", "hurt", "death"]:
            var texture: Texture2D = load("res://assets/lujuria/enemies/%s/%s.png" % [source, action])
            library.add_animation(action)
            library.set_animation_speed(action, 8)
            library.set_animation_loop(action, action in ["idle", "walk"])
            var source_image := texture.get_image()
            for i in range(int(texture.get_width() / 128)):
                var region := Rect2i(i * 128, 0, 128, 144)
                library.add_frame(action, preload("res://scripts/sprite_library.gd").isolated(texture, source_image, region, 6))
        sprite.sprite_frames = library
        sprite.scale = Vector2(0.85,0.85)
        sprite.position.y = -62
        sprite.modulate = Color("c6b4b0")
        sprite.play("idle")
        art = sprite
    add_child(art)
    preload("res://scripts/enemy_contrast.gd").apply(art)

func _physics_process(delta: float) -> void:
    if not is_instance_valid(world) or not world.game_active:
        return
    clock += delta
    flash = maxf(0, flash-delta)
    cooldown = maxf(0,cooldown-delta)
    timer = maxf(0,timer-delta)
    if dead:
        art.modulate.a = maxf(0,art.modulate.a-delta*1.6)
        if art.modulate.a <= 0:
            queue_free()
        return
    if not is_instance_valid(hero):
        return
    if boss:
        _boss_tick(delta)
    else:
        _common_tick(delta)
    if boss:
        var direction: Vector2 = charge_direction if state in ["charge"] else look_direction
        var facing := "left" if direction.x < 0 else "right"
        if absf(direction.y) > absf(direction.x):
            facing = "up" if direction.y < 0 else "down"
        var action := "attack" if state in ["slam"] else "walk" if state in ["charge","pursue"] else "idle"
        _animate(action+"_"+facing)
        art.position.y = -101 + (sin(clock*12)*2 if state in ["charge","pursue"] else sin(clock*2)*1.2)
        art.modulate = Color("e6a29a") if flash > 0 else Color("b6aaa4") if state == "stunned" else Color.WHITE
    queue_redraw()

func _common_tick(delta: float) -> void:
    var to_hero: Vector2 = hero.position-position
    burst_timer -= delta
    if burst_left > 0 and burst_timer <= 0:
        world.spawn_projectile(position,(hero.position-position).normalized(),true,1)
        burst_left -= 1
        burst_timer = 0.22
    if to_hero.length() > 440 or absf(hero.position.y-anchor.y) > 280:
        _animate("idle")
        return
    if state == "windup":
        _animate("attack")
        if timer <= 0:
            if archetype == "centauro":
                attack_index += 1
                if attack_index % 3 == 0:
                    burst_left = 3
                    burst_timer = 0.0
                elif attack_index % 3 == 1:
                    for angle in [-0.28,0.0,0.28]:
                        world.spawn_projectile(position+charge_direction*30,charge_direction.rotated(angle),true,1)
                else:
                    for i in range(8):
                        world.spawn_projectile(position,Vector2.RIGHT.rotated(TAU*i/8.0),true,1)
            else:
                attack_index += 1
                if attack_index % 2 == 0:
                    for i in range(5):
                        world.spawn_projectile(position,charge_direction.rotated((i-2)*0.32),true,1)
                elif to_hero.length() < 105:
                    hero.take_damage(1)
            state = "pursue"
            cooldown = 1.8
        return
    if cooldown <= 0 and to_hero.length() < (330 if archetype == "centauro" else 76):
        charge_direction = to_hero.normalized()
        state = "windup"
        timer = 0.65
        return
    if art is AnimatedSprite2D:
        art.flip_h = to_hero.x < 0
    if to_hero.length() > (220 if archetype == "centauro" else 60):
        var motion := to_hero.normalized()*88.0*delta
        position = world.geometry.move_on_ground(position,motion,body_radius)
        _animate("walk")
    else:
        _animate("idle")

func _boss_tick(delta: float) -> void:
    if hp <= max_hp/2 and phase == 1:
        phase = 2
        world.notify("MINOTAURO · La furia acelera sus cargas. Espera el choque.")
    match state:
        "pursue":
            look_direction = (hero.position-position).normalized()
            var orbit := look_direction.orthogonal() * sin(clock*0.8)*55.0
            var motion := (look_direction*65.0 if position.distance_to(hero.position)>150 else orbit)*delta
            position = world.geometry.move_on_ground(position,motion,body_radius,true)
            if cooldown <= 0:
                if charge_count > 0 and charge_count % 3 == 0:
                    state = "slam_warning"
                    timer = 1.0
                    charge_count += 1
                else:
                    begin_charge()
        "windup":
            if timer <= 0:
                state = "charge"
                preload("res://scripts/combat_fx.gd").burst(self, global_position, charge_direction, 65.0, Color("#ffbb76"))
                timer = 1.25
                world.play_sound("carga")
        "charge":
            var displacement := charge_direction * (740.0 if phase == 2 else 610.0) * delta
            # La carga no se desliza por paredes: chocar abre una ventana de daño.
            var steps := maxi(1, int(ceil(displacement.length()/4)))
            for i in range(steps):
                var target := position+displacement/float(steps)
                if not world.geometry.can_walk(target,body_radius,true):
                    stun()
                    break
                position = target
                if position.distance_to(hero.position) < body_radius+17:
                    hero.take_damage(2)
            if timer <= 0 and state == "charge":
                state = "recover"
                timer = 0.9
        "stunned", "recover":
            if timer <= 0:
                state = "pursue"
                cooldown = 0.6
        "slam_warning":
            if timer <= 0:
                if position.distance_to(hero.position) < 170:
                    hero.take_damage(2)
                for i in range(12):
                    world.spawn_projectile(position,Vector2.RIGHT.rotated(TAU*i/12.0),true,1)
                preload("res://scripts/combat_fx.gd").burst(self, global_position, Vector2.ZERO, 170.0, Color("#ffb07a"))
                state = "slam"
                timer = 0.4
                world.play_sound("choque")
        "slam":
            if timer <= 0:
                state = "recover"
                timer = 1.3

func begin_charge() -> void:
    charge_direction = (hero.position-position).normalized()
    if charge_direction.length_squared() < 0.01:
        charge_direction = Vector2.DOWN
    state = "windup"
    timer = 0.72 if phase == 2 else 1.05
    charge_count += 1

func stun() -> void:
    state = "stunned"
    timer = 2.6
    world.play_sound("choque")
    world.notify("¡Ha chocado! Acércate: el Minotauro es vulnerable.")

func take_damage(amount: int, _direction: Vector2 = Vector2.DOWN) -> void:
    if dead:
        return
    var inflicted := amount*2 if boss and state == "stunned" else amount
    hp = maxi(0,hp-inflicted)
    flash = 0.16
    hp_changed.emit(hp,max_hp)
    world.play_sound("impacto")
    if hp <= 0:
        dead = true
        _animate("death")
        died.emit(uid)
    elif not boss:
        _animate("hurt")

func _animate(action: String) -> void:
    if art is AnimatedSprite2D and art.sprite_frames.has_animation(action) and art.animation != action:
        art.play(action)

func _draw() -> void:
    draw_set_transform(Vector2.ZERO,0,Vector2(1,0.34))
    draw_circle(Vector2.ZERO,body_radius+9,Color(0,0,0,0.45))
    draw_set_transform(Vector2.ZERO)
    if dead:
        return
    if state == "stunned":
        draw_arc(Vector2(0,-160),20,clock*3,clock*3+5,30,Color("f0dec2"),3,true)
    if state == "slam":
        draw_arc(Vector2.ZERO,170*(1.0-timer/0.4),0,TAU,64,Color(0.65,0.4,0.35,0.45),3,true)
    if not boss and hp < max_hp:
        draw_rect(Rect2(-25,-95,50,5),Color("251b1c"))
        draw_rect(Rect2(-25,-95,50*float(hp)/max_hp,5),Color("c59488"))
