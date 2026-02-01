extends Node2D

@export var enemy_scenes: Array[PackedScene] = []  # ARRAY de enemigos
@export var spawn_interval = 2.0
@export var max_enemies = 10

# PUNTOS DE SPAWN PREDEFINIDOS (edítalos desde el Inspector)
@export var spawn_points: Array[Vector2] = []

# Fallback si no hay spawn_points
@export var use_player_radius = true  # Usar radio del jugador si no hay spawn_points
@export var spawn_radius = 400.0
@export var min_spawn_distance = 200.0

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
	
	# Debug info
	if spawn_points.is_empty():
		print("ℹ️ No hay spawn_points definidos. Usando spawn aleatorio alrededor del jugador.")
	else:
		print("✅ Usando ", spawn_points.size(), " puntos de spawn:")
		for i in range(spawn_points.size()):
			print("   Punto ", i, ": ", spawn_points[i])

func _process(delta: float) -> void:
	if boss_spawned:
		return
	
	if enemy_scenes.is_empty() or not player:
		return
	
	spawn_timer += delta
	
	if spawn_timer >= spawn_interval and current_enemies < max_enemies:
		spawn_random_enemy()
		spawn_timer = 0.0

func spawn_random_enemy() -> void:
	var spawn_pos = Vector2.ZERO
	
	# MÉTODO 1: Si hay spawn_points definidos, usar uno directamente
	if not spawn_points.is_empty():
		# Elegir un spawn point aleatorio
		var random_point = spawn_points[randi() % spawn_points.size()]
		spawn_pos = random_point
		print("📍 Usando spawn point: ", spawn_pos)
	
	# MÉTODO 2: Si no hay spawn_points, usar radio alrededor del jugador
	elif use_player_radius and player:
		var angle = randf() * TAU
		var distance = randf_range(min_spawn_distance, spawn_radius)
		spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * distance
		
		# Intentar ajustar al suelo si es posible
		var ground_pos = try_find_ground_below(spawn_pos, 200.0)
		if ground_pos != Vector2.ZERO:
			spawn_pos = ground_pos
		
		print("🎲 Spawn aleatorio en: ", spawn_pos)
	else:
		print("❌ No hay spawn_points ni jugador - no se puede spawnear")
		return
	
	# Crear enemigo
	var random_enemy = enemy_scenes[randi() % enemy_scenes.size()]
	var enemy = random_enemy.instantiate()
	enemy.global_position = spawn_pos
	
	# Conectar señal de muerte
	enemy.tree_exited.connect(_on_enemy_died)
	
	# Añadir a la escena
	var enemies_node = get_node_or_null("../Enemies")
	if enemies_node:
		enemies_node.add_child(enemy)
	else:
		get_parent().add_child(enemy)
	
	current_enemies += 1
	print("✅ Enemigo spawneado en: ", spawn_pos, " | Total: ", current_enemies)

# Función auxiliar para intentar encontrar suelo (OPCIONAL - no bloquea el spawn)
func try_find_ground_below(start_pos: Vector2, max_distance: float) -> Vector2:
	var space_state = get_world_2d().direct_space_state
	
	if not space_state:
		return Vector2.ZERO
	
	# Raycast desde arriba hacia abajo
	var ray_start = start_pos + Vector2(0, -50)
	var ray_end = start_pos + Vector2(0, max_distance)
	
	var ray_query = PhysicsRayQueryParameters2D.create(ray_start, ray_end)
	ray_query.collision_mask = 4  # Capa del mundo/suelo
	
	var result = space_state.intersect_ray(ray_query)
	
	if result:
		# Encontró suelo - posicionar enemigo justo encima
		return result.position + Vector2(0, -30)
	
	# No encontró suelo pero no es crítico
	return Vector2.ZERO

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
