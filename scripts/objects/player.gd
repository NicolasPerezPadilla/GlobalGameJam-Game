extends CharacterBody2D

# ─── AUDIO ──────────────────────────────────────────────────────
@export var hit_sfx_path: String = "res://audio/sfx/punch.ogg"

# Velocidades y aceleración
var SPEED = 600
var MAX_RUN_SPEED = 1000
var ACCELERATION = 2800.0
var AIR_ACCELERATION = 2200.0
var FRICTION = 2200.0
var AIR_RESISTANCE = 1000.0

# Salto
var JUMP_STRENGTH = -1020.0
var coyote_time = 0.15
var coyote_timer = 0.0
var jump_buffer_time = 0.1
var jump_buffer_timer = 0.0

# Estados básicos
var was_running_on_ground = false

# Momentum boost
var momentum_multiplier = 1.0
var MAX_MOMENTUM = 1.5

# SISTEMA DE ATAQUE MEJORADO CON COMBOS
var is_attacking = false
var current_attack = 0  # 0 = ninguno, 1 = attack1, 2 = kick, 3 = attack2
var combo_window = 0.5  # Tiempo para continuar combo
var combo_timer = 0.0
var can_combo = false  # Se activa cuando puedes encadenar el siguiente golpe

# Duraciones de cada ataque
var attack1_duration = 0.3
var kick_duration = 0.35
var attack2_duration = 0.4

var attack_timer = 0.0
var attack_damage_base = 25
var attack_cooldown = 0.1
var cooldown_timer = 0.0

# Ataque aéreo
var air_attack_slam_force = 800.0  # Fuerza de caída al atacar en aire
var is_air_attacking = false

# HITSTOP (freeze frame)
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

# IDLE ANIMATIONS
var idle_timer = 0.0
var idle_variation_time = 5.0  # Cada 5 segundos puede hacer idle2
var can_do_idle2 = false
var is_meoing = false
var meo_triggered = false

# Referencias
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var attack_collision: CollisionShape2D = $AttackHitbox/CollisionShape2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D

var original_camera_position: Vector2
var enemies_hit_this_attack = []

# Combo tracking
var total_combo_count = 0
var combo_reset_timer = 0.0
var combo_reset_time = 1.5

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
	# HITSTOP
	if hitstop_timer > 0:
		hitstop_timer -= delta
		return
	
	# Timers
	if coyote_timer > 0:
		coyote_timer -= delta
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta
	if cooldown_timer > 0:
		cooldown_timer -= delta
	if combo_timer > 0:
		combo_timer -= delta
	if combo_reset_timer > 0:
		combo_reset_timer -= delta
	else:
		total_combo_count = 0
	
	if invulnerability_timer > 0:
		invulnerability_timer -= delta
		if animated_sprite:
			animated_sprite.modulate.a = 0.5 if int(invulnerability_timer * 20) % 2 == 0 else 1.0
	else:
		is_invulnerable = false
		if animated_sprite:
			animated_sprite.modulate.a = 1.0
	
	# Idle timer para variaciones
	if is_on_floor() and abs(velocity.x) < 10 and not is_attacking:
		idle_timer += delta
		if idle_timer >= idle_variation_time:
			can_do_idle2 = true
	else:
		idle_timer = 0.0
		can_do_idle2 = false
	
	var was_on_floor = is_on_floor()
	
	# Gravedad
	handle_gravity(delta)
	
	handle_meo_input()
	
	# Si está haciendo MEO, no procesar otros inputs
	if is_meoing:
		velocity.x = 0
		move_and_slide()
		return
		
	# Ataque aéreo - caída rápida
	if is_air_attacking and not is_on_floor():
		velocity.y += air_attack_slam_force * delta
	
	# Manejar ataque
	handle_attack(delta)
	
	# Movimiento
	handle_movement(delta)
	
	# Salto
	handle_jump()
	
	# Actualizar animaciones
	update_animations()
	
	# Camera shake
	handle_camera_shake(delta)
	
	# Coyote time
	if was_on_floor and not is_on_floor() and velocity.y >= 0:
		coyote_timer = coyote_time
	
	# Calcular momentum
	if is_on_floor():
		var speed_ratio = abs(velocity.x) / MAX_RUN_SPEED
		momentum_multiplier = lerpf(1.0, MAX_MOMENTUM, speed_ratio)
		was_running_on_ground = Input.is_action_pressed("RUN")
		
		if is_air_attacking:
			is_air_attacking = false
	
	move_and_slide()

