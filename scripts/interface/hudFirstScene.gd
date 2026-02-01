extends CanvasLayer

@onready var combo_label: Label = $ComboLabel
@onready var health_bar: ProgressBar = $HealthBar

var player: CharacterBody2D = null

func _ready():
	player = get_tree().get_first_node_in_group("player")

func _process(_delta: float) -> void:
	if player:
		# Actualizar combo
		if player.combo_count > 0:
			combo_label.text = "COMBO x" + str(player.combo_count)
			combo_label.modulate = Color(1, 1 - player.combo_count * 0.1, 0)  # Más rojo con combo
			combo_label.visible = true
		else:
			combo_label.visible = false
		
		# Actualizar vida
		health_bar.value = (float(player.current_health) / player.max_health) * 100
