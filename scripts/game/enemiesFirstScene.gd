extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_interval = 2.0
@export var max_enemies = 10
@export var spawn_radius = 500.0
@export var min_spawn_distance = 200.0

var spawn_timer = 0.0
var current_enemies = 0
var player: CharacterBody2D = null

func _ready():
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	
	print("=== DEBUG SPAWN ===")
	print("Player encontrado: ", player != null)
	print("Enemy scene asignada: ", enemy_scene != null)
	
	if not player:
		push_error("⚠️ NO SE ENCONTRÓ AL JUGADOR - Agregar grupo 'player'")
	
	if not enemy_scene:
		push_error("⚠️ NO HAY ESCENA DE ENEMIGO - Asignar en el Inspector")

func _process(delta: float) -> void:
	if not enemy_scene or not player:
		return
	
	spawn_timer += delta
	
	if spawn_timer >= spawn_interval and current_enemies < max_enemies:
		spawn_enemy()
		spawn_timer = 0.0

func spawn_enemy() -> void:
	var max_attempts = 10
	var attempt = 0
	var valid_position = false
	var spawn_pos = Vector2.ZERO
	
	while not valid_position and attempt < max_attempts:
		var angle = randf() * TAU
		var distance = randf_range(min_spawn_distance, spawn_radius)
		spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * distance
		
		# Raycast hacia abajo para verificar que hay suelo
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(
			spawn_pos,
			spawn_pos + Vector2(0, 1000)  # 1000 pixeles hacia abajo
		)
		
		var result = space_state.intersect_ray(query)
		
		if result:
			# Hay suelo, spawnear encima
			spawn_pos = result.position + Vector2(0, -50)  # 50px arriba del suelo
			valid_position = true
		
		attempt += 1
	
	if not valid_position:
		print("⚠️ No se pudo encontrar posición válida para spawn")
		return
	
	var enemy = enemy_scene.instantiate()
	enemy.global_position = spawn_pos
	
	var enemies_node = get_node_or_null("../Enemies")
	if enemies_node:
		enemies_node.add_child(enemy)
	else:
		get_parent().add_child(enemy)
	
	enemy.tree_exited.connect(_on_enemy_died)
	current_enemies += 1

func _on_enemy_died() -> void:
	current_enemies -= 1
	print("💀 Enemigo murió. Quedan: ", current_enemies)
