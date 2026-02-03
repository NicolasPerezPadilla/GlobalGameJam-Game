extends Node2D

# ─── AUDIO ──────────────────────────────────────────────────────
@export var level_music_path: String = "res://audio/music/audio.ogg"

@onready var dialogue_system = $DialogueSystem
@onready var player = $Entities/Player
@onready var pause_menu = $PauseMenu

func _ready():
	# Esperar un frame para que todo esté listo
	await get_tree().process_frame
	
	# Mostrar diálogos iniciales
	if dialogue_system:
		dialogue_system.show_dialogues()
		await dialogue_system.dialogues_finished
		print("✅ Diálogos terminados, juego iniciado")
	
	# ── AUDIO: iniciar música del nivel después de la cinemática ──
	AudioManager.play_music(level_music_path, true)
