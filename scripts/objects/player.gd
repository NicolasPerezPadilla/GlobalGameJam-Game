extends CharacterBody2D

# Velocidades y aceleración
var SPEED = 560
var MAX_RUN_SPEED = 1000.0
var ACCELERATION = 3200
var AIR_ACCELERATION = 2200.0
var FRICTION = 2700
var AIR_RESISTANCE = 1200

# Salto
var JUMP_STRENGTH = -600.0
var coyote_time = 0.15
var coyote_timer = 0.0
var jump_buffer_time = 0.1
var jump_buffer_timer = 0.0

# Wall mechanics
var WALL_SLIDE_SPEED = 700.0
var WALL_JUMP_X_FORCE = 900.0
var WALL_JUMP_Y_FORCE = -700.0
var WALL_RUN_SPEED = 900.0

# Estados
var is_wall_sliding = false
var is_wall_running = false
var last_wall_normal = 0
var was_running_on_ground = false
var just_finished_wall_run = false

# Momentum boost
var momentum_multiplier = 1.0
var MAX_MOMENTUM = 1.5

# SISTEMA DE ATAQUE MEJORADO
var is_attacking = false
var attack_duration = 0.25  # Más rápido para fluidez
var attack_timer = 0.0
var attack_damage = 25
var attack_knockback = 400.0
var can_move_while_attacking = true  # CAMBIO: Ahora SÍ puede moverse
var attack_cooldown = 0.05  # Cooldown muy corto
var cooldown_timer = 0.0
var combo_count = 0
var combo_timer = 0.0
var combo_window = 1.5  # Tiempo para mantener combo

# HITSTOP (freeze frame al golpear)
var hitstop_duration = 0.0
var hitstop_timer = 0.0

# SISTEMA DE VIDA
var max_health = 100
var current_health = 100
var is_invulnerable = false
var invulnerability_time = 0.5
var invulnerability_timer = 0.0

# CAMARA SHAKE
var camera_shake_amount = 0.0
var camera_shake_decay = 5.0

var last_attack: String = "attack1"

# Referencias
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var attack_collision: CollisionShape2D = $AttackHitbox/CollisionShape2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D
var original_camera_position: Vector2

# Lista para evitar golpear al mismo enemigo varias veces en un ataque
var enemies_hit_this_attack = []

func _ready():
	if attack_collision:
		attack_collision.disabled = true
	
	if attack_hitbox:
		attack_hitbox.body_entered.connect(_on_attack_hit)
	
	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_animation_finished)
	
	if camera:
		original_camera_position = camera.position
	
	current_health = max_health

func _physics_process(delta: float) -> void:
	# HITSTOP - Congela el juego brevemente
	if hitstop_timer > 0:
		hitstop_timer -= delta
		return  # No procesar nada durante hitstop
	
	# Timers
	if coyote_timer > 0:
		coyote_timer -= delta
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta
	if cooldown_timer > 0:
		cooldown_timer -= delta
	if combo_timer > 0:
		combo_timer -= delta
	else:
		combo_count = 0  # Reset combo si se acaba el tiempo
	
	if invulnerability_timer > 0:
		invulnerability_timer -= delta
		# Flash effect
		if animated_sprite:
			animated_sprite.modulate.a = 0.5 if int(invulnerability_timer * 20) % 2 == 0 else 1.0
	else:
		is_invulnerable = false
		if animated_sprite:
			animated_sprite.modulate.a = 1.0
	
	var was_on_floor = is_on_floor()
	var was_wall_running_before = is_wall_running
	
	# Manejar ataque
	handle_attack(delta)
	
	# Gravedad y mecánicas de pared
	handle_gravity(delta)
	
	# Movimiento (ahora permitido durante ataque)
	handle_movement(delta)
	
	handle_jump()
	handle_wall_mechanics(delta)
	
	# Actualizar animaciones
	update_animations()
	
	# Camera shake
	handle_camera_shake(delta)
	
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
	
	# Calcular momentum
	if is_on_floor():
		var speed_ratio = abs(velocity.x) / MAX_RUN_SPEED
		momentum_multiplier = lerpf(1.0, MAX_MOMENTUM, speed_ratio)
		was_running_on_ground = Input.is_action_pressed("RUN")
	
	if is_on_floor() or is_on_wall():
		was_running_on_ground = Input.is_action_pressed("RUN")
	
	move_and_slide()

func handle_attack(delta: float) -> void:
	# CANCELACIÓN DE ATAQUE - puedes atacar de nuevo antes de terminar
	if Input.is_action_just_pressed("ATTACK") and cooldown_timer <= 0:
		start_attack()
	
	# Manejar duración del ataque
	if is_attacking:
		attack_timer -= delta
		if attack_timer <= 0:
			end_attack()

