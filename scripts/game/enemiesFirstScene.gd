extends Node2D

@export var enemy_scenes: Array[PackedScene] = []  # ARRAY de enemigos
@export var spawn_interval = 2.0
@export var max_enemies = 10
@export var spawn_radius = 400.0
@export var min_spawn_distance = 200.0
@export var max_spawn_attempts = 15
@export var ground_check_distance = 100.0  # Distancia para verificar suelo

var spawn_timer = 0.0
var current_enemies = 0
var player: CharacterBody2D = null

# Sistema de oleadas para el boss
@export var kills_needed_for_boss = 30
var total_kills = 0
var boss_spawned = false

signal boss_should_spawn

func _ready():
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	
	if not player:
		push_error("⚠️ NO SE ENCONTRÓ AL JUGADOR")
	
	if enemy_scenes.is_empty():
		push_error("⚠️ NO HAY ESCENAS DE ENEMIGOS - Asignar en el Inspector")

func _process(delta: float) -> void:
	if boss_spawned:
		return  # No spawnear más enemigos si el boss ya apareció
	
	if enemy_scenes.is_empty() or not player:
		return
	
	spawn_timer += delta
	
	if spawn_timer >= spawn_interval and current_enemies < max_enemies:
		spawn_random_enemy()
		spawn_timer = 0.0

func spawn_random_enemy() -> void:
	var valid_position = false
	var spawn_pos = Vector2.ZERO
	var attempts = 0
	
	while not valid_position and attempts < max_spawn_attempts:
		# Generar posición aleatoria
		var angle = randf() * TAU
		var distance = randf_range(min_spawn_distance, spawn_radius)
		var test_pos = player.global_position + Vector2(cos(angle), sin(angle)) * distance
		
		# SHAPE CAST para verificar que no haya obstáculos
		var space_state = get_world_2d().direct_space_state
		
		# 1. Verificar que no haya nada en la posición de spawn (círculo de 40px)
		var shape = CircleShape2D.new()
		shape.radius = 40.0
		
		var params = PhysicsShapeQueryParameters2D.new()
		params.shape = shape
		params.transform = Transform2D(0, test_pos)
		params.collision_mask = 4  # Solo mundo
		
		var obstacles = space_state.intersect_shape(params)
		
		if obstacles.is_empty():
			# 2. Buscar suelo debajo con raycast
			var ray_query = PhysicsRayQueryParameters2D.create(
				test_pos,
				test_pos + Vector2(0, ground_check_distance)
			)
			ray_query.collision_mask = 4
			
			var ground_result = space_state.intersect_ray(ray_query)
			
			if ground_result:
				spawn_pos = ground_result.position + Vector2(0, -30)
				valid_position = true
		
		attempts += 1
	
	if not valid_position:
		print("⚠️ No se encontró posición válida")
		return
	
	# Elegir enemigo aleatorio
	var random_enemy = enemy_scenes[randi() % enemy_scenes.size()]
	var enemy = random_enemy.instantiate()
	enemy.global_position = spawn_pos
	
	# Conectar señal de muerte
	enemy.tree_exited.connect(_on_enemy_died)
	
	var enemies_node = get_node_or_null("../Enemies")
	if enemies_node:
		enemies_node.add_child(enemy)
	else:
		get_parent().add_child(enemy)
	
	current_enemies += 1
	print("✅ Enemigo spawneado | Total: ", current_enemies)

func _on_enemy_died() -> void:
	current_enemies -= 1
	total_kills += 1
	
	print("💀 Kills: ", total_kills, "/", kills_needed_for_boss)
	
	# Verificar si es momento del boss
	if total_kills >= kills_needed_for_boss and not boss_spawned:
		boss_spawned = true
		spawn_boss()

func spawn_boss() -> void:
	print("🔥 ¡BOSS APARECE!")
	
	# Eliminar todos los enemigos restantes
	var enemies_node = get_node_or_null("../Enemies")
	if enemies_node:
		for enemy in enemies_node.get_children():
			enemy.queue_free()
	
	current_enemies = 0
	
	# Emitir señal para que el boss se active
	boss_should_spawn.emit()
