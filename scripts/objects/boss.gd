extends StaticBody2D

@export var max_health = 2000
@export var projectile_scene: PackedScene
@export var shoot_interval = 1.5
@export var vulnerable_time = 6
@export var invulnerable_time = 10

var current_health = max_health
var is_vulnerable = false
var phase_timer = 0.0
var shoot_timer = 0.0
var is_dead = false
var player: CharacterBody2D = null
var is_active = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit_area: Area2D = $HitArea
@onready var projectile_spawn: Marker2D = $ProjectileSpawnPoint
@onready var spawn_manager = get_tree().root.find_child("EnemiesFirstScene", true, false)

func _ready():
	# Agregar al grupo boss
	add_to_group("boss")
	
	player = get_tree().get_first_node_in_group("player")
	
	# Conectar señal del spawn manager
	if spawn_manager:
		spawn_manager.boss_should_spawn.connect(_on_boss_activate)
	
	# Ocultar y desactivar al inicio
	visible = false
	set_physics_process(false)
	
	# Desactivar colisión al inicio
	collision_layer = 0
	collision_mask = 0
	
	# Desactivar hit area
	if hit_area:
		hit_area.collision_layer = 0
		hit_area.collision_mask = 0
	
	if hit_area:
		hit_area.area_entered.connect(_on_hit_area_entered)

func _on_hit_area_entered(area: Area2D) -> void:
	# Detectar si es el ataque del jugador
	if area.name == "AttackHitbox" or area.is_in_group("player_attack"):
		var player_node = area.get_parent()
		if player_node and player_node.is_in_group("player"):
			# Calcular daño basado en el ataque del jugador
			var damage = 25  # O puedes obtenerlo del jugador
			take_damage(damage)
			
func _on_boss_activate() -> void:
	print("🔥 Boss activándose...")
	visible = true
	play_intro_cinematic()

func play_intro_cinematic() -> void:
	print("🎬 Cinemática del boss")
	
	# Congelar al jugador
	if player:
		player.set_physics_process(false)
	
	# Obtener cámara del jugador
	if player and player.has_node("Camera2D"):
		var camera = player.get_node("Camera2D")
		var original_pos = camera.position
		
		# Guardar posición original
		var player_camera_offset = camera.position
		
		# Calcular posición para enfocar al boss
		var boss_screen_pos = global_position - player.global_position
		
		# Mover cámara hacia el boss
		var tween = create_tween()
		tween.tween_property(camera, "offset", boss_screen_pos, 1.5).set_ease(Tween.EASE_IN_OUT)
		tween.tween_interval(2.0)  # Pausa dramática
		tween.tween_property(camera, "offset", Vector2.ZERO, 1.0)
		
		await tween.finished
		
		# Descongelar jugador
		if player:
			player.set_physics_process(true)
	else:
		await get_tree().create_timer(3.0).timeout
		if player:
			player.set_physics_process(true)
	
	# Activar boss
	activate_boss()

func activate_boss():
	is_active = true
	set_physics_process(true)
	
	# Activar colisiones
	collision_layer = 32  # Layer 6 (Boss)
	collision_mask = 0
	
	# Activar hit area para recibir golpes
	if hit_area:
		hit_area.collision_layer = 32  # Layer 6
		hit_area.collision_mask = 0
	
	enter_invulnerable_phase()
	print("⚔️ Boss activado y listo para pelear")

func _physics_process(delta: float) -> void:
	if is_dead or not is_active:
		return
	
	# Timer de fase
	phase_timer -= delta
	
	if phase_timer <= 0:
		if is_vulnerable:
			enter_invulnerable_phase()
		else:
			enter_vulnerable_phase()
	
	# Disparar proyectiles si está en fase invulnerable
	if not is_vulnerable:
		shoot_timer -= delta
		if shoot_timer <= 0:
			shoot_projectile()
			shoot_timer = shoot_interval

func enter_invulnerable_phase() -> void:
	is_vulnerable = false
	phase_timer = invulnerable_time
	shoot_timer = shoot_interval
	
	if animated_sprite:
		if animated_sprite.sprite_frames.has_animation("attack"):
			animated_sprite.play("attack")
		else:
			animated_sprite.play("idle")
	
	# Visual de invulnerabilidad
	if animated_sprite:
		animated_sprite.modulate = Color(0.5, 0.5, 0.5, 1.0)
	
	print("🛡️ Boss INVULNERABLE - disparando")

func enter_vulnerable_phase() -> void:
	is_vulnerable = true
	phase_timer = vulnerable_time
	
	if animated_sprite:
		if animated_sprite.sprite_frames.has_animation("idle"):
			animated_sprite.play("idle")
	
	# Visual de vulnerabilidad
	if animated_sprite:
		animated_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	print("⚔️ Boss VULNERABLE - ¡ataca ahora!")

func shoot_projectile() -> void:
	if not projectile_scene or not player or not is_active:
		return
	
	var projectile = projectile_scene.instantiate()
	
	# Posición de spawn
	if projectile_spawn:
		projectile.global_position = projectile_spawn.global_position
	else:
		projectile.global_position = global_position
	
	# Dirección hacia el jugador
	var direction = (player.global_position - projectile.global_position).normalized()
	projectile.direction = direction
	
	get_parent().add_child(projectile)
	
	print("💥 Boss dispara proyectil hacia jugador")

func take_damage(damage: int) -> void:
	if not is_vulnerable or is_dead or not is_active:
		if not is_dead and is_active:
			print("🛡️ Boss es invulnerable!")
		return
	
	current_health -= damage
	
	# Flash
	if animated_sprite:
		animated_sprite.modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		if animated_sprite and is_vulnerable:
			animated_sprite.modulate = Color.WHITE
	
	print("👾 Boss recibió ", damage, " de daño. Vida: ", current_health, "/", max_health)
	
	if current_health <= 0:
		die()

func die() -> void:
	is_dead = true
	is_active = false
	print("💀 ¡BOSS DERROTADO!")
	
	# Desactivar colisiones
	collision_layer = 0
	if hit_area:
		hit_area.collision_layer = 0
	
	# Animación de muerte
	if animated_sprite:
		if animated_sprite.sprite_frames.has_animation("death"):
			animated_sprite.play("death")
			await animated_sprite.animation_finished
		else:
			# Fade out
			var tween = create_tween()
			tween.tween_property(animated_sprite, "modulate:a", 0.0, 1.0)
			await tween.finished
	
	# Activar puerta
	activate_exit_door()
	
	queue_free()

func activate_exit_door() -> void:
	var door = get_tree().get_first_node_in_group("exit_door")
	if door and door.has_method("activate"):
		door.activate()
		print("🚪 Puerta de salida activada")
