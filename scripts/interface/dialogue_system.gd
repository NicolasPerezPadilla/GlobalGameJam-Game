extends CanvasLayer

@onready var dialogue_box = $DialogueBox
@onready var dialogue_label = $DialogueBox/DialogueLabel

var dialogues = [
	"FINISH THEM ALL...",
	"DON´T LET THEM RUN.",
	"NOW!"
]

var current_dialogue = 0
var dialogue_time = 2.5
var is_showing = false

signal dialogues_finished

func _ready():
	visible = false

func show_dialogues():
	visible = true
	is_showing = true
	show_next_dialogue()

func show_next_dialogue():
	if current_dialogue >= dialogues.size():
		finish_dialogues()
		return
	
	dialogue_label.text = dialogues[current_dialogue]
	
	# Fade in
	dialogue_box.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(dialogue_box, "modulate:a", 1.0, 0.5)
	tween.tween_interval(dialogue_time)
	tween.tween_property(dialogue_box, "modulate:a", 0.0, 0.5)
	
	await tween.finished
	
	current_dialogue += 1
	show_next_dialogue()

func finish_dialogues():
	is_showing = false
	dialogues_finished.emit()
	visible = false
