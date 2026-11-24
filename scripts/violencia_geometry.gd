extends RefCounted
## Polígonos sobre la ilustración de las terrazas. Coordenadas de referencia 850 × 637.5.
const SCALE := 2304.0 / 850.0
const MAP_SIZE := Vector2(2304, 1728)
const SPAWN := Vector2(425, 575) * SCALE
const ARENA := Rect2(Vector2(278, 150) * SCALE, Vector2(294, 92) * SCALE)
const PILLARS := [Vector2(308, 225) * SCALE, Vector2(540, 225) * SCALE]
const VOWS := [Vector2(424, 467) * SCALE, Vector2(233, 283) * SCALE, Vector2(616, 283) * SCALE]
const EXIT := Vector2(425, 116) * SCALE
var polygons: Array[PackedVector2Array] = []

func _init() -> void:
    # Puente de ingreso, patio bajo y escaleras a ambos lados del altar.
    _add([Vector2(386,631),Vector2(388,510),Vector2(453,510),Vector2(465,631)])
    _add([Vector2(263,453),Vector2(320,447),Vector2(537,447),Vector2(584,456),Vector2(607,495),Vector2(578,518),Vector2(514,525),Vector2(459,517),Vector2(383,517),Vector2(328,527),Vector2(273,517),Vector2(245,491)])
    _add([Vector2(268,467),Vector2(290,406),Vector2(324,358),Vector2(366,364),Vector2(342,404),Vector2(321,463)])
    _add([Vector2(525,462),Vector2(513,406),Vector2(485,367),Vector2(527,351),Vector2(552,402),Vector2(576,467)])
    # Terraza de la estatua y dos alas. El pedestal sólo bloquea su huella.
    _add([Vector2(290,295),Vector2(347,256),Vector2(505,256),Vector2(560,292),Vector2(562,342),Vector2(517,380),Vector2(481,392),Vector2(368,392),Vector2(315,369),Vector2(286,333)])
    _add([Vector2(89,318),Vector2(140,288),Vector2(206,277),Vector2(263,281),Vector2(311,290),Vector2(325,317),Vector2(268,316),Vector2(192,310),Vector2(144,326),Vector2(117,350),Vector2(127,375),Vector2(184,407),Vector2(194,432),Vector2(163,441),Vector2(121,415),Vector2(93,397),Vector2(70,356)])
    _add([Vector2(525,294),Vector2(589,282),Vector2(649,279),Vector2(710,290),Vector2(765,312),Vector2(783,347),Vector2(765,388),Vector2(732,411),Vector2(683,426),Vector2(675,399),Vector2(722,370),Vector2(729,346),Vector2(693,324),Vector2(638,315),Vector2(541,320)])
    # Escaleras superiores a izquierda y derecha y explanada del jefe.
    _add([Vector2(297,305),Vector2(317,244),Vector2(343,226),Vector2(380,234),Vector2(359,283),Vector2(345,305)])
    _add([Vector2(487,233),Vector2(527,226),Vector2(553,250),Vector2(568,306),Vector2(516,302),Vector2(504,271)])
    _add([Vector2(282,165),Vector2(306,149),Vector2(545,149),Vector2(568,166),Vector2(575,217),Vector2(555,239),Vector2(511,243),Vector2(333,243),Vector2(281,227),Vector2(269,201)])
    _add([Vector2(385,166),Vector2(385,127),Vector2(463,127),Vector2(463,166)])
    _add([Vector2(241,103),Vector2(394,102),Vector2(398,84),Vector2(452,84),Vector2(460,102),Vector2(609,103),Vector2(591,124),Vector2(466,145),Vector2(382,145),Vector2(269,129)])

func _add(points: Array) -> void:
    var polygon := PackedVector2Array()
    for point in points:
        polygon.append(point * SCALE)
    polygons.append(polygon)

func contains_point(p: Vector2) -> bool:
    var local := p / SCALE
    # Bases de altar, monumento, braseros y columnas. El volumen dibujado queda libre.
    if ((local - Vector2(427,333)) / Vector2(89,39)).length_squared() < 1.0:
        return false
    for base in [Vector2(424,441), Vector2(233,271), Vector2(616,271)]:
        if ((local - base) / Vector2(29,12)).length_squared() < 1.0:
            return false
    for pillar in PILLARS:
        if ((p - pillar) / Vector2(19, 13)).length_squared() < 1.0:
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
