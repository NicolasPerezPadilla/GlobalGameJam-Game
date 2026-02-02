extends Control

@onready var video_player = $VideoStreamPlayer
@onready var skip_button = $SkipButton

@export var video_path = "res://resources/interface/video.ogv"
@export var next_scene = "res://scenes/game/first_scene.tscn"

var mouse_idle_timer = 0.0
var mouse_hide_delay = 2.0
var mouse_moved = false

func _ready():
	# Cargar y reproducir video
	var video_stream = VideoStreamTheora.new()  # O VideoStreamAV1 si usas .webm
	
	# Para MP4, necesitas convertirlo a .ogv o .webm
	# Godot no soporta MP4 directamente
	# Usa FFmpeg: ffmpeg -i intro.mp4 -c:v libtheora -q:v 7 -c:a libvorbis -q:a 4 intro.ogv
	
	video_stream.file = video_path
	video_player.stream = video_stream
	video_player.play()
	
	# Conectar señal de fin
	video_player.finished.connect(_on_video_finished)
	
	# Configurar botón de skip
	skip_button.modulate.a = 0
	skip_button.pressed.connect(skip_cutscene)
	
	# Estilizar botón
	style_skip_button()
	
	# Ocultar cursor al inicio
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _process(delta: float) -> void:
	# Detectar movimiento del mouse
	if Input.get_last_mouse_velocity().length() > 0:
		mouse_moved = true
		mouse_idle_timer = 0.0
		show_skip_button()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		mouse_idle_timer += delta
		
		# Ocultar después de inactividad
		if mouse_idle_timer > mouse_hide_delay:
			hide_skip_button()
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	
	# Detectar Enter o Escape para saltar
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_cancel"):
		skip_cutscene()

func show_skip_button():
	if skip_button.modulate.a < 1.0:
		var tween = create_tween()
		tween.tween_property(skip_button, "modulate:a", 1.0, 0.3)

func hide_skip_button():
	if skip_button.modulate.a > 0.0:
		var tween = create_tween()
		tween.tween_property(skip_button, "modulate:a", 0.0, 0.3)

func skip_cutscene():
	video_player.stop()
	go_to_next_scene()

func _on_video_finished():
	go_to_next_scene()

func go_to_next_scene():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(next_scene)

func style_skip_button():
	# Posición: Abajo a la derecha
	skip_button.position = Vector2(1600, 950)
	skip_button.size = Vector2(250, 60)
	
	# Estilo
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.7)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color.WHITE
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	
	skip_button.add_theme_stylebox_override("normal", style)
	skip_button.add_theme_font_size_override("font_size", 24)
	skip_button.add_theme_color_override("font_color", Color.WHITE)
