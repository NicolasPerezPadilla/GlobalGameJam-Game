extends Control

# Contenidos
@onready var main_menu_content = $MainMenuContent
@onready var save_load_content = $SaveLoadContent
@onready var options_content = $OptionsContent

# Botones del menú principal
@onready var play_button = $MainMenuContent/PlayButton
@onready var options_button = $MainMenuContent/OptionsButton
@onready var quit_button = $MainMenuContent/QuitButton

# Botones de save/load
@onready var slot1_button = $SaveLoadContent/Slot1Container/Slot1Button
@onready var slot2_button = $SaveLoadContent/Slot2Container/Slot2Button
@onready var slot3_button = $SaveLoadContent/Slot3Container/Slot3Button

@onready var delete1_button = $SaveLoadContent/Slot1Container/Delete1Button
@onready var delete2_button = $SaveLoadContent/Slot2Container/Delete2Button
@onready var delete3_button = $SaveLoadContent/Slot3Container/Delete3Button

@onready var save_back_button = $SaveLoadContent/BackButton

# Opciones
@onready var master_slider = $OptionsContent/HSlider
@onready var music_slider = $OptionsContent/HSlider2
@onready var sfx_slider = $OptionsContent/HSlider3
@onready var master_label = $OptionsContent/Label2
@onready var music_label = $OptionsContent/Label3
@onready var sfx_label = $OptionsContent/Label4
@onready var fullscreen_check = $OptionsContent/CheckBox
@onready var resolution_option = $OptionsContent/OptionButton
@onready var apply_button = $OptionsContent/Button
@onready var options_back_button = $OptionsContent/Button2

# Estado
var selected_slot = -1
var delete_mode = false

# Resoluciones
var resolutions = {
	"1920x1080": Vector2i(1920, 1080),
	"1600x900": Vector2i(1600, 900),
	"1366x768": Vector2i(1366, 768),
	"1280x720": Vector2i(1280, 720),
	"1024x576": Vector2i(1024, 576)
}

