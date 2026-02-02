extends Node2D

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
	
	# Aquí el juego continúa normalmente
