extends SceneTree

var failures: Array[String] = []
var captures := OS.get_environment("INFERNO_UI_CAPTURES")
const MENU := "res://scenes/MenuPrincipal.tscn"

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var game = root.get_node("Game")
    if game.has_save():
        push_error("Ejecutar la prueba con APPDATA temporal y sin guardado de campaña.")
        quit(1)
        return
    change_scene_to_file(MENU)
    await _settle()
    _check(_button("Continuar partida anterior").disabled, "Continuar se habilita antes de guardar")
    _check(_focused("Comenzar un nuevo viaje"), "El menú no tiene foco inicial")
    _check_centered_screen("MenuPrincipal")
    await _capture("01-menu")
    await _key(KEY_DOWN)
    _check(_focused("Selección de niveles"), "La flecha no salta Continuar desactivado")
    await _key(KEY_DOWN)
    await _key(KEY_ENTER)
    _check(_focused("Audio · Activado"), "Configuración no enfoca el ajuste de audio")
    await _capture("02-configuracion")
    await _key(KEY_ENTER)
    _check(not game.audio_enabled and _focused("Audio · Silenciado"), "El botón de audio no actualiza su estado")
    await _key(KEY_TAB)
    _check(root.gui_get_focus_owner() is HSlider, "Tab no enfoca el volumen")
    await _key(KEY_LEFT)
    _check(game.audio_volume < 0.8, "La flecha no cambia el volumen")
    await _key(KEY_ESCAPE)
    _check(_focused("Configuración"), "Escape no devuelve el foco al elemento de origen")
    if not _focused("Configuración"):
        _finish()
        return
    await _click("Comenzar un nuevo viaje")
    _check(current_scene.name == "Limbo", "Nueva partida no abre Limbo")
    if current_scene.name != "Limbo":
        _finish()
        return
    var limbo: Node = current_scene
    await _key(KEY_SPACE)
    _check(limbo.hud.dialogue_open, "Espacio activa el diálogo y puede disparar una esquiva")
    await _key(KEY_ENTER)
    _check(limbo.hud.dialogue_open and not limbo.hud.dialogue_text.writing, "Enter no revela el diálogo")
    await _capture("03-dialogo")
    await _key(KEY_ENTER)
    _check(not limbo.hud.dialogue_open, "Enter no acepta el diálogo enfocado")
    _check(not limbo.hud.player_details.visible, "El HUD de Dante inicia desplegado")
    await _capture("03a-hud-compacto")
    await _key(KEY_H)
    _check(limbo.hud.player_details.visible, "H no despliega el estado de Dante")
    await _capture("03b-hud-desplegado")
    await _click(limbo.hud.player_toggle.text)
    _check(not limbo.hud.player_details.visible, "El botón H no recoge el estado de Dante")
    await _key(KEY_ESCAPE)
    _check(paused and limbo.hud.pause_open and _focused("REANUDAR  ·  ESC"), "Escape no pausa y enfoca Reanudar")
    await _capture("04-pausa")
    limbo.player.dash_cooldown_left = 0.5
    var before: Vector2 = limbo.player.global_position
    Input.action_press("move_up")
    for frame in range(5):
        await physics_frame
    Input.action_release("move_up")
    _check(limbo.player.global_position == before and is_equal_approx(limbo.player.dash_cooldown_left, 0.5), "La simulación sigue avanzando durante la pausa")
    await _key(KEY_ENTER)
    _check(not paused and not limbo.hud.pause_open, "Enter no reanuda")
    await _key(KEY_ESCAPE)
    await _key(KEY_DOWN)
    _check(_focused("GUARDAR Y VOLVER AL MENÚ"), "La flecha no selecciona Guardar y volver")
    await _key(KEY_ENTER)
    _check(current_scene.name == "MenuPrincipal" and game.has_save() and not paused, "Guardar y volver no restaura el menú")
    if current_scene.name != "MenuPrincipal":
        _finish()
        return
    _check(_focused("Continuar partida anterior"), "Continuar no recibe foco al volver")
    await _click("Comenzar un nuevo viaje")
    _check(_focused("Volver"), "La confirmación de nueva campaña no enfoca la salida segura")
    await _key(KEY_ESCAPE)
    _check(_focused("Comenzar un nuevo viaje") and game.has_save(), "Cancelar nueva campaña no conserva el progreso")
    if current_scene.name != "MenuPrincipal":
        _finish()
        return

    var campaign := FileAccess.get_file_as_string(game.SAVE_PATH)
    var levels: Dictionary = current_scene.LEVELS
    for label in levels:
        await _click("Selección de niveles")
        _check(_focused("I · LIMBO"), "La selección de niveles no tiene foco inicial")
        if label == "I · LIMBO":
            await _capture("05-niveles")
        await _click(label)
        _check(current_scene.name == levels[label], "El acceso libre no abre " + label)
        change_scene_to_file(MENU)
        await _settle()
    _check(FileAccess.get_file_as_string(game.SAVE_PATH) == campaign, "El modo libre modificó la campaña")
    await _key(KEY_ENTER)
    _check(_focused("Continuar"), "No se abrió la ficha del peregrino")
    await _capture("06-ficha")
    await _key(KEY_ENTER)
    _check(current_scene.name == "Limbo", "Continuar no restaura Limbo después del modo libre")

    for screen in ["Transicion", "FinLimbo", "FinLujuria", "FinGula", "FinViolencia", "FinTraicion"]:
        change_scene_to_file("res://scenes/%s.tscn" % screen)
        await _settle()
        if screen != "FinTraicion":
            _check_centered_screen(screen)
        if screen == "Transicion":
            for frame in range(58):
                await process_frame
        await _capture(screen)
        if screen == "FinTraicion":
            await _key(KEY_ENTER)
            await _key(KEY_ENTER)
            await _key(KEY_ENTER)
            await _key(KEY_ESCAPE)
        else:
            await _click("VOLVER AL MENÚ PRINCIPAL")
        _check(current_scene.name == "MenuPrincipal", "Volver al menú falla en " + screen)
    game.progress["redencion"] = 4
    game.save_progress()
    await _click("Comenzar un nuevo viaje")
    await _click("Iniciar nueva campaña")
    _check(current_scene.name == "Limbo" and game.progress["redencion"] == 0, "Confirmar no reinicia la campaña")
    change_scene_to_file(MENU)
    await _settle()
    _finish()