func _ready():
	# Estilizar todos los botones
	style_all_buttons()
	
	# Mostrar solo menú principal
	show_main_menu()
	
	# Conectar botones del menú principal
	play_button.pressed.connect(_on_play_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Conectar botones de save/load
	slot1_button.pressed.connect(func(): _on_slot_pressed(1))
	slot2_button.pressed.connect(func(): _on_slot_pressed(2))
	slot3_button.pressed.connect(func(): _on_slot_pressed(3))
	delete1_button.pressed.connect(func(): _on_delete_slot(1))
	delete2_button.pressed.connect(func(): _on_delete_slot(2))
	delete3_button.pressed.connect(func(): _on_delete_slot(3))
	save_back_button.pressed.connect(show_main_menu)
	
	# Configurar opciones
	setup_options()
	
	# Conectar botones de opciones
	apply_button.pressed.connect(_on_apply_options)
	options_back_button.pressed.connect(show_main_menu)
	
	# Cargar configuración
	SettingsManager.load_settings()

func style_all_buttons():
	# Menú principal
	MenuStyler.style_button(play_button)
	MenuStyler.style_button(options_button)
	MenuStyler.style_button(quit_button)
	
	# Save/Load
	MenuStyler.style_button(slot1_button)
	MenuStyler.style_button(slot2_button)
	MenuStyler.style_button(slot3_button)
	MenuStyler.style_button(save_back_button)
	
	# Opciones
	MenuStyler.style_button(apply_button)
	MenuStyler.style_button(options_back_button)

func show_main_menu():
	main_menu_content.visible = true
	save_load_content.visible = false
	options_content.visible = false
	delete_mode = false

func show_save_load_menu():
	main_menu_content.visible = false
	save_load_content.visible = true
	options_content.visible = false
	update_save_slots()

func show_options_menu():
	main_menu_content.visible = false
	save_load_content.visible = false
	options_content.visible = true

# ==================== MENÚ PRINCIPAL ====================

func _on_play_pressed():
	show_save_load_menu()

func _on_options_pressed():
	show_options_menu()

func _on_quit_pressed():
	get_tree().quit()

# ==================== SAVE/LOAD ====================

func update_save_slots():
	# Slot 1
	if SaveManager.save_exists(1):
		var data = SaveManager.load_game(1)
		slot1_button.text = "SLOT 1 - LVL " + str(data.get("level", 1))
		delete1_button.visible = true
		delete1_button.disabled = false
	else:
		slot1_button.text = "SLOT 1 - EMPTY"
		delete1_button.visible = false
	
	# Slot 2
	if SaveManager.save_exists(2):
		var data = SaveManager.load_game(2)
		slot2_button.text = "SLOT 2 - LVL " + str(data.get("level", 1))
		delete2_button.visible = true
		delete2_button.disabled = false
	else:
		slot2_button.text = "SLOT 2 - EMPTY"
		delete2_button.visible = false
	
	# Slot 3
	if SaveManager.save_exists(3):
		var data = SaveManager.load_game(3)
		slot3_button.text = "SLOT 3 - LVL " + str(data.get("level", 1))
		delete3_button.visible = true
		delete3_button.disabled = false
	else:
		slot3_button.text = "SLOT 3 - EMPTY"
		delete3_button.visible = false

func _on_slot_pressed(slot: int):
	selected_slot = slot
	start_game(slot)

func _on_delete_pressed():
	delete_mode = not delete_mode
	update_save_slots()

func start_game(slot: int):
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	
	# Cargar o crear partida
	var is_new_game = false
	if SaveManager.save_exists(slot):
		var data = SaveManager.load_game(slot)
		SaveManager.current_save_slot = slot
	else:
		SaveManager.create_new_save(slot)
		SaveManager.current_save_slot = slot
		is_new_game = true
	
	# Si es nueva partida, mostrar cinemática
	if is_new_game:
		get_tree().change_scene_to_file("res://scenes/interface/intro_cutscene.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/game/first_scene.tscn")

# ==================== OPCIONES ====================

func setup_options():
	# Sliders de audio
	master_slider.min_value = 0
	master_slider.max_value = 100
	master_slider.step = 1
	master_slider.value = SettingsManager.master_volume
	
	music_slider.min_value = 0
	music_slider.max_value = 100
	music_slider.step = 1
	music_slider.value = SettingsManager.music_volume
	
	sfx_slider.min_value = 0
	sfx_slider.max_value = 100
	sfx_slider.step = 1
	sfx_slider.value = SettingsManager.sfx_volume
	
	# Conectar sliders
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	
	# Actualizar labels
	update_volume_labels()
	
	# Fullscreen
	fullscreen_check.button_pressed = SettingsManager.fullscreen
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	
	# Resoluciones
	for res_name in resolutions.keys():
		resolution_option.add_item(res_name)
	
	var current_res = str(SettingsManager.resolution.x) + "x" + str(SettingsManager.resolution.y)
	var index = resolutions.keys().find(current_res)
	if index >= 0:
		resolution_option.selected = index
	
	resolution_option.item_selected.connect(_on_resolution_selected)

func _on_master_changed(value: float):
	SettingsManager.master_volume = value
	update_volume_labels()
	SettingsManager.apply_audio_settings()

func _on_music_changed(value: float):
	SettingsManager.music_volume = value
	update_volume_labels()
	SettingsManager.apply_audio_settings()

func _on_sfx_changed(value: float):
	SettingsManager.sfx_volume = value
	update_volume_labels()
	SettingsManager.apply_audio_settings()

func update_volume_labels():
	master_label.text = "MASTER: " + str(int(master_slider.value)) + "%"
	music_label.text = "MUSIC: " + str(int(music_slider.value)) + "%"
	sfx_label.text = "SFX: " + str(int(sfx_slider.value)) + "%"

func _on_fullscreen_toggled(toggled: bool):
	SettingsManager.fullscreen = toggled

func _on_resolution_selected(index: int):
	var res_name = resolutions.keys()[index]
	SettingsManager.resolution = resolutions[res_name]

func _on_apply_options():
	SettingsManager.apply_settings()
	SettingsManager.save_settings()
	print("✅ Settings applied and saved")

func _on_delete_slot(slot: int):
	# Crear diálogo de confirmación
	var confirm_dialog = AcceptDialog.new()
	confirm_dialog.dialog_text = "Delete save slot " + str(slot) + "?\nThis cannot be undone."
	confirm_dialog.title = "Confirm Delete"
	confirm_dialog.ok_button_text = "DELETE"
	confirm_dialog.add_cancel_button("CANCEL")
	
	add_child(confirm_dialog)
	confirm_dialog.popup_centered()
	
	# Esperar confirmación
	confirm_dialog.confirmed.connect(func():
		SaveManager.delete_save(slot)
		update_save_slots()
		confirm_dialog.queue_free()
	)
	
	confirm_dialog.canceled.connect(func():
		confirm_dialog.queue_free()
	)
		