func start_attack() -> void:
	# Cancelar ataque anterior si existe
	if is_attacking:
		end_attack()
	
	is_attacking = true
	attack_timer = attack_duration
	enemies_hit_this_attack.clear()
	
	# Activar hitbox
	if attack_collision:
		attack_collision.disabled = false
	
	# Reproducir animación de ataque
	if animated_sprite:
		if last_attack == "attack1":
			animated_sprite.play("kick")
			last_attack = "kick"
		elif last_attack == "kick":
			animated_sprite.play("attack2")
			last_attack = "attack2"
		elif last_attack == "attack2":
			animated_sprite.play("attack1")
			last_attack = "attack1"
	
	# Impulso al atacar (mantiene momentum)
	var attack_impulse = 150.0
	if animated_sprite and animated_sprite.flip_h:
		velocity.x = -attack_impulse
	else:
		velocity.x = attack_impulse

func end_attack() -> void:
	is_attacking = false
	cooldown_timer = attack_cooldown
	
	# Desactivar hitbox
	if attack_collision:
		attack_collision.disabled = true

func _on_animation_finished() -> void:
	if animated_sprite and animated_sprite.animation == "attack":
		# No hacer end_attack aquí, dejar que el timer lo maneje
		pass

func _on_attack_hit(body: Node2D) -> void:
	# Evitar golpear al mismo enemigo varias veces
	if body == self:
		return
		
	if body in enemies_hit_this_attack:
		return
	
	enemies_hit_this_attack.append(body)
	
	if body.has_method("take_damage"):
		# HITSTOP
		apply_hitstop(0.05)
		
		# CAMERA SHAKE
		add_camera_shake(8.0)
		
		# COMBO
		combo_count += 1
		combo_timer = combo_window
		
		# Calcular daño con multiplicador de combo
		var combo_multiplier = 1.0 + (combo_count * 0.2)
		var total_damage = int(attack_damage * combo_multiplier)
		
		# APLICAR DAÑO (sin knockback)
		body.take_damage(total_damage)
		
		# FEEDBACK
		print("💥 GOLPE! Combo x", combo_count, " | Daño: ", total_damage)

func apply_hitstop(duration: float) -> void:
	hitstop_timer = duration
	# Opcional: hacer que todo se congele
	Engine.time_scale = 0.1
	await get_tree().create_timer(duration, false).timeout
	Engine.time_scale = 1.0

func add_camera_shake(amount: float) -> void:
	camera_shake_amount += amount

func handle_camera_shake(delta: float) -> void:
	if not camera:
		return
	
	if camera_shake_amount > 0:
		# Shake aleatorio
		var shake_offset = Vector2(
			randf_range(-camera_shake_amount, camera_shake_amount),
			randf_range(-camera_shake_amount, camera_shake_amount)
		)
		camera.offset = shake_offset
		
		# Decay
		camera_shake_amount = lerp(camera_shake_amount, 0.0, camera_shake_decay * delta)
	else:
		camera.offset = Vector2.ZERO

func take_damage(damage: int) -> void:
	if is_invulnerable:
		return
	
	current_health -= damage
	is_invulnerable = true
	invulnerability_timer = invulnerability_time
	
	# Camera shake al recibir daño
	add_camera_shake(12.0)
	
	# Resetear combo
	combo_count = 0
	combo_timer = 0.0
	
	print("🩸 Daño recibido! Vida: ", current_health, "/", max_health)
	
	if current_health <= 0:
		die()
		
func die() -> void:
	print("☠️ MUERTE!")
	# Reiniciar escena o game over
	get_tree().reload_current_scene()

func update_animations() -> void:
	if not animated_sprite:
		return
	
	# Ataque tiene prioridad PERO permite cambios rápidos
	if is_attacking and animated_sprite.animation != "attack":
		return
	
	# Flip basado en la velocidad
	if velocity.x > 10:
		animated_sprite.flip_h = false
	elif velocity.x < -10:
		animated_sprite.flip_h = true
	
	# No cambiar animación durante ataque
	if is_attacking:
		return
	
	# Seleccionar animación
	if is_on_floor():
		if abs(velocity.x) > 560:
			if animated_sprite.animation != "run":
				animated_sprite.play("run")
		elif abs(velocity.x) <= 560 and abs(velocity.x) > 0 :
			if animated_sprite.animation != "walk":
				animated_sprite.play("walk")
		else:
			if animated_sprite.animation != "idle1":
				animated_sprite.play("idle1")
	#else:
		#if is_wall_sliding:
			#if animated_sprite.animation != "wall_slide":
				#animated_sprite.play("wall_slide")
		#elif is_wall_running:
			#if animated_sprite.animation != "wall_run":
				#animated_sprite.play("wall_run")
		#elif velocity.y < 0:
			#if animated_sprite.animation != "jump":
				#animated_sprite.play("jump")
		#else:
			#if animated_sprite.animation != "fall":
				#animated_sprite.play("fall")

# ... (resto de funciones handle_gravity, handle_movement, etc. igual que antes)

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
