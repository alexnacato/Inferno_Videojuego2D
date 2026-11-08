extends Node2D
## Motas ambientales ligeras, deterministas y sin sprites externos.
var particles: Array[Dictionary] = []
var clock: float = 0.0

func _ready() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7060
	for i in range(75):
		particles.append({
			"x": rng.randf_range(14.0, 1526.0),
			"y": rng.randf_range(150.0, 958.0),
			"speed": rng.randf_range(4.0, 13.0),
			"phase": rng.randf_range(0.0, TAU),
			"radius": rng.randf_range(0.5, 1.7)
		})

func _process(delta: float) -> void:
	clock += delta
	queue_redraw()

func _draw() -> void:
	for p in particles:
		var px: float = float(p["x"]) + sin(clock * 0.30 + float(p["phase"])) * 10.0
		var py: float = fposmod(float(p["y"]) - clock * float(p["speed"]), 980.0)
		var alpha: float = 0.11 + 0.15 * absf(sin(clock * 0.82 + float(p["phase"])))
		draw_circle(Vector2(px, py), float(p["radius"]), Color(0.83, 0.85, 0.87, alpha))
