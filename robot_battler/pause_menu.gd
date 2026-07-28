extends CanvasLayer

const MAIN_MENU_SCENE := "res://robot_battler/main_menu.tscn"
const MatchCountdown := preload("res://robot_battler/match_countdown.gd")
const DefeatScreen := preload("res://robot_battler/defeat_screen.gd")
const VictoryScreen := preload("res://robot_battler/victory_screen.gd")

@onready var resume_button: Button = %ResumeButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if MatchCountdown.active or DefeatScreen.active or VictoryScreen.active:
			return
		_toggle_pause()
		get_viewport().set_input_as_handled()


func _toggle_pause() -> void:
	var paused := not get_tree().paused
	get_tree().paused = paused
	visible = paused
	if paused:
		resume_button.grab_focus()


func _on_resume_pressed() -> void:
	_toggle_pause()


func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
