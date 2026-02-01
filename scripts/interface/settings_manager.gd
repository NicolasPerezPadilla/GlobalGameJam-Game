extends Node

# Configuración de audio
var master_volume: float = 100.0
var music_volume: float = 80.0
var sfx_volume: float = 100.0

# Configuración de video
var fullscreen: bool = false
var resolution: Vector2i = Vector2i(1920, 1080)

# Buses de audio
const MASTER_BUS = "Master"
const MUSIC_BUS = "Music"
const SFX_BUS = "SFX"

# Archivo de configuración
const SETTINGS_FILE = "user://settings.cfg"

func _ready():
	# Crear buses de audio si no existen
	create_audio_buses()
	
	# Cargar configuración al iniciar
	load_settings()
	apply_settings()

func create_audio_buses():
	# Verificar si existen los buses, si no, crearlos
	# Nota: Los buses se crean mejor desde el editor en Audio → Audio Buses
	pass

func apply_settings():
	apply_audio_settings()
	apply_video_settings()

func apply_audio_settings():
	# Convertir porcentaje a decibeles
	var master_db = linear_to_db(master_volume / 100.0)
	var music_db = linear_to_db(music_volume / 100.0)
	var sfx_db = linear_to_db(sfx_volume / 100.0)
	
	# Aplicar a los buses
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(MASTER_BUS), master_db)
	
	# Solo si existen los buses adicionales
	if AudioServer.get_bus_index(MUSIC_BUS) >= 0:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(MUSIC_BUS), music_db)
	
	if AudioServer.get_bus_index(SFX_BUS) >= 0:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(SFX_BUS), sfx_db)

func apply_video_settings():
	# Aplicar pantalla completa
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	# Aplicar resolución
	DisplayServer.window_set_size(resolution)
	
	# Centrar ventana
	var screen_size = DisplayServer.screen_get_size()
	var window_size = DisplayServer.window_get_size()
	var centered_pos = (screen_size - window_size) / 2
	DisplayServer.window_set_position(centered_pos)

func save_settings():
	var config = ConfigFile.new()
	
	# Audio
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	
	# Video
	config.set_value("video", "fullscreen", fullscreen)
	config.set_value("video", "resolution_x", resolution.x)
	config.set_value("video", "resolution_y", resolution.y)
	
	# Guardar archivo
	var error = config.save(SETTINGS_FILE)
	if error != OK:
		push_error("Error guardando configuración: " + str(error))
	else:
		print("💾 Configuración guardada exitosamente")

func load_settings():
	var config = ConfigFile.new()
	var error = config.load(SETTINGS_FILE)
	
	if error != OK:
		print("⚠️ No se encontró archivo de configuración, usando valores por defecto")
		return
	
	# Cargar audio
	master_volume = config.get_value("audio", "master_volume", 100.0)
	music_volume = config.get_value("audio", "music_volume", 80.0)
	sfx_volume = config.get_value("audio", "sfx_volume", 100.0)
	
	# Cargar video
	fullscreen = config.get_value("video", "fullscreen", false)
	var res_x = config.get_value("video", "resolution_x", 1920)
	var res_y = config.get_value("video", "resolution_y", 1080)
	resolution = Vector2i(res_x, res_y)
	
	print("📂 Configuración cargada exitosamente")
