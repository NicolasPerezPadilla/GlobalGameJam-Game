extends Node

# Slot actualmente activo
var current_save_slot: int = -1

# Ruta base de guardado
const SAVE_PATH := "user://save_%d.json"

# ====================
# UTILIDADES
# ====================

func _get_save_path(slot: int) -> String:
	return SAVE_PATH % slot

# ====================
# EXISTE SAVE
# ====================

func save_exists(slot: int) -> bool:
	return FileAccess.file_exists(_get_save_path(slot))

# ====================
# CREAR SAVE NUEVO
# ====================

func create_new_save(slot: int) -> void:
	var data = {
		"level": 1,
		"player": {
			"hp": 100,
			"max_hp": 100,
			"position": Vector2.ZERO
		},
		"play_time": 0
	}
	
	_write_save(slot, data)

# ====================
# CARGAR SAVE
# ====================

func load_game(slot: int) -> Dictionary:
	if not save_exists(slot):
		push_warning("Save slot %d does not exist" % slot)
		return {}
	
	var file = FileAccess.open(_get_save_path(slot), FileAccess.READ)
	var text = file.get_as_text()
	file.close()
	
	var data = JSON.parse_string(text)
	return data if data is Dictionary else {}

# ====================
# GUARDAR SAVE
# ====================

func save_game(slot: int, data: Dictionary) -> void:
	_write_save(slot, data)

func _write_save(slot: int, data: Dictionary) -> void:
	var file = FileAccess.open(_get_save_path(slot), FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

func delete_save(slot: int) -> void:
	var path = _get_save_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