func _check_centered_screen(screen: String) -> void:
    var center := current_scene.find_children("*", "CenterContainer", true, false)[0] as CenterContainer
    var panel := center.get_child(0) as PanelContainer
    var bounds := root.get_visible_rect()
    var panel_rect := panel.get_global_rect()
    _check(panel_rect.get_center().distance_to(bounds.get_center()) <= 1.5, "Panel descentrado: " + screen)
    _check(bounds.encloses(panel_rect), "Panel fuera del área visible: " + screen)
    for node in panel.find_children("*", "Button", true, false):
        var button := node as Button
        _check(panel_rect.encloses(button.get_global_rect()), "Botón fuera del panel: " + screen)

func _button(caption: String) -> Button:
    for node in current_scene.find_children("*", "Button", true, false):
        if node.text.trim_prefix("‹  ") == caption.to_upper() and node.is_visible_in_tree():
            return node
    push_error("Botón no encontrado: " + caption)
    return null

func _focused(caption: String) -> bool:
    var focus := root.gui_get_focus_owner() as Button
    return is_instance_valid(focus) and focus.text.trim_prefix("‹  ") == caption.to_upper()

func _key(code: Key) -> void:
    var event := InputEventKey.new()
    event.keycode = code
    event.pressed = true
    Input.parse_input_event(event)
    await process_frame
    var release := InputEventKey.new()
    release.keycode = code
    Input.parse_input_event(release)
    await _settle()

func _click(caption: String) -> void:
    var button := _button(caption)
    if button == null:
        failures.append("No se pudo pulsar " + caption)
        return
    var point := button.get_global_transform_with_canvas() * (button.size * 0.5)
    var moved := InputEventMouseMotion.new()
    moved.position = point
    moved.global_position = point
    root.push_input(moved, true)
    for pressed in [true, false]:
        var event := InputEventMouseButton.new()
        event.button_index = MOUSE_BUTTON_LEFT
        event.position = point
        event.global_position = point
        event.pressed = pressed
        root.push_input(event, true)
    await _settle()

func _settle() -> void:
    for frame in range(3):
        await process_frame

func _capture(name: String) -> void:
    if captures.is_empty():
        return
    await RenderingServer.frame_post_draw
    var image := root.get_texture().get_image()
    if image != null:
        image.save_png(captures.path_join(name + ".png"))

func _check(success: bool, message: String) -> void:
    if not success:
        failures.append(message)

func _finish() -> void:
    if not failures.is_empty():
        for failure in failures:
            push_error(failure)
        quit(1)
        return
    print("Menú, entradas, guardado, cinco accesos libres y seis cierres verificados.")
    await _click("Créditos")
    var roll := current_scene.get_child(current_scene.get_child_count() - 1)
    var credits := []
    for entry in roll.find_children("*", "Label", true, false):
        credits.append(entry.text)
    for name in ["Alexander Ñacato", "Leidy Saraguro", "Gabriel Baez"]:
        if name not in credits:
            push_error("Falta en créditos: " + name)
            quit(1)
            return
    await _capture("07-creditos")
    await _key(KEY_ESCAPE)
    await _click("Salir")
    var exit_roll := current_scene.get_child(current_scene.get_child_count() - 1)
    var exit_key := InputEventKey.new()
    exit_key.keycode = KEY_ESCAPE
    exit_key.pressed = true
    root.push_input(exit_key)
    if not exit_roll.closing:
        push_error("Salir no cerró la aplicación")
        quit(1)
