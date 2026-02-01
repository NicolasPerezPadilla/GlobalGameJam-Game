extends Area2D

@export var speed = 300.0
@export var damage = 15

var direction = Vector2.RIGHT
var has_hit = false

@onready var sprite = $Sprite2D  # O AnimatedSprite2D

func _ready():
	body_entered.connect(_on_body_entered)
	
	# Auto-destruirse después de 10 segundos
	await get_tree().create_timer(10.0).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	
	# Rotar sprite según dirección
	if sprite:
		sprite.rotation = direction.angle()

func _on_body_entered(body: Node2D) -> void:
	if has_hit:
		return
	
	has_hit = true
	
	# Si golpea al jugador
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
	
	# Si golpea una pared
	elif body is StaticBody2D:
		queue_free()
