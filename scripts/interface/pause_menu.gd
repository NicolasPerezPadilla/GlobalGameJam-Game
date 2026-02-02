extends CanvasLayer

@onready var menu_box = $MenuBox
@onready var resume_button = $MenuBox/VBoxContainer/ResumeButton
@onready var save_button = $MenuBox/VBoxContainer/SaveButton
@onready var settings_button = $MenuBox/VBoxContainer/SettingsButton
@onready var controls_button = $MenuBox/VBoxContainer/ControlsButton
@onready var menu_button = $MenuBox/VBoxContainer/MenuButton

# Paneles adicionales
#@onready var settings_panel = $SettingsPanel  # Lo crearemos
@onready var controls_panel = $ControlsPanel  # Lo crearemos

var is_paused = false

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS  # IMPORTANTE: Procesar incluso pausado
	
	# Estilizar botones
	style_all_buttons()
	
	# Conectar
	resume_button.pressed.connect(unpause)
	save_button.pressed.connect(_on_save_pressed)
	settings_button.pressed.connect(show_settings)
	controls_button.pressed.connect(show_controls)
	menu_button.pressed.connect(_on_menu_pressed)

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):  # ESC
		if is_paused:
			unpause()
		else:
			pause()

func pause():
	is_paused = true
	visible = true
	get_tree().paused = true
	
	# Animación de entrada
	menu_box.modulate.a = 0
	menu_box.scale = Vector2(0.8, 0.8)
	var tween = create_tween()
	tween.tween_property(menu_box, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(menu_box, "scale", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func unpause():
	is_paused = false
	
	# Animación de salida
	var tween = create_tween()
	tween.tween_property(menu_box, "modulate:a", 0.0, 0.2)
	await tween.finished
	
	visible = false
	get_tree().paused = false

func _on_save_pressed():
	if SaveManager.current_save_slot > 0:
		# Obtener datos del jugador
		var player = get_tree().get_first_node_in_group("player")
		if player:
			var save_data = SaveManager.SaveData.new()
			save_data.slot_number = SaveManager.current_save_slot
			save_data.health = player.current_health
			save_data.max_health = player.max_health
			save_data.position = player.global_position
			save_data.level = 1  # Ajusta según tu juego
			
			SaveManager.save_game(SaveManager.current_save_slot, save_data)
			print("💾 Game saved!")
			
			# Feedback visual
			save_button.text = "SAVED!"
			await get_tree().create_timer(1.0).timeout
			save_button.text = "SAVE GAME"

func show_settings():
	# Ocultar menú principal, mostrar settings
	menu_box.visible = false
	#settings_panel.visible = true

func show_controls():
	# Ocultar menú principal, mostrar controles
	menu_box.visible = false
	controls_panel.visible = true

func _on_menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/interface/main_menu.tscn")

func style_all_buttons():
	for button in [resume_button, save_button, settings_button, controls_button, menu_button]:
		MenuStyler.style_button(button)