func handle_gravity(delta: float) -> void:
	if is_on_floor():
		return
	
	if velocity.y > 0:
		velocity += get_gravity() * delta * 1.2
	else:
		velocity += get_gravity() * delta

func handle_attack(delta: float) -> void:
	if Input.is_action_just_pressed("ATTACK") and cooldown_timer <= 0:
		if is_on_floor():
			if not is_attacking:
				start_ground_attack(1)
			elif can_combo and current_attack < 3:
				start_ground_attack(current_attack + 1)
		else:
			if not is_attacking:
				start_air_attack()
	
	if is_attacking:
		attack_timer -= delta
		
		var attack_duration = get_current_attack_duration()
		if attack_timer <= attack_duration * 0.4 and not can_combo:
			can_combo = true
		
		if attack_timer <= 0:
			end_attack()

func get_current_attack_duration() -> float:
	match current_attack:
		1: return attack1_duration
		2: return kick_duration
		3: return attack2_duration
		_: return 0.3

func start_ground_attack(attack_number: int) -> void:
	if is_attacking and not can_combo:
		return
	
	if not is_attacking:
		enemies_hit_this_attack.clear()
	
	is_attacking = true
	current_attack = attack_number
	can_combo = false
	combo_timer = combo_window
	
	attack_timer = get_current_attack_duration()
	
	if attack_collision:
		attack_collision.disabled = false
	
	if animated_sprite:
		match attack_number:
			1:
				animated_sprite.play("attack1")
			2:
				animated_sprite.play("kick")
			3:
				animated_sprite.play("attack2")
	
	var impulse = 100.0
	if attack_number == 3:
		impulse = 150.0
	
	if animated_sprite:
		if animated_sprite.flip_h:
			velocity.x = -impulse
		else:
			velocity.x = impulse

func start_air_attack() -> void:
	is_attacking = true
	is_air_attacking = true
	current_attack = 3
	attack_timer = attack2_duration * 0.7
	enemies_hit_this_attack.clear()
	
	if attack_collision:
		attack_collision.disabled = false
	
	if animated_sprite:
		animated_sprite.play("attack2")
	
	velocity.y = 200

func end_attack() -> void:
	is_attacking = false
	can_combo = false
	
	if combo_timer <= 0:
		current_attack = 0
	
	cooldown_timer = attack_cooldown
	
	if attack_collision:
		attack_collision.disabled = true

func _on_animation_finished() -> void:
	if animated_sprite:
		if animated_sprite.animation == "idle2":
			animated_sprite.play("idle1")
			can_do_idle2 = false
			idle_timer = 0.0

func _on_attack_hit(body: Node2D) -> void:
	if body == self:
		return
	
	if body in enemies_hit_this_attack:
		return
	
	enemies_hit_this_attack.append(body)
	
	if body.has_method("take_damage"):
		var hit_power = 1.0
		var shake_amount = 8.0
		var hitstop_time = 0.05
		
		if current_attack == 3:
			hit_power = 2.0
			shake_amount = 20.0
			hitstop_time = 0.1
		
		# HITSTOP
		apply_hitstop(hitstop_time)
		
		# CAMERA SHAKE
		add_camera_shake(shake_amount)
		
		# ── AUDIO: SFX de golpe al conectar ──
		AudioManager.play_sfx(hit_sfx_path)
		
		# COMBO
		total_combo_count += 1
		combo_reset_timer = combo_reset_time
		
		# Calcular daño
		var combo_multiplier = 1.0 + (total_combo_count * 0.2)
		var total_damage = int(attack_damage_base * hit_power * combo_multiplier)
		
		# APLICAR DAÑO
		body.take_damage(total_damage)

		# KNOCKBACK especial para attack2
		if current_attack == 3:
			if body.has_method("apply_knockback"):
				var knockback_dir = (body.global_position - global_position).normalized()
				knockback_dir.y = -0.5
				body.apply_knockback(knockback_dir * 600)
		
		print("💥 GOLPE! Ataque: ", current_attack, " | Combo total: x", total_combo_count, " | Daño: ", total_damage)

func apply_hitstop(duration: float) -> void:
	hitstop_timer = duration
	Engine.time_scale = 0.1
	await get_tree().create_timer(duration, false).timeout
	Engine.time_scale = 1.0

