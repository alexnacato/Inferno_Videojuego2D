extends SceneTree

## Normaliza las hojas fuente a tiras de seis fotogramas para Godot.
const ROOT := "res://assets/gula/enemies/"
const COUNT := 6
const CONFIG := {
    "penitente": {"states": ["idle", "walk", "attack", "hurt", "death"], "frame": Vector2i(192, 192), "content": Vector2i(160, 174)},
    "rastrero": {"states": ["idle", "walk", "attack", "hurt", "death"], "frame": Vector2i(192, 192), "content": Vector2i(166, 170)},
    "escanciador": {"states": ["idle", "walk", "attack", "hurt", "death"], "frame": Vector2i(192, 192), "content": Vector2i(158, 174)},
    "cerbero": {"states": ["idle", "walk", "bite", "howl", "claw", "hurt", "death"], "frame": Vector2i(384, 384), "content": Vector2i(330, 350)},
}

func _initialize() -> void:
    var failed := false
    for kind in CONFIG:
        if not _build_kind(kind, CONFIG[kind]):
            failed = true
    quit(1 if failed else 0)

func _build_kind(kind: String, config: Dictionary) -> bool:
    var frames_by_state := {}
    var max_width := 1
    var max_height := 1
    for state in config["states"]:
        var source_path: String = ROOT + kind + "/sheets/" + state + ".png"
        var source: Image = Image.load_from_file(ProjectSettings.globalize_path(source_path))
        if source == null or source.is_empty():
            push_error("Falta hoja: " + source_path)
            return false
        source.convert(Image.FORMAT_RGBA8)
        var pieces: Array[Image] = []
        for i in range(COUNT):
            var x0: int = roundi(float(i) * float(source.get_width()) / float(COUNT))
            var x1: int = roundi(float(i + 1) * float(source.get_width()) / float(COUNT))
            var piece: Image = source.get_region(Rect2i(x0, 0, x1 - x0, source.get_height()))
            var used: Rect2i = _visible_bounds(piece)
            if used.size.x < 30 or used.size.y < 30:
                push_error("Fotograma vacío: %s/%s/%d" % [kind, state, i])
                return false
            piece = piece.get_region(used)
            pieces.append(piece)
            if state in ["idle", "walk"]:
                max_width = maxi(max_width, piece.get_width())
                max_height = maxi(max_height, piece.get_height())
        frames_by_state[state] = pieces
    var frame: Vector2i = config["frame"]
    var content: Vector2i = config["content"]
    var scale_factor: float = minf(float(content.x) / float(max_width), float(content.y) / float(max_height))
    print("Escala ", kind, ": ", max_width, "x", max_height, " -> ", scale_factor)
    for state in config["states"]:
        var strip: Image = Image.create_empty(frame.x * COUNT, frame.y, false, Image.FORMAT_RGBA8)
        strip.fill(Color.TRANSPARENT)
        var pieces: Array[Image] = frames_by_state[state]
        for i in range(COUNT):
            var piece: Image = pieces[i]
            var piece_scale: float = minf(scale_factor,
                minf(float(content.x) / float(piece.get_width()), float(content.y) / float(piece.get_height())))
            var width: int = maxi(1, roundi(piece.get_width() * piece_scale))
            var height: int = maxi(1, roundi(piece.get_height() * piece_scale))
            piece.resize(width, height, Image.INTERPOLATE_LANCZOS)
            var x: int = i * frame.x + (frame.x - width) / 2
            var y: int = frame.y - 7 - height
            strip.blit_rect(piece, Rect2i(Vector2i.ZERO, piece.get_size()), Vector2i(x, y))
        var output_path: String = ROOT + kind + "/" + state + ".png"
        var result: Error = strip.save_png(ProjectSettings.globalize_path(output_path))
        if result != OK:
            push_error("No se pudo guardar: " + output_path)
            return false
        print("Animación: ", output_path)
    return true

func _visible_bounds(image: Image) -> Rect2i:
    var left: int = image.get_width()
    var top: int = image.get_height()
    var right := -1
    var bottom := -1
    for y in range(0, image.get_height(), 2):
        for x in range(0, image.get_width(), 2):
            if image.get_pixel(x, y).a > 0.13:
                left = mini(left, x)
                top = mini(top, y)
                right = maxi(right, x)
                bottom = maxi(bottom, y)
    if right < left or bottom < top:
        return Rect2i()
    left = maxi(0, left - 2)
    top = maxi(0, top - 2)
    return Rect2i(left, top, mini(image.get_width() - left, right - left + 3),
        mini(image.get_height() - top, bottom - top + 3))
