extends RefCounted
## Suelo transitable del mapa pintado. Los polígonos se unen ANTES de probar
## la huella para evitar costuras invisibles entre plazas, puentes y escaleras.
const MAP_SCALE := 1.448
var ground: Array[PackedVector2Array] = []

func _init() -> void:
    ground.append(PackedVector2Array([Vector2(278, 118) * MAP_SCALE, Vector2(720, 118) * MAP_SCALE, Vector2(720, 147) * MAP_SCALE, Vector2(665, 166) * MAP_SCALE, Vector2(565, 173) * MAP_SCALE, Vector2(550, 190) * MAP_SCALE, Vector2(450, 190) * MAP_SCALE, Vector2(435, 173) * MAP_SCALE, Vector2(335, 166) * MAP_SCALE, Vector2(278, 147) * MAP_SCALE]))
    ground.append(PackedVector2Array([Vector2(449, 157) * MAP_SCALE, Vector2(551, 157) * MAP_SCALE, Vector2(551, 218) * MAP_SCALE, Vector2(449, 218) * MAP_SCALE]))
    ground.append(PackedVector2Array([Vector2(344, 198) * MAP_SCALE, Vector2(390, 185) * MAP_SCALE, Vector2(610, 185) * MAP_SCALE, Vector2(656, 198) * MAP_SCALE, Vector2(665, 245) * MAP_SCALE, Vector2(639, 264) * MAP_SCALE, Vector2(555, 277) * MAP_SCALE, Vector2(445, 277) * MAP_SCALE, Vector2(361, 264) * MAP_SCALE, Vector2(335, 245) * MAP_SCALE]))
    ground.append(PackedVector2Array([Vector2(450, 257) * MAP_SCALE, Vector2(551, 257) * MAP_SCALE, Vector2(554, 322) * MAP_SCALE, Vector2(447, 322) * MAP_SCALE]))
    ground.append(PackedVector2Array([Vector2(427, 302) * MAP_SCALE, Vector2(568, 302) * MAP_SCALE, Vector2(604, 324) * MAP_SCALE, Vector2(634, 355) * MAP_SCALE, Vector2(640, 398) * MAP_SCALE, Vector2(615, 430) * MAP_SCALE, Vector2(568, 451) * MAP_SCALE, Vector2(433, 451) * MAP_SCALE, Vector2(387, 430) * MAP_SCALE, Vector2(360, 400) * MAP_SCALE, Vector2(362, 353) * MAP_SCALE, Vector2(392, 322) * MAP_SCALE]))
    ground.append(PackedVector2Array([Vector2(236, 315) * MAP_SCALE, Vector2(355, 318) * MAP_SCALE, Vector2(395, 342) * MAP_SCALE, Vector2(392, 378) * MAP_SCALE, Vector2(335, 381) * MAP_SCALE, Vector2(271, 376) * MAP_SCALE, Vector2(209, 387) * MAP_SCALE, Vector2(155, 414) * MAP_SCALE, Vector2(139, 445) * MAP_SCALE, Vector2(181, 470) * MAP_SCALE, Vector2(214, 486) * MAP_SCALE, Vector2(208, 505) * MAP_SCALE, Vector2(180, 509) * MAP_SCALE, Vector2(132, 486) * MAP_SCALE, Vector2(96, 459) * MAP_SCALE, Vector2(78, 415) * MAP_SCALE, Vector2(91, 374) * MAP_SCALE, Vector2(123, 342) * MAP_SCALE, Vector2(176, 328) * MAP_SCALE]))
    ground.append(PackedVector2Array([Vector2(764, 315) * MAP_SCALE, Vector2(645, 318) * MAP_SCALE, Vector2(605, 342) * MAP_SCALE, Vector2(608, 378) * MAP_SCALE, Vector2(665, 381) * MAP_SCALE, Vector2(729, 376) * MAP_SCALE, Vector2(791, 387) * MAP_SCALE, Vector2(845, 414) * MAP_SCALE, Vector2(861, 445) * MAP_SCALE, Vector2(819, 470) * MAP_SCALE, Vector2(786, 486) * MAP_SCALE, Vector2(792, 505) * MAP_SCALE, Vector2(820, 509) * MAP_SCALE, Vector2(868, 486) * MAP_SCALE, Vector2(904, 459) * MAP_SCALE, Vector2(922, 415) * MAP_SCALE, Vector2(909, 374) * MAP_SCALE, Vector2(877, 342) * MAP_SCALE, Vector2(824, 328) * MAP_SCALE]))
    ground.append(PackedVector2Array([Vector2(382, 422) * MAP_SCALE, Vector2(432, 434) * MAP_SCALE, Vector2(446, 471) * MAP_SCALE, Vector2(427, 499) * MAP_SCALE, Vector2(425, 540) * MAP_SCALE, Vector2(351, 540) * MAP_SCALE, Vector2(355, 501) * MAP_SCALE, Vector2(391, 475) * MAP_SCALE, Vector2(399, 455) * MAP_SCALE]))
    ground.append(PackedVector2Array([Vector2(618, 422) * MAP_SCALE, Vector2(568, 434) * MAP_SCALE, Vector2(554, 471) * MAP_SCALE, Vector2(573, 499) * MAP_SCALE, Vector2(575, 540) * MAP_SCALE, Vector2(649, 540) * MAP_SCALE, Vector2(645, 501) * MAP_SCALE, Vector2(609, 475) * MAP_SCALE, Vector2(601, 455) * MAP_SCALE]))
    ground.append(PackedVector2Array([Vector2(357, 525) * MAP_SCALE, Vector2(643, 525) * MAP_SCALE, Vector2(672, 547) * MAP_SCALE, Vector2(678, 585) * MAP_SCALE, Vector2(656, 612) * MAP_SCALE, Vector2(344, 612) * MAP_SCALE, Vector2(322, 585) * MAP_SCALE, Vector2(328, 547) * MAP_SCALE]))
    ground.append(PackedVector2Array([Vector2(464, 594) * MAP_SCALE, Vector2(536, 594) * MAP_SCALE, Vector2(540, 674) * MAP_SCALE, Vector2(532, 735) * MAP_SCALE, Vector2(468, 735) * MAP_SCALE, Vector2(460, 674) * MAP_SCALE]))
    ground.append(PackedVector2Array([Vector2(300, 702) * MAP_SCALE, Vector2(464, 702) * MAP_SCALE, Vector2(464, 678) * MAP_SCALE, Vector2(536, 678) * MAP_SCALE, Vector2(536, 702) * MAP_SCALE, Vector2(700, 702) * MAP_SCALE, Vector2(709, 748) * MAP_SCALE, Vector2(291, 748) * MAP_SCALE]))
    ground.append(PackedVector2Array([Vector2(244, 303) * MAP_SCALE, Vector2(306, 303) * MAP_SCALE, Vector2(323, 338) * MAP_SCALE, Vector2(231, 341) * MAP_SCALE]))
    ground.append(PackedVector2Array([Vector2(694, 303) * MAP_SCALE, Vector2(756, 303) * MAP_SCALE, Vector2(769, 341) * MAP_SCALE, Vector2(677, 338) * MAP_SCALE]))

