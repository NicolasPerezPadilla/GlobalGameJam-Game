extends Area2D

@export var speed = 800
@export var damage = 15

var direction = Vector2.RIGHT
var has_hit = false

@onready var sprite = $Sprite2D  # O AnimatedSprite2D

func _ready():
	
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Rotar sprite según dirección
	if sprite:
		sprite.rotation = direction.angle()
	
	# Auto-destruirse después de 10 segundos
	await get_tree().create_timer(10.0).timeout
	if is_instance_valid(self):
		queue_free()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if has_hit:
		return
	
	has_hit = true
	
	# Si golpea al jugador
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		print("💥 Proyectil golpeó al jugador")
		queue_free()
	# Si golpea una pared
	elif body is StaticBody2D or body is TileMap:
		print("💨 Proyectil golpeó pared")
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	# Por si golpea otra área
	if not has_hit:
		has_hit = true
		queue_free()
