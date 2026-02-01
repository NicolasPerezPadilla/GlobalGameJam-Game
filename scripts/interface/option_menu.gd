extends Control

#AudioSliders
@onready var master_slider = $Panel/VBoxContainer/AudioSection/MasterSlider
@onready var music_slider = $Panel/VBoxContainer/AudioSection/MusicSlider
@onready var sfx_slider = $Panel/VBoxContainer/AudioSection/SFXSlider
#AudioLabels
@onready var master_label = $Panel/VBoxContainer/AudioSection/MasterLabel
@onready var music_label = $Panel/VBoxContainer/AudioSection/MusicLabel
@onready var sfx_label = $Panel/VBoxContainer/AudioSection/SFXLabel

#ResolutionOptions
@onready var fullscreen_checkbox = $Panel/VBoxContainer/VideoSection/FullscreenCheckbox
@onready var resolution_option = $Panel/VBoxContainer/VideoSection/ResolutionOption

#Buttons
@onready var back_button = $Panel/BackButton
@onready var apply_button = $Panel/ApplyButton

# Resoluciones disponibles (viewport scaling)
var resolutions = {
	"1920x1080": Vector2i(1920, 1080),
	"1600x900": Vector2i(1600, 900),
	"1366x768": Vector2i(1366, 768),
	"1280x720": Vector2i(1280, 720),
	"1024x576": Vector2i(1024, 576)
}


func _ready() -> void:
	# Configurar sliders de audio
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
	
	# Actualizar labels
	update_volume_labels()
	
	# Llenar opciones de resolución
	for res_name in resolutions.keys():
		resolution_option.add_item(res_name)
	
	# Seleccionar resolución actual
	var current_res = str(SettingsManager.resolution.x) + "x" + str(SettingsManager.resolution.y)
	var index = resolution_option.get_item_index(resolution_option.get_item_id(resolutions.keys().find(current_res)))
	if index >= 0:
		resolution_option.selected = resolutions.keys().find(current_res)

func _on_master_slider_value_changed(value: float) -> void:
	SettingsManager.master_volume = value
	update_volume_labels()
	SettingsManager.apply_audio_settings()


func _on_music_slider_value_changed(value: float) -> void:
	SettingsManager.music_volume = value
	update_volume_labels()
	SettingsManager.apply_audio_settings()


func _on_sfx_slider_value_changed(value: float) -> void:
	SettingsManager.sfx_volume = value
	update_volume_labels()
	SettingsManager.apply_audio_settings()
	
func update_volume_labels():
	master_label.text = "Master Volume: " + str(int(master_slider.value)) + "%"
	music_label.text = "Music Volume: " + str(int(music_slider.value)) + "%"
	sfx_label.text = "SFX Volume: " + str(int(sfx_slider.value)) + "%"

func _on_fullscreen_check_box_toggled(toggled_on: bool) -> void:
	SettingsManager.fullscreen = toggled_on

func _on_resolution_option_item_selected(index: int) -> void:
	var res_name = resolutions.keys()[index]
	SettingsManager.resolution = resolutions[res_name]

func _on_back_button_pressed() -> void:
	visible = false


func _on_apply_button_pressed() -> void:
	SettingsManager.apply_settings()
	SettingsManager.save_settings()
	print("✅ Configuración guardada y aplicada")
