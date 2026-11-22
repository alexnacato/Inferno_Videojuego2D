extends RefCounted
## Coordenadas de mundo: imagen 1536x1024 ampliada 1.5 veces.
const SCALE := 1.5
const SPAWN := Vector2(1152, 1400)
const ARENA := Rect2(300, 192, 1704, 338)
const PILLARS := [Vector2(865, 282), Vector2(1433, 282), Vector2(865, 488), Vector2(1433, 488)]
var polygons: Array[PackedVector2Array] = []

func _init() -> void:
    _add([Vector2(120,890),Vector2(610,890),Vector2(620,870),Vector2(913,870),Vector2(925,890),Vector2(1410,890),Vector2(1410,967),Vector2(890,967),Vector2(890,1000),Vector2(650,1000),Vector2(650,967),Vector2(120,967)])
    _add([Vector2(622,886),Vector2(913,886),Vector2(900,633),Vector2(633,633)])
    _add([Vector2(370,456),Vector2(626,448),Vector2(635,432),Vector2(902,432),Vector2(912,448),Vector2(1176,456),Vector2(1210,523),Vector2(1160,566),Vector2(1160,612),Vector2(905,612),Vector2(905,655),Vector2(630,655),Vector2(630,612),Vector2(370,612),Vector2(370,566),Vector2(318,538),Vector2(318,497)])
    _add([Vector2(636,453),Vector2(902,453),Vector2(898,352),Vector2(640,352)])
    _add([Vector2(190,155),Vector2(500,125),Vector2(705,116),Vector2(705,80),Vector2(827,80),Vector2(827,116),Vector2(1060,125),Vector2(1340,155),Vector2(1410,226),Vector2(1410,310),Vector2(1280,342),Vector2(920,351),Vector2(900,375),Vector2(635,375),Vector2(616,351),Vector2(280,342),Vector2(130,310),Vector2(130,226)])

func _add(points: Array) -> void:
    var polygon := PackedVector2Array()
    for point in points:
        polygon.append(point * SCALE)
    polygons.append(polygon)

func contains_point(p: Vector2) -> bool:
    # Bases de columnas y obeliscos. No se bloquea su altura dibujada.
    for pillar in PILLARS:
        if ((p - pillar) / Vector2(32, 18)).length_squared() < 1.0:
            return false
    for obelisk in [Vector2(585, 790), Vector2(1713, 790)]:
        if ((p - obelisk) / Vector2(35, 18)).length_squared() < 1.0:
            return false
    for polygon in polygons:
        if Geometry2D.is_point_in_polygon(p, polygon):
            return true
    return false

func can_walk(p: Vector2, radius: float = 14.0, arena_locked: bool = false) -> bool:
    if arena_locked and not ARENA.grow(-radius).has_point(p):
        return false
    if not contains_point(p):
        return false
    for i in range(16):
        var a := TAU * float(i) / 16.0
        if not contains_point(p + Vector2(cos(a), sin(a)) * radius):
            return false
    return true

func move_on_ground(origin: Vector2, displacement: Vector2, radius: float, arena_locked: bool = false) -> Vector2:
    var steps := maxi(1, int(ceil(displacement.length() / 4.0)))
    var step := displacement / float(steps)
    var p := origin
    for i in range(steps):
        if can_walk(p + step, radius, arena_locked):
            p += step
        else:
            if can_walk(p + Vector2(step.x, 0), radius, arena_locked):
                p.x += step.x
            if can_walk(p + Vector2(0, step.y), radius, arena_locked):
                p.y += step.y
    return p

func nearest_walkable(p: Vector2, radius: float) -> Vector2:
    if can_walk(p, radius):
        return p
    for distance in range(4, 301, 4):
        for i in range(32):
            var a := TAU * float(i) / 32.0
            var q := p + Vector2(cos(a), sin(a)) * distance
            if can_walk(q, radius):
                return q
    return SPAWN
