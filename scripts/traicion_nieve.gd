extends Node2D

const COUNT := 158
var flakes: Array[Vector3] = []
var age := 0.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
    rng.seed = 91739
    for i in range(COUNT):
        flakes.append(Vector3(rng.randf_range(0.0, 1448.0), rng.randf_range(0.0, 1086.0), rng.randf_range(0.65, 2.3)))

func _process(delta: float) -> void:
    age += delta
    for i in range(flakes.size()):
        var flake := flakes[i]
        flake.x += (14.0 + flake.z * 22.0 + sin(age * 1.3 + i * 0.12) * 19.0) * delta
        flake.y += (33.0 + flake.z * 23.0) * delta
        if flake.x > 1455.0:
            flake.x = -8.0
        if flake.y > 1093.0:
            flake.y = -8.0
        flakes[i] = flake
    queue_redraw()

func _draw() -> void:
    for flake in flakes:
        var point := Vector2(flake.x, flake.y)
        draw_line(point - Vector2(4.0, 6.0) * flake.z, point, Color(0.81, 0.95, 1.0, 0.36), flake.z)
        draw_circle(point, flake.z, Color(0.91, 0.98, 1.0, 0.60))
