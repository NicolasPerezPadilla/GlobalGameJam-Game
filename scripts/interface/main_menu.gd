extends Control

const MenuStyler = preload("res://scripts/interface/styles/menu_styler.gd")

@onready var play_button = $VBoxContainer/PlayButton
@onready var options_button = $VBoxContainer/OptionsButton
@onready var quit_button = $VBoxContainer/QuitButton
@onready var options_menu = $OptionsMenu
@onready var vbox = $VBoxContainer
@onready var title = $Title

@export var game_scene: PackedScene

func _ready():
	MenuStyler.style_button(play_button)
	MenuStyler.style_button(options_button)
	MenuStyler.style_button(quit_button)
	
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color.WHITE)
	
	options_menu.visible = false
	# Cargar configuración guardada
	SettingsManager.load_settings()
	animate_menu_in()
	
func animate_menu_in():
	vbox.modulate.a = 0
	vbox.position.y += 50
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(vbox, "modulate:a", 1.0, 0.5)
	tween.tween_property(vbox, "position:y", vbox.position.y - 50, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _on_play_button_pressed() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/interface/save_load_menu.tscn")

func _on_options_button_pressed() -> void:
	var tween = create_tween()
	options_menu.modulate.a = 0
	options_menu.visible = true
	tween.tween_property(options_menu, "modulate:a", 1.0, 0.2)

func _on_quit_button_pressed() -> void:
	get_tree().quit()
