extends StaticBody2D

@export var is_active = false

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D
@onready var interaction_area = $HitArea  # Area2D nueva

func _ready():
	add_to_group("exit_door")
	
	# Sprite visible
	if sprite:
		sprite.modulate = Color(0.3, 0.3, 0.3, 1.0)
	
	# Desactivar colisión del body
	if collision_shape:
		collision_shape.disabled = true
	
	# Crear y configurar Area2D para detectar jugador
	if not interaction_area:
		interaction_area = Area2D.new()
		add_child(interaction_area)
		
		var area_shape = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(64, 128)  # Ajusta al tamaño de tu puerta
		area_shape.shape = shape
		interaction_area.add_child(area_shape)
	
	# Configurar layers del area
	interaction_area.collision_layer = 16  # Layer 5
	interaction_area.collision_mask = 1   # Detecta Player
	interaction_area.body_entered.connect(_on_body_entered)
	
	# Desactivar al inicio
	interaction_area.monitoring = false

func activate() -> void:
	is_active = true
	print("🚪 ¡Puerta activada!")
	
	# Activar detección
	if interaction_area:
		interaction_area.monitoring = true
	
	# Visual
	if sprite:
		sprite.modulate = Color.WHITE
		
		var tween = create_tween().set_loops()
		tween.tween_property(sprite, "modulate:v", 1.3, 0.5)
		tween.tween_property(sprite, "modulate:v", 1.0, 0.5)

func _on_body_entered(body: Node2D) -> void:
	if not is_active:
		print("🚪 Puerta bloqueada")
		return
	
	if body.is_in_group("player"):
		print("🎉 Jugador entró en la puerta")
		end_game()

func end_game() -> void:
	print("🎉 ¡JUEGO COMPLETADO!")
	
	# Fade out
	var fade = ColorRect.new()
	fade.color = Color.BLACK
	fade.modulate.a = 0
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_tree().root.add_child(fade)
	
	var tween = create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, 2.0)
	await tween.finished
	
	get_tree().change_scene_to_file("res://scenes/interface/main_menu.tscn")
