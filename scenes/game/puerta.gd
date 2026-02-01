extends StaticBody2D

@export var is_active = false

@onready var sprite = $Sprite2D  # Tu sprite de puerta
@onready var hit_area = $HitArea  # Area2D para detectar golpes

func _ready():
	add_to_group("exit_door")
	
	if hit_area:
		hit_area.body_entered.connect(_on_hit)
	
	# Visual de puerta bloqueada
	if sprite:
		sprite.modulate = Color(0.5, 0.5, 0.5)  # Gris = bloqueada

func activate() -> void:
	is_active = true
	print("🚪 ¡Puerta activada!")
	
	# Visual de puerta desbloqueada
	if sprite:
		sprite.modulate = Color.WHITE
		
		# Efecto de brillo
		var tween = create_tween().set_loops()
		tween.tween_property(sprite, "modulate:v", 1.2, 0.5)
		tween.tween_property(sprite, "modulate:v", 1.0, 0.5)

func _on_hit(body: Node2D) -> void:
	if not is_active:
		print("🚪 Puerta bloqueada - derrota al boss primero")
		return
	
	# Si el jugador golpea la puerta
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
	
	# Cambiar a escena de créditos o menú
	get_tree().change_scene_to_file("res://main_menu.tscn")
