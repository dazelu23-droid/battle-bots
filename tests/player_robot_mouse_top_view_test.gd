extends Node


func _ready() -> void:
	GameSettings.control_mode = GameSettings.ControlMode.MOUSE
	var player := preload("res://robot_battler/player_robot.tscn").instantiate()
	add_child(player)
	await get_tree().process_frame

	player.toggle_view()

	if not player._should_capture_mouse():
		push_error("Mouse mode must stay captured while mouse controls use top view.")
		get_tree().quit(1)
		return

	var starting_yaw: float = player.rotation.y
	player._apply_mouse_turn(24.0)
	if is_equal_approx(player.rotation.y, starting_yaw):
		push_error("Horizontal mouse motion must turn the player in top view.")
		get_tree().quit(1)
		return

	player.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)
