extends Node
## Persistencia independiente del nivel, reutilizable en todos los círculos.
const SAVE_PATH: String = "user://inferno_save_v2.json"
const CIRCLE_TINTS: Dictionary = {
    "vestibulo": "#b8b8b8",
    "limbo": "#9aa0a6",
    "lujuria": "#7b3f9e",
    "gula": "#5e8c31",
    "avaricia": "#b8902f",
    "ira": "#c1121f",
    "herejia": "#e8710a",
    "violencia": "#7a0c1c",
    "fraude": "#a8741a",
    "traicion": "#5ba4cf"
}
var progress: Dictionary = {}

func _ready() -> void:
    load_progress()

func default_progress() -> Dictionary:
    return {
        "circle": "limbo", "intro_seen": false,
        "shrine_step": 0, "puzzle_errors": 0,
        "alma_elio": "", "alma_livia": "",
        "alma_paolo": "", "alma_francesca": "",
        "redencion": 0, "rigor": 0,
        "checkpoint": false, "pos_x": 769.0, "pos_y": 843.0,
        "limbo_completed": false,
        "lujuria_started": false, "lujuria_intro_seen": false,
        "lujuria_seals": [], "lujuria_decisions": {},
        "lujuria_triggered": {}, "lujuria_defeated": {},
        "lujuria_boss_spawned": false, "lujuria_boss_defeated": false,
        "lujuria_checkpoint_x": 723.0, "lujuria_checkpoint_y": 977.0,
        "lujuria_completed": false
    }

func has_save() -> bool:
    return FileAccess.file_exists(SAVE_PATH)

func new_game() -> void:
    progress = default_progress()
    save_progress()

func load_progress() -> void:
    progress = default_progress()
    if not has_save():
        return
    var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return
    var loaded: Variant = JSON.parse_string(file.get_as_text())
    if loaded is Dictionary:
        for key in progress.keys():
            if not loaded.has(key):
                continue
            var expected_type: int = typeof(progress[key])
            var actual_type: int = typeof(loaded[key])
            if expected_type == actual_type:
                progress[key] = loaded[key]
            elif expected_type == TYPE_INT and actual_type == TYPE_FLOAT:
                progress[key] = int(loaded[key])
            elif expected_type == TYPE_FLOAT and actual_type == TYPE_INT:
                progress[key] = float(loaded[key])
    progress["shrine_step"] = clampi(int(progress["shrine_step"]), 0, 3)
    progress["redencion"] = maxi(0, int(progress["redencion"]))
    progress["rigor"] = maxi(0, int(progress["rigor"]))

func save_progress() -> void:
    var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        push_warning("No se pudo escribir el guardado en: " + SAVE_PATH)
        return
    file.store_string(JSON.stringify(progress, "  "))
    file.flush()

func save_position(pos: Vector2) -> void:
    progress["pos_x"] = clampf(pos.x, 36.0, 1504.0)
    progress["pos_y"] = clampf(pos.y, 200.0, 938.0)
    progress["checkpoint"] = true
    save_progress()

func souls_completed() -> int:
    return int(not str(progress["alma_elio"]).is_empty()) + int(not str(progress["alma_livia"]).is_empty())

func gate_unlocked() -> bool:
    return int(progress["shrine_step"]) >= 3 and souls_completed() == 2

func decide(id: String, compassionate: bool) -> void:
    if not str(progress.get(id, "")).is_empty():
        return
    if compassionate:
        progress["redencion"] = int(progress["redencion"]) + 1
        progress[id] = "redencion"
    else:
        progress["rigor"] = int(progress["rigor"]) + 1
        progress[id] = "rigor"
    save_progress()

func next_scene() -> String:
    if bool(progress.get("lujuria_completed", false)):
        return "res://scenes/FinLujuria.tscn"
    if str(progress.get("circle", "limbo")) == "lujuria" or bool(progress.get("limbo_completed", false)):
        return "res://scenes/Lujuria.tscn"
    return "res://scenes/Limbo.tscn"

func enter_lujuria() -> void:
    progress["limbo_completed"] = true
    progress["lujuria_started"] = true
    progress["circle"] = "lujuria"
    save_progress()
