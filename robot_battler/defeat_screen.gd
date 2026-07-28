extends CanvasLayer

const STAGE_SELECT_SCENE := "res://robot_battler/stage_select.tscn"

static var active := false

@onready var time_value: Label = %TimeValue
@onready var accuracy_value: Label = %AccuracyValue
@onready var try_again_button: Button = %TryAgainButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func show_defeat(elapsed: float, shots_fired: int, shots_hit: int) -> void:
	active = true
	get_tree().paused = true
	visible = true
	var minutes := int(elapsed) / 60
	var seconds := fmod(elapsed, 60.0)
	time_value.text = "%d:%04.1f" % [minutes, seconds]
	if shots_fired > 0:
		var percent := roundi(100.0 * shots_hit / shots_fired)
		accuracy_value.text = "%d%%  (%d of %d shots)" % [percent, shots_hit, shots_fired]
	else:
		accuracy_value.text = "No shots fired"
	try_again_button.grab_focus()


func _on_try_again_pressed() -> void:
	active = false
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_leave_pressed() -> void:
	active = false
	get_tree().paused = false
	get_tree().change_scene_to_file(STAGE_SELECT_SCENE)
