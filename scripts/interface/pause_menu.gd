extends CanvasLayer

# Paneles
@onready var main_panel = $MenuBox
@onready var settings_panel = $SettingsPanel
@onready var controls_panel = $ControlsPanel

# Botones principales
@onready var resume_button = $MenuBox/VBoxContainer/ResumeButton
@onready var save_button = $MenuBox/VBoxContainer/SaveButton
@onready var settings_button = $MenuBox/VBoxContainer/SettingsButton
@onready var controls_button = $MenuBox/VBoxContainer/ControlsButton
@onready var menu_button = $MenuBox/VBoxContainer/MenuButton

# Settings
@onready var master_slider = $SettingsPanel/VBoxContainer/MasterSlider
@onready var music_slider = $SettingsPanel/VBoxContainer/MusicSlider
@onready var sfx_slider = $SettingsPanel/VBoxContainer/SFXSlider
@onready var master_label = $SettingsPanel/VBoxContainer/MasterLabel
@onready var music_label = $SettingsPanel/VBoxContainer/MusicLabel
@onready var sfx_label = $SettingsPanel/VBoxContainer/SFXLabel
@onready var fullscreen_check = $SettingsPanel/VBoxContainer/FullscreenCheck
@onready var resolution_option = $SettingsPanel/VBoxContainer/ResolutionOption
@onready var apply_button = $SettingsPanel/VBoxContainer/ApplyButton
@onready var settings_back = $SettingsPanel/VBoxContainer/BackButton

# Controls
@onready var controls_back = $ControlsPanel/VBoxContainer/BackButton

var is_paused = false

# Resoluciones
var resolutions = {
	"1920x1080": Vector2i(1920, 1080),
	"1600x900": Vector2i(1600, 900),
	"1366x768": Vector2i(1366, 768),
	"1280x720": Vector2i(1280, 720),
	"1024x576": Vector2i(1024, 576)
}

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Conectar botones principales
	resume_button.pressed.connect(unpause)
	save_button.pressed.connect(_on_save_pressed)
	settings_button.pressed.connect(show_settings)
	controls_button.pressed.connect(show_controls)
	menu_button.pressed.connect(_on_menu_pressed)
	
	# Conectar botones de back
	settings_back.pressed.connect(show_main)
	controls_back.pressed.connect(show_main)
	
	# Setup settings
	setup_settings()
	
	# Mostrar panel principal
	show_main()

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		if is_paused:
			if settings_panel.visible or controls_panel.visible:
				show_main()
			else:
				unpause()
		else:
			pause()

# ═══════════════════════════════════════════════════════════════════
#  PAUSA / RETOMAR  ← música se detiene y retoma aquí
# ═══════════════════════════════════════════════════════════════════

func pause():
	is_paused = true
	visible = true
	get_tree().paused = true
	
	# ── AUDIO: pausar música ──
	AudioManager.pause_music()
	
	# Asegurar que se muestra el panel principal
	show_main()
	
	# Animación de entrada
	main_panel.modulate.a = 0
	main_panel.scale = Vector2(0.8, 0.8)
	var tween = create_tween()
	tween.tween_property(main_panel, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(main_panel, "scale", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func unpause():
	is_paused = false
	
	var tween = create_tween()
	tween.tween_property(main_panel, "modulate:a", 0.0, 0.2)
	await tween.finished
	
	visible = false
	get_tree().paused = false
	
	# ── AUDIO: retomar música desde donde la dejó ──
	AudioManager.resume_music()

func show_main():
	main_panel.visible = true
	settings_panel.visible = false
	controls_panel.visible = false

func show_settings():
	main_panel.visible = false
	settings_panel.visible = true
	controls_panel.visible = false

func show_controls():
	main_panel.visible = false
	settings_panel.visible = false
	controls_panel.visible = true

func _on_save_pressed():
	if SaveManager.current_save_slot > 0:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			var save_data = {
				"level": 1,
				"player": {
					"hp": player.current_health,
					"max_hp": player.max_health,
					"position": {
						"x": player.global_position.x,
						"y": player.global_position.y
					}
				},
				"play_time": 0
			}
			
			SaveManager.save_game(SaveManager.current_save_slot, save_data)
			print("💾 Game saved to slot ", SaveManager.current_save_slot)
			
			save_button.text = "SAVED!"
			await get_tree().create_timer(1.0).timeout
			save_button.text = "SAVE GAME"

func _on_menu_pressed():
	# ── AUDIO: detener música al volver al menú principal ──
	AudioManager.stop_music()
	
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/interface/main_menu.tscn")

# ═══════════════════════════════════════════════════════════════════
#  SETTINGS (dentro de pausa)
# ═══════════════════════════════════════════════════════════════════

func setup_settings():
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
	
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	
	update_volume_labels()
	
	fullscreen_check.button_pressed = SettingsManager.fullscreen
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	
	for res_name in resolutions.keys():
		resolution_option.add_item(res_name)
	
	var current_res = str(SettingsManager.resolution.x) + "x" + str(SettingsManager.resolution.y)
	var index = resolutions.keys().find(current_res)
	if index >= 0:
		resolution_option.selected = index
	
	resolution_option.item_selected.connect(_on_resolution_selected)
	
	apply_button.pressed.connect(_on_apply_settings)

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

func _on_apply_settings():
	SettingsManager.apply_settings()
	SettingsManager.save_settings()
	print("✅ Settings applied")
	
	apply_button.text = "APPLIED!"
	await get_tree().create_timer(0.5).timeout
	apply_button.text = "APPLY"
