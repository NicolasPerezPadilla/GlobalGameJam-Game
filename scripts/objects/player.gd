extends CharacterBody2D

# Velocidades y aceleración - RÁPIDA PERO SUAVE
var SPEED = 415.0
var MAX_RUN_SPEED = 460.0
var ACCELERATION = 2800.0
var AIR_ACCELERATION = 2200.0
var FRICTION = 2200.0
var AIR_RESISTANCE = 1000.0

# Salto
var JUMP_STRENGTH = -450.0
var coyote_time = 0.15
var coyote_timer = 0.0
var jump_buffer_time = 0.1
var jump_buffer_timer = 0.0

# Wall mechanics
var WALL_SLIDE_SPEED = 300
var WALL_JUMP_X_FORCE = 500.0
var WALL_JUMP_Y_FORCE = -400.0
var WALL_RUN_SPEED = 500.0

# Estados
var is_wall_sliding = false
var is_wall_running = false
var last_wall_normal = 0
var was_running_on_ground = false
var just_finished_wall_run = false

# Momentum boost
var momentum_multiplier = 1.0
var MAX_MOMENTUM = 1.5

# SISTEMA DE ATAQUE
var is_attacking = false
var attack_duration = 0.3  # Duración del ataque en segundos
var attack_timer = 0.0
var attack_damage = 10
var attack_knockback = 300.0  # Fuerza del knockback
var can_move_while_attacking = false  # Si puede moverse durante ataque
var attack_cooldown = 0.1  # Cooldown después del ataque
var cooldown_timer = 0.0

# Referencias (asignar en el editor o por código)
@onready var attack_hitbox: Area2D = $AttackHitbox  # Tu Area2D
@onready var attack_collision: CollisionShape2D = $AttackHitbox/CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer  # Tu AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D  # Tu sprite para flip

func _ready():
	# Desactivar hitbox al inicio
	if attack_collision:
		attack_collision.disabled = true
	
	# Conectar señal del Area2D para detectar golpes
	if attack_hitbox:
		attack_hitbox.body_entered.connect(_on_attack_hit)

func _physics_process(delta: float) -> void:
	# Timers
	if coyote_timer > 0:
		coyote_timer -= delta
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta
	if cooldown_timer > 0:
		cooldown_timer -= delta
	
	var was_on_floor = is_on_floor()
	var was_wall_running_before = is_wall_running
	
	# Manejar ataque
	handle_attack(delta)
	
	# Gravedad y mecánicas de pared
	handle_gravity(delta)
	
	# Solo permitir movimiento si no está atacando O si puede moverse mientras ataca
	if not is_attacking or can_move_while_attacking:
		handle_movement(delta)
	
	handle_jump()
	handle_wall_mechanics(delta)
	
	# Flip del sprite según dirección
	update_sprite_direction()
	
	# Detectar cuando termina el wall run
	if was_wall_running_before and not is_wall_running and not is_on_wall():
		if velocity.y < 0:
			velocity.y = 0
		just_finished_wall_run = true
	
	if just_finished_wall_run and is_on_floor():
		just_finished_wall_run = false
	
	# Coyote time
	if was_on_floor and not is_on_floor() and velocity.y >= 0:
		coyote_timer = coyote_time
	
	# Calcular momentum para speedruns
	if is_on_floor():
		var speed_ratio = abs(velocity.x) / MAX_RUN_SPEED
		momentum_multiplier = lerpf(1.0, MAX_MOMENTUM, speed_ratio)
		was_running_on_ground = Input.is_action_pressed("RUN")
	
	if is_on_floor() or is_on_wall():
		was_running_on_ground = Input.is_action_pressed("RUN")
	
	move_and_slide()

func handle_attack(delta: float) -> void:
	# Iniciar ataque
	if Input.is_action_just_pressed("ATTACK") and not is_attacking and cooldown_timer <= 0:
		start_attack()
	
	# Manejar duración del ataque
	if is_attacking:
		attack_timer -= delta
		if attack_timer <= 0:
			end_attack()

func start_attack() -> void:
	is_attacking = true
	attack_timer = attack_duration
	
	# Activar hitbox
	if attack_collision:
		attack_collision.disabled = false
	
	# Reproducir animación de ataque
	if animation_player and animation_player.has_animation("attack"):
		animation_player.play("attack")
	
	# Opcional: pequeño impulso hacia adelante al atacar
	var attack_impulse = 100.0
	if sprite and sprite.flip_h:
		velocity.x -= attack_impulse
	else:
		velocity.x += attack_impulse