func contains_point(p: Vector2) -> bool:
    var q := p / MAP_SCALE
    # Base de la estatua de los amantes y pilares de la puerta inferior.
    if pow((q.x - 500.0) / 78.0, 2.0) + pow((q.y - 390.0) / 40.0, 2.0) <= 1.0:
        return false
    if Rect2(443, 474, 114, 52).has_point(q):
        return false
    if Rect2(427, 620, 32, 80).has_point(q) or Rect2(541, 620, 32, 80).has_point(q):
        return false
    for polygon in ground:
        if Geometry2D.is_point_in_polygon(p, polygon):
            return true
    return false

func can_walk(p: Vector2, radius: float) -> bool:
    if not contains_point(p):
        return false
    # Huella circular completa: también comprueba las diagonales.
    for i in range(16):
        var angle := TAU * float(i) / 16.0
        if not contains_point(p + Vector2(cos(angle), sin(angle)) * radius):
            return false
    return true

func move_on_ground(origin: Vector2, displacement: Vector2, radius: float) -> Vector2:
    # Subpasos: ni el dash ni un fotograma lento saltan por encima de un borde.
    var steps := maxi(1, int(ceil(displacement.length() / 4.0)))
    var step := displacement / float(steps)
    var result := origin
    for i in range(steps):
        var target := result + step
        if can_walk(target, radius):
            result = target
        else:
            if can_walk(result + Vector2(step.x, 0), radius):
                result.x += step.x
            if can_walk(result + Vector2(0, step.y), radius):
                result.y += step.y
    return result

func nearest_walkable(p: Vector2, radius: float) -> Vector2:
    if can_walk(p, radius):
        return p
    for distance in range(4, 241, 4):
        for i in range(32):
            var angle := TAU * float(i) / 32.0
            var candidate := p + Vector2(cos(angle), sin(angle)) * float(distance)
            if can_walk(candidate, radius):
                return candidate
    push_error("No hay suelo cercano a %s" % p)
    return p
