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
@onready var art: Sprite2D = $Sprite2D

func _ready() -> void:
    art.texture = load("res://assets/traicion/enemies/lucifer.png")
    art.scale = Vector2(0.21, 0.21)
    art.position = Vector2(0, -104)
    art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    hp_changed.emit(hp, max_hp)

func _process(delta: float) -> void:
    if dead or not active or not is_instance_valid(world) or not world.game_active or not is_instance_valid(hero):
        return
    flash = maxf(0.0, flash - delta)
    art.modulate = Color("#8eeaff") if flash > 0.0 else Color.WHITE
    var distance: float = global_position.distance_to(hero.global_position)
    if windup > 0.0:
        windup -= delta
        if windup <= 0.0:
            _release_attack()
            pattern = (pattern + 1) % 3
            cooldown = 1.45 if hp > MAX_HP / 2 else 1.0
    else:
        cooldown -= delta
        if cooldown <= 0.0 and distance < 480.0:
            target = hero.global_position
            windup = 0.90 if hp > MAX_HP / 2 else 0.65
    queue_redraw()

func _release_attack() -> void:
    if not is_instance_valid(hero) or not is_instance_valid(world):
        return
    var distance: float = global_position.distance_to(hero.global_position)
    match pattern:
        0: # Aliento helado: abanico visible y esquivable.
            var aim: Vector2 = global_position.direction_to(target)
            for angle in [-0.35, -0.17, 0.0, 0.17, 0.35]:
                world.spawn_projectile(global_position + aim * 55.0, aim.rotated(angle), true, 1)
        1: # Quiebre del hielo: una zona avisada antes de recibir daño.
            if hero.global_position.distance_to(target) < 112.0:
                hero.take_damage(2)
        2: # Golpe cercano.
            if distance < 145.0:
                hero.take_damage(2)

func take_damage(amount: int, _direction: Vector2) -> void:
    if dead or not active or not is_instance_valid(world) or not world.game_active:
        return
    hp = maxi(0, hp - maxi(0, amount))
    flash = 0.20
    hp_changed.emit(hp, max_hp)
    if hp == 0:
        dead = true
        active = false
        visible = false
        defeated.emit()

func _draw() -> void:
    if dead:
        return
    draw_set_transform(Vector2(0, 9), 0.0, Vector2(1.0, 0.37))
    draw_circle(Vector2.ZERO, 76.0, Color(0.0, 0.02, 0.05, 0.48))
    draw_set_transform(Vector2.ZERO)
    if windup <= 0.0:
        return
    var warning := Color(0.58, 0.94, 1.0, 0.8)
    if pattern == 1:
        draw_arc(to_local(target), 112.0, 0.0, TAU, 56, warning, 3.0)
        draw_circle(to_local(target), 112.0, Color(0.2, 0.8, 1.0, 0.09))
    elif pattern == 2:
        draw_arc(Vector2.ZERO, 145.0, 0.0, TAU, 56, warning, 3.0)
    else:
        draw_arc(Vector2.ZERO, 72.0, 0.0, TAU, 56, warning, 2.0)