func add_camera_shake(amount: float) -> void:
	camera_shake_amount += amount

func handle_camera_shake(delta: float) -> void:
	if not camera:
		return
	
	if camera_shake_amount > 0:
		var shake_offset = Vector2(
			randf_range(-camera_shake_amount, camera_shake_amount),
			randf_range(-camera_shake_amount, camera_shake_amount)
		)
		camera.offset = shake_offset
		camera_shake_amount = lerp(camera_shake_amount, 0.0, camera_shake_decay * delta)
	else:
		camera.offset = Vector2.ZERO

func take_damage(damage: int) -> void:
	if is_invulnerable:
		return
		
	if is_meoing:
		cancel_meo()
	
	current_health -= damage
	is_invulnerable = true
	invulnerability_timer = invulnerability_time
	
	add_camera_shake(12.0)
	
	total_combo_count = 0
	combo_reset_timer = 0.0
	
	animated_sprite.play("hit")
	
	print("🩸 Daño recibido! Vida: ", current_health, "/", max_health)
	
	if current_health <= 0:
		die()

func die() -> void:
	print("☠️ MUERTE!")
	get_tree().reload_current_scene()

func update_animations() -> void:
	if not animated_sprite:
		return
	
	if is_meoing:
		if animated_sprite.animation != "meo":
			animated_sprite.play("meo")
		return
		
	if is_attacking:
		return
	
	if animated_sprite.animation == "hit":
		if not animated_sprite.is_playing():
			pass
		else:
			return
	
	if velocity.x > 10:
		animated_sprite.flip_h = false
	elif velocity.x < -10:
		animated_sprite.flip_h = true
	
	if is_on_floor():
		if abs(velocity.x) > 10:
			if Input.is_action_pressed("RUN"):
				if animated_sprite.animation != "run":
					animated_sprite.play("run")
			else:
				if animated_sprite.animation != "walk":
					animated_sprite.play("walk")
		else:
			if can_do_idle2 and animated_sprite.animation != "idle2":
				animated_sprite.play("idle2")
			elif animated_sprite.animation != "idle1" and animated_sprite.animation != "idle2":
				animated_sprite.play("idle1")
	else:
		if velocity.y < 0:
			if animated_sprite.animation != "jump":
				animated_sprite.play("jump")
		else:
			if animated_sprite.animation != "fall":
				animated_sprite.play("fall")

func handle_movement(delta: float) -> void:
	var direction := Input.get_axis("LEFT", "RIGHT")
	var target_speed = SPEED
	
	var can_run = Input.is_action_pressed("RUN")
	if not is_on_floor():
		if can_run and not was_running_on_ground:
			can_run = false
	
	if can_run:
		target_speed = MAX_RUN_SPEED * momentum_multiplier
	
	if direction != 0:
		var accel = ACCELERATION if is_on_floor() else AIR_ACCELERATION
		velocity.x = move_toward(velocity.x, direction * target_speed, accel * delta)
	else:
		var friction = FRICTION if is_on_floor() else AIR_RESISTANCE
		velocity.x = move_toward(velocity.x, 0, friction * delta)

func handle_jump() -> void:
	if Input.is_action_just_pressed("JUMP"):
		jump_buffer_timer = jump_buffer_time
	
	if jump_buffer_timer > 0 and (is_on_floor() or coyote_timer > 0):
		velocity.y = JUMP_STRENGTH
		jump_buffer_timer = 0
		coyote_timer = 0
		if abs(velocity.x) > MAX_RUN_SPEED * 0.9:
			velocity.x *= 1.05
		return

func handle_meo_input():
	if Input.is_action_just_pressed("MEO") and is_on_floor() and abs(velocity.x) < 10 and not is_attacking and not is_meoing:
		start_meo()
	
	if is_meoing:
		if Input.is_action_pressed("LEFT") or Input.is_action_pressed("RIGHT") or \
		   Input.is_action_pressed("JUMP") or Input.is_action_pressed("ATTACK") or \
		   Input.is_action_pressed("RUN"):
			cancel_meo()

func start_meo():
	is_meoing = true
	meo_triggered = true
	
	if animated_sprite:
		animated_sprite.play("meo")
	
	print("💧 MEO!")

func cancel_meo():
	is_meoing = false
	meo_triggered = false
	
	print("❌ MEO cancelado")
