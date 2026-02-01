extends StaticBody2D

@export var max_health = 500
@export var projectile_scene: PackedScene
@export var shoot_interval = 2.0
@export var vulnerable_time = 5.0  # Tiempo que baja a recibir golpes
@export var invulnerable_time = 8.0  # Tiempo disparando sin recibir daño

var current_health = max_health
var is_vulnerable = false
var phase_timer = 0.0
var shoot_timer = 0.0
var is_dead = false
var player: CharacterBody2D = null
var is_active = false  # Se activa después de la cinemática

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var spawn_manager = get_node("/root/Main/EnemySpawner")  # Ajusta la ruta

func _ready():
	player = get_tree().get_first_node_in_group("player")
	
	# Conectar a la señal del spawn manager
	if spawn_manager:
		spawn_manager.boss_should_spawn.connect(_on_boss_activate)
	
	visible = false
	set_physics_process(false)

func _on_boss_activate() -> void:
	visible = true
	play_intro_cinematic()

func play_intro_cinematic() -> void:
	print("🎬 Cinemática del boss")
	
	# Obtener cámara del jugador
	if player and player.has_node("Camera2D"):
		var camera = player.get_node("Camera2D")
		var original_pos = camera.global_position
		
		# Mover cámara hacia el boss
		var tween = create_tween()
		tween.tween_property(camera, "global_position", global_position, 1.5).set_ease(Tween.EASE_IN_OUT)
		tween.tween_interval(2.0)  # Pausa dramática
		tween.tween_property(camera, "global_position", original_pos, 1.0)
		
		await tween.finished
	else:
		await get_tree().create_timer(3.0).timeout
	
	# Activar boss
	is_active = true
	set_physics_process(true)
	enter_invulnerable_phase()

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
	
	if animated_sprite:
		animated_sprite.play("invulnerable")  # Animación flotando/disparando
	
	print("🛡️ Boss INVULNERABLE - disparando")

func enter_vulnerable_phase() -> void:
	is_vulnerable = true
	phase_timer = vulnerable_time
	
	if animated_sprite:
		animated_sprite.play("vulnerable")  # Animación bajando/expuesto
	
	print("⚔️ Boss VULNERABLE - ¡ataca ahora!")

func shoot_projectile() -> void:
	if not projectile_scene or not player:
		return
	
	var projectile = projectile_scene.instantiate()
	projectile.global_position = global_position
	
	# Dirección hacia donde está el jugador AHORA
	var direction = (player.global_position - global_position).normalized()
	projectile.direction = direction
	
	get_parent().add_child(projectile)
	
	print("💥 Boss dispara proyectil")

func take_damage(damage: int) -> void:
	if not is_vulnerable or is_dead:
		print("🛡️ Boss es invulnerable!")
		return
	
	current_health -= damage
	
	# Flash
	if animated_sprite:
		animated_sprite.modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		if animated_sprite:
			animated_sprite.modulate = Color.WHITE
	
	print("👾 Boss recibió ", damage, " de daño. Vida: ", current_health, "/", max_health)
	
	if current_health <= 0:
		die()

func die() -> void:
	is_dead = true
	print("💀 ¡BOSS DERROTADO!")
	
	# Animación de muerte
	if animated_sprite and animated_sprite.has_animation("death"):
		animated_sprite.play("death")
		await animated_sprite.animation_finished
	
	# Activar puerta
	activate_exit_door()
	
	queue_free()

func activate_exit_door() -> void:
	# Buscar la puerta en la escena
	var door = get_tree().get_first_node_in_group("exit_door")
	if door and door.has_method("activate"):
		door.activate()
