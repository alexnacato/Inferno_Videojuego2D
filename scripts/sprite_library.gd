extends RefCounted
## Normaliza cada celda al mismo lienzo y línea de pies, sin recortar el cuerpo.
static var cache: Dictionary = {}
static func frame(path: String, column: int, row: int, columns: int, rows: int, size: Vector2i) -> Texture2D:
    var key := "%s:%d:%d:%s" % [path,column,row,size]
    if cache.has(key):
        return cache[key]
    var source: Image = load(path).get_image()
    source.convert(Image.FORMAT_RGBA8)
    var cell := Rect2i(roundi(float(column)*source.get_width()/columns),roundi(float(row)*source.get_height()/rows),floori(float(source.get_width())/columns),floori(float(source.get_height())/rows))
    var piece := source.get_region(cell)
    # Elimina únicamente el velo de transparencia residual de la generación.
    for y in range(piece.get_height()):
        for x in range(piece.get_width()):
            var color := piece.get_pixel(x,y)
            if color.a < 0.65:
                piece.set_pixel(x,y,Color.TRANSPARENT)
    var used := piece.get_used_rect()
    if used.has_area():
        piece = piece.get_region(used)
        var scale_factor := minf(float(size.x-10)/piece.get_width(),float(size.y-10)/piece.get_height())
        piece.resize(maxi(1,roundi(piece.get_width()*scale_factor)),maxi(1,roundi(piece.get_height()*scale_factor)),Image.INTERPOLATE_LANCZOS)
    var canvas := Image.create(size.x,size.y,false,Image.FORMAT_RGBA8)
    canvas.fill(Color.TRANSPARENT)
    canvas.blit_rect(piece,Rect2i(Vector2i.ZERO,piece.get_size()),Vector2i((size.x-piece.get_width())/2,size.y-piece.get_height()-4))
    var texture := ImageTexture.create_from_image(canvas)
    cache[key] = texture
    return texture

static func dante() -> SpriteFrames:
    var library := SpriteFrames.new()
    for state in ["idle","walk","dash","interact","ready"]:
        for row in range(4):
            var key: String = state+"_"+["down","left","up","right"][row]
            library.add_animation(key)
            library.set_animation_speed(key,10 if state == "walk" else 7)
            library.set_animation_loop(key,true)
            for column in range(4 if state == "walk" or state == "dash" else 1):
                library.add_frame(key,frame("res://assets/dante/movimiento_completo.png",column,row,4,4,Vector2i(80,96)))
    return library
