extends RefCounted
## Conserva el avance hasta el borde y aprovecha la tangente en curvas.

const SLIDE_ANGLES := [-PI / 6.0, PI / 6.0, -PI / 3.0, PI / 3.0]

static func step(origin: Vector2, displacement: Vector2, can_enter: Callable) -> Vector2:
    if displacement.length_squared() < 0.0001:
        return origin
    var target: Vector2 = origin + displacement
    if can_enter.call(target):
        return target
    # El último punto válido evita perder todo el paso al rozar una esquina.
    var low: float = 0.0
    var high: float = 1.0
    for i in range(7):
        var middle: float = (low + high) * 0.5
        if can_enter.call(origin + displacement * middle):
            low = middle
        else:
            high = middle
    var contact: Vector2 = origin + displacement * low
    var remainder: Vector2 = displacement * (1.0 - low)
    var direction: Vector2 = displacement.normalized()
    var best: Vector2 = contact
    var best_progress: float = 0.0
    for slide in [Vector2(remainder.x, 0.0), Vector2(0.0, remainder.y)]:
        var progress: float = slide.dot(direction)
        if progress > best_progress and can_enter.call(contact + slide):
            best = contact + slide
            best_progress = progress
    # Un borde recto no debe desplazar lateralmente al pulsar contra él.
    var diagonal: bool = absf(displacement.x) > 0.5 and absf(displacement.y) > 0.5
    for pair in [[SLIDE_ANGLES[0], SLIDE_ANGLES[1]], [SLIDE_ANGLES[2], SLIDE_ANGLES[3]]]:
        var left: Vector2 = remainder.rotated(pair[0])
        var right: Vector2 = remainder.rotated(pair[1])
        var left_valid: bool = can_enter.call(contact + left)
        var right_valid: bool = can_enter.call(contact + right)
        if not diagonal and left_valid == right_valid:
            continue
        for slide in [left, right]:
            var progress: float = slide.dot(direction)
            if progress > best_progress and can_enter.call(contact + slide):
                best = contact + slide
                best_progress = progress
    return best
