extends CharacterBody2D

@export var max_health = 50
@export var move_speed = 100.0
@export var damage = 10
@export var detection_range = 300.0
@export var attack_range = 50.0
@export var attack_cooldown = 1.0

var current_health = max_health
var player: CharacterBody2D = null
var attack_timer = 0.0
var is_dead = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	current_health = max_health
	player = get_tree().get_first_node_in_group("player")
	
	print("👾 Enemigo creado en: ", global_position)
	
	# DEBUG: Hacer visible
	if animated_sprite:
		animated_sprite.modulate = Color.RED
	else:
		modulate = Color.RED

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	if attack_timer > 0:
		attack_timer -= delta
	
	if player:
		var distance_to_player = global_position.distance_to(player.global_position)
		
		if distance_to_player < detection_range:
			var direction = (player.global_position - global_position).normalized()
			
			if distance_to_player > attack_range:
				velocity.x = direction.x * move_speed
				
				if animated_sprite:
					animated_sprite.flip_h = direction.x < 0
					if animated_sprite.animation != "run":
						animated_sprite.play("run")
			else:
				velocity.x = 0
				if attack_timer <= 0:
					attack_player()
					attack_timer = attack_cooldown
				
				if animated_sprite and animated_sprite.animation != "attack":
					animated_sprite.play("idle")
		else:
			velocity.x = 0
			if animated_sprite and animated_sprite.animation != "idle":
				animated_sprite.play("idle")
	
	# Gravedad
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	move_and_slide()

func attack_player() -> void:
	print("⚔️ Enemigo atacando!")
	if player and player.has_method("take_damage"):
		var distance = global_position.distance_to(player.global_position)
		if distance < attack_range:
			player.take_damage(damage)
			if animated_sprite:
				animated_sprite.play("attack")

func take_damage(damage_amount: int) -> void:
	if is_dead:
		return
	
	current_health -= damage_amount
	
	# Flash rojo
	if animated_sprite:
		animated_sprite.modulate = Color.WHITE
		await get_tree().create_timer(0.1).timeout
		if animated_sprite:
			animated_sprite.modulate = Color.RED
	else:
		modulate = Color.WHITE
		await get_tree().create_timer(0.1).timeout
		modulate = Color.RED
	
	print("👾 Enemigo recibió ", damage_amount, " de daño. Vida: ", current_health)
	
	if current_health <= 0:
		die()

func die() -> void:
	is_dead = true
	print("💀 Enemigo murió")
	
	# Opcional: animación de muerte
	#if animated_sprite and animated_sprite.has_animation("death"):
		#animated_sprite.play("death")
		#await animated_sprite.animation_finished
	
	queue_free()
