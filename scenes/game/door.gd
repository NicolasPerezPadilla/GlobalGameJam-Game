extends StaticBody2D

@export var is_active = false

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D

func _ready():
	add_to_group("exit_door")
	
	# Sprite visible pero sin colisión al inicio
	if sprite:
		sprite.modulate = Color(0.3, 0.3, 0.3, 1.0)  # Oscura = bloqueada
	
	# Desactivar colisión
	if collision_shape:
		collision_shape.disabled = true
	
	collision_layer = 0
	collision_mask = 0

func activate() -> void:
	is_active = true
	print("🚪 ¡Puerta activada!")
	
	# Activar colisión
	if collision_shape:
		collision_shape.disabled = false
	
	collision_layer = 16  # Layer 5 (Door)
	collision_mask = 1    # Detecta Player
	
	# Visual de puerta desbloqueada
	if sprite:
		sprite.modulate = Color.WHITE
		
		# Efecto de brillo
		var tween = create_tween().set_loops()
		tween.tween_property(sprite, "modulate:v", 1.3, 0.5)
		tween.tween_property(sprite, "modulate:v", 1.0, 0.5)

func _on_body_entered(body: Node2D) -> void:
	if not is_active:
		return
	
	if body.is_in_group("player"):
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
