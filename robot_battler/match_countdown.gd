extends CanvasLayer

static var active := false

@onready var count_label: Label = %CountLabel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run_countdown()


func _run_countdown() -> void:
	active = true
	get_tree().paused = true
	for step in ["3", "2", "1"]:
		count_label.text = step
		await get_tree().create_timer(1.0).timeout
	count_label.text = "FIGHT!"
	get_tree().paused = false
	active = false
	await get_tree().create_timer(0.7).timeout
	queue_free()
