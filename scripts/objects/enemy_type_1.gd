extends CharacterBody2D

@export var max_health = 50
@export var move_speed = 100.0
@export var run_away_speed = 180.0
@export var damage = 10
@export var detection_range = 300.0
@export var attack_range = 50.0
@export var attack_cooldown = 1.0
@export var fear_duration = 3.0  # Tiempo que huye después de recibir golpe

var current_health = max_health
var player: CharacterBody2D = null
var attack_timer = 0.0
var is_dead = false
var is_scared = false
var fear_timer = 0.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	current_health = max_health
	# Esperar un frame antes de buscar al jugador
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	# Verificar que el enemigo está en el árbol de la escena
	if not is_inside_tree():
		return
	
	# Timers
	if attack_timer > 0:
		attack_timer -= delta
	
	if fear_timer > 0:
		fear_timer -= delta
		if fear_timer <= 0:
			is_scared = false
	
	if player and is_instance_valid(player):
		var distance_to_player = global_position.distance_to(player.global_position)
		
		# Comportamiento según estado
		if is_scared:
			# HUIR del jugador
			run_away_from_player()
		elif distance_to_player < detection_range:
			# Comportamiento normal - perseguir
			var direction = (player.global_position - global_position).normalized()
			
			if distance_to_player > attack_range:
				# Moverse hacia el jugador
				velocity.x = direction.x * move_speed
				
				# FLIP CORRECTO: basado en la dirección del movimiento
				if animated_sprite:
					if velocity.x > 0:
						animated_sprite.flip_h = false
					elif velocity.x < 0:
						animated_sprite.flip_h = true
					
					if animated_sprite.animation != "walk":
						animated_sprite.play("walk")
			else:
				# En rango de ataque
				velocity.x = 0
				if attack_timer <= 0:
					attack_player()
					attack_timer = attack_cooldown
		else:
			# Fuera de rango - idle
			velocity.x = 0
			if animated_sprite and animated_sprite.animation != "walk":
				animated_sprite.play("walk")
				animated_sprite.pause()
	
	# Aplicar gravedad
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# PROTECCIÓN: Solo llamar move_and_slide si está en el árbol
	if is_inside_tree():
		move_and_slide()

func run_away_from_player() -> void:
	if not player or not is_instance_valid(player):
		return
	
	# Huir en dirección opuesta
	var direction = (global_position - player.global_position).normalized()
	velocity.x = direction.x * run_away_speed
	
	# FLIP CORRECTO: basado en la dirección del movimiento
	if animated_sprite:
		if velocity.x > 0:
			animated_sprite.flip_h = false
		elif velocity.x < 0:
			animated_sprite.flip_h = true
		
		if animated_sprite.animation != "run":
			animated_sprite.play("run")

func attack_player() -> void:
	if not player or not is_instance_valid(player):
		return
		
	if player.has_method("take_damage"):
		var distance = global_position.distance_to(player.global_position)
		if distance < attack_range:
			player.take_damage(damage)
			if animated_sprite:
				animated_sprite.play("hit")
				# Volver a walk después del golpe
				await animated_sprite.animation_finished
				if not is_dead and animated_sprite:
					animated_sprite.play("walk")

func take_damage(damage_amount: int) -> void:
	if is_dead:
		return
	
	current_health -= damage_amount
	
	# Entrar en modo miedo
	is_scared = true
	fear_timer = fear_duration
	
	# Flash blanco
	if animated_sprite:
		animated_sprite.modulate = Color.WHITE
		await get_tree().create_timer(0.1).timeout
		if animated_sprite:
			animated_sprite.modulate = Color(1, 1, 1, 1)
	
	print("👾 Enemigo recibió ", damage_amount, " de daño. Vida: ", current_health)
	
	if current_health <= 0:
		die()

func apply_knockback(force: Vector2) -> void:
	# Aplicar el knockback del golpe fuerte
	velocity = force
	is_scared = true
	fear_timer = fear_duration

func die() -> void:
	is_dead = true
	print("💀 Enemigo murió")
	queue_free()
