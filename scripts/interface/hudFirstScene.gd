extends CanvasLayer

# Referencias
@onready var combo_container = $ComboContainer
@onready var combo_label = $ComboContainer/ComboLabel
@onready var combo_multiplier = $ComboContainer/ComboMultiplier

@onready var health_container = $HealthContainer
@onready var health_bar = $HealthContainer/HealthBar

@onready var kills_container = $KillsContainer
@onready var kills_label = $KillsContainer/KillsLabel

var player: CharacterBody2D = null
var spawn_manager: Node = null

# Animación del combo
var combo_shake_amount = 0.0

func _ready():
	# Buscar referencias
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	spawn_manager = get_tree().get_first_node_in_group("spawn")
	
	if not player:
		push_error("⚠️ No se encontró el jugador")
	else:
		print("✅ HUD: Jugador encontrado")
	
	if not spawn_manager:
		push_warning("⚠️ No se encontró el spawn manager en /root/Main/EnemySpawner")
	else:
		print("✅ HUD: Spawn manager encontrado")
	
	# Verificar nodos del combo
	if combo_container:
		print("✅ HUD: ComboContainer existe")
		combo_container.modulate.a = 0
		
		# Animación de pulsación
		var tween = create_tween().set_loops()
		tween.tween_property(combo_container, "scale", Vector2(1.05, 1.05), 1.0).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(combo_container, "scale", Vector2(1.0, 1.0), 1.0).set_ease(Tween.EASE_IN_OUT)
	else:
		push_error("❌ HUD: No se encontró ComboContainer")
	
	if not combo_label:
		push_error("❌ HUD: No se encontró ComboLabel")
	
	if not combo_multiplier:
		push_error("❌ HUD: No se encontró ComboMultiplier")

func _process(delta: float) -> void:
	if player:
		update_combo()
		update_health()
	
	if spawn_manager:
		update_kills()
	
	# Shake del combo
	if combo_shake_amount > 0 and combo_container:
		combo_container.rotation = randf_range(-combo_shake_amount, combo_shake_amount)
		combo_shake_amount = lerp(combo_shake_amount, 0.0, 10.0 * delta)
	elif combo_container:
		combo_container.rotation = 0

func update_combo():
	if not combo_container or not combo_label or not combo_multiplier:
		return
	
	# Verificar que el player tiene la variable
	if not "total_combo_count" in player:
		push_error("❌ El jugador no tiene la variable 'total_combo_count'")
		return
	
	var combo = player.total_combo_count
	
	if combo > 0:
		# Mostrar combo
		if combo_container.modulate.a < 1.0:
			var tween = create_tween()
			tween.tween_property(combo_container, "modulate:a", 1.0, 0.2)
			print("🎯 Mostrando combo: x", combo)
		
		# Actualizar texto
		combo_label.text = "COMBO"
		combo_multiplier.text = "x" + str(combo)
		
		# Color más intenso con más combo
		var combo_color = Color.WHITE.lerp(Color.RED, min(combo / 10.0, 1.0))
		combo_multiplier.add_theme_color_override("font_color", combo_color)
		
		# Efecto de "punch" al aumentar combo
		if combo != get_meta("last_combo", 0):
			var tween = create_tween()
			combo_multiplier.scale = Vector2(1.3, 1.3)
			tween.tween_property(combo_multiplier, "scale", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
			set_meta("last_combo", combo)
			combo_shake_amount = 0.1
	else:
		# Ocultar combo
		if combo_container.modulate.a > 0:
			var tween = create_tween()
			tween.tween_property(combo_container, "modulate:a", 0.0, 0.3)

func update_health():
	if not health_bar:
		return
	
	var health_percent = (float(player.current_health) / player.max_health) * 100
	health_bar.value = health_percent
	
	# Color de la barra según vida
	if health_percent > 60:
		health_bar.modulate = Color.WHITE
	elif health_percent > 30:
		health_bar.modulate = Color.YELLOW
	else:
		health_bar.modulate = Color.RED

func update_kills():
	if not kills_label or not spawn_manager:
		return
	
	kills_label.text = "KILLS:" + str(spawn_manager.total_kills) + "/" + str(spawn_manager.kills_needed_for_boss)
