extends StaticBody2D

# Referencias opcionales
var hit_area: Area2D = null
var sprite: Sprite2D = null
var collision_shape: CollisionShape2D = null

var is_active = false

func _ready():
	# Buscar nodos de forma segura
	hit_area = get_node_or_null("HitArea")
	sprite = get_node_or_null("Sprite2D")
	collision_shape = get_node_or_null("CollisionShape2D")
	
	# Debug - ver qué nodos se encontraron
	if hit_area:
		print("✅ Puerta: HitArea encontrada")
		hit_area.body_entered.connect(_on_player_entered)
	else:
		push_warning("⚠️ Puerta: No se encontró HitArea - La puerta no detectará al jugador")
	
	if sprite:
		print("✅ Puerta: Sprite2D encontrado")
	else:
		push_warning("⚠️ Puerta: No se encontró Sprite2D")
	
	if collision_shape:
		print("✅ Puerta: CollisionShape2D encontrado")
	else:
		push_warning("⚠️ Puerta: No se encontró CollisionShape2D")
	
	# Desactivar al inicio
	deactivate()

func activate() -> void:
	is_active = true
	
	# Cambiar apariencia
	if sprite:
		sprite.modulate = Color.GREEN
	
	print("🚪 Puerta ACTIVADA - Puedes pasar al siguiente nivel")

func deactivate() -> void:
	is_active = false
	
	# Apariencia bloqueada
	if sprite:
		sprite.modulate = Color.RED

func _on_player_entered(body: Node2D) -> void:
	if not is_active:
		print("🚪 Puerta bloqueada - Derrota al boss primero")
		return
	
	if body.is_in_group("player"):
		print("🚪 Pasando al siguiente nivel...")
		# Aquí cambias de escena
		get_tree().change_scene_to_file("res://scenes/interface/main_menu.tscn")