func end_attack() -> void:
	is_attacking = false
	cooldown_timer = attack_cooldown
	
	# Desactivar hitbox
	if attack_collision:
		attack_collision.disabled = true
	
	# Volver a animación idle/run
	if animation_player:
		if abs(velocity.x) > 10:
			if animation_player.has_animation("run"):
				animation_player.play("run")
		else:
			if animation_player.has_animation("idle"):
				animation_player.play("idle")

func _on_attack_hit(body: Node2D) -> void:
	# Verificar si el cuerpo es un enemigo o tiene vida
	if body.has_method("take_damage"):
		# Calcular dirección del knockback
		var knockback_direction = (body.global_position - global_position).normalized()
		
		# Aplicar daño y knockback
		body.take_damage(attack_damage, knockback_direction * attack_knockback)
		
		print("¡Golpe exitoso a: ", body.name, "!")

func update_sprite_direction() -> void:
	if sprite:
		# Flip basado en la velocidad horizontal
		if velocity.x > 0:
			sprite.flip_h = false
		elif velocity.x < 0:
			sprite.flip_h = true

func handle_gravity(delta: float) -> void:
	if is_on_floor():
		return
	
	if is_wall_running:
		velocity.y = -WALL_RUN_SPEED
		return
	
	if is_wall_sliding:
		velocity.y = min(velocity.y + get_gravity().y * delta, WALL_SLIDE_SPEED)
		return
	
	if just_finished_wall_run:
		velocity += get_gravity() * delta * 1.5
		return
	
	if velocity.y > 0:
		velocity += get_gravity() * delta * 1.2
	else:
		velocity += get_gravity() * delta

func handle_movement(delta: float) -> void:
	var direction := Input.get_axis("LEFT", "RIGHT")
	var target_speed = SPEED
	
	var can_run = Input.is_action_pressed("RUN")
	if not is_on_floor() and not is_on_wall():
		if can_run and not was_running_on_ground:
			can_run = false
	
	if can_run:
		target_speed = MAX_RUN_SPEED * momentum_multiplier
	
	if direction != 0:
		var accel = ACCELERATION if is_on_floor() else AIR_ACCELERATION
		velocity.x = move_toward(velocity.x, direction * target_speed, accel * delta)
		
		if is_on_wall_only() and Input.is_action_pressed("RUN"):
			var wall_normal = get_wall_normal()
			if sign(direction) != sign(wall_normal.x):
				is_wall_running = true
				last_wall_normal = wall_normal.x
				just_finished_wall_run = false
			else:
				is_wall_running = false
		else:
			is_wall_running = false
	else:
		var friction = FRICTION if is_on_floor() else AIR_RESISTANCE
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		is_wall_running = false

func handle_jump() -> void:
	if Input.is_action_just_pressed("JUMP"):
		jump_buffer_timer = jump_buffer_time
	
	if jump_buffer_timer > 0 and (is_on_wall_only() or is_wall_running):
		var wall_normal = get_wall_normal()
		velocity.x = wall_normal.x * WALL_JUMP_X_FORCE
		velocity.y = WALL_JUMP_Y_FORCE
		is_wall_sliding = false
		is_wall_running = false
		jump_buffer_timer = 0
		momentum_multiplier = clamp(momentum_multiplier, 1.0, MAX_MOMENTUM)
		was_running_on_ground = true
		just_finished_wall_run = false
		return
	
	if jump_buffer_timer > 0 and (is_on_floor() or coyote_timer > 0):
		velocity.y = JUMP_STRENGTH
		jump_buffer_timer = 0
		coyote_timer = 0
		is_wall_running = false
		if abs(velocity.x) > MAX_RUN_SPEED * 0.9:
			velocity.x *= 1.05
		return

func handle_wall_mechanics(delta: float) -> void:
	if not is_on_wall() or is_on_floor():
		is_wall_sliding = false
		is_wall_running = false
		return
	
	if not is_wall_running:
		if velocity.y > 0:
			is_wall_sliding = true
			last_wall_normal = get_wall_normal().x
		else:
			is_wall_sliding = false
