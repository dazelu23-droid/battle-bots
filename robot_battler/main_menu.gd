extends Control

const STAGE_SELECT_SCENE := "res://robot_battler/stage_select.tscn"

const SELECTED_FONT_COLOR := Color(0.913725, 0.94902, 0.980392)

@onready var play_button: Button = %PlayButton
@onready var main_vbox: VBoxContainer = %VBox
@onready var options_vbox: VBoxContainer = %OptionsVBox
@onready var difficulty_vbox: VBoxContainer = %DifficultyVBox
@onready var controls_vbox: VBoxContainer = %ControlsVBox
@onready var options_difficulty_button: Button = %DifficultyButton
@onready var options_controls_button: Button = %ControlsButton
@onready var controls_back_button: Button = %ControlsBackButton
@onready var mode_buttons := {
	GameSettings.ControlMode.TANK: %TankModeButton,
	GameSettings.ControlMode.MOUSE: %MouseModeButton,
}
@onready var move_val: Label = %MoveVal
@onready var turn_key: Label = %TurnKey
@onready var turn_val: Label = %TurnVal
@onready var difficulty_buttons := {
	GameSettings.Difficulty.EASY: %EasyButton,
	GameSettings.Difficulty.MEDIUM: %MediumButton,
	GameSettings.Difficulty.HARD: %HardButton,
}

var _outline_normal: StyleBox
var _outline_hover: StyleBox
var _outline_font_color: Color


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var reference: Button = difficulty_buttons[GameSettings.Difficulty.EASY]
	_outline_normal = reference.get_theme_stylebox("normal")
	_outline_hover = reference.get_theme_stylebox("hover")
	_outline_font_color = reference.get_theme_color("font_color")
	play_button.grab_focus()


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(STAGE_SELECT_SCENE)


func _on_quit_pressed() -> void:
	get_tree().quit()


func _show_panel(panel: VBoxContainer) -> void:
	main_vbox.visible = panel == main_vbox
	options_vbox.visible = panel == options_vbox
	difficulty_vbox.visible = panel == difficulty_vbox
	controls_vbox.visible = panel == controls_vbox


func _on_options_pressed() -> void:
	_show_panel(options_vbox)
	options_difficulty_button.grab_focus()


func _on_options_back_pressed() -> void:
	_show_panel(main_vbox)
	play_button.grab_focus()


func _on_difficulty_open_pressed() -> void:
	_show_panel(difficulty_vbox)
	_update_difficulty_buttons()
	difficulty_buttons[GameSettings.difficulty].grab_focus()


func _on_back_pressed() -> void:
	_show_panel(options_vbox)
	options_difficulty_button.grab_focus()


func _on_controls_pressed() -> void:
	_show_panel(controls_vbox)
	_update_control_mode_buttons()
	mode_buttons[GameSettings.control_mode].grab_focus()


func _on_tank_mode_pressed() -> void:
	_set_control_mode(GameSettings.ControlMode.TANK)


func _on_mouse_mode_pressed() -> void:
	_set_control_mode(GameSettings.ControlMode.MOUSE)


func _set_control_mode(mode: int) -> void:
	GameSettings.control_mode = mode
	_update_control_mode_buttons()


func _update_control_mode_buttons() -> void:
	for mode in mode_buttons:
		_style_toggle_button(mode_buttons[mode], mode == GameSettings.control_mode)
	if GameSettings.control_mode == GameSettings.ControlMode.MOUSE:
		move_val.text = "W / A / S / D"
		turn_key.text = "Aim"
		turn_val.text = "Mouse"
	else:
		move_val.text = "W / S  or  Up / Down"
		turn_key.text = "Turn"
		turn_val.text = "A / D  or  Left / Right"


func _on_controls_back_pressed() -> void:
	_show_panel(options_vbox)
	options_controls_button.grab_focus()


func _on_easy_pressed() -> void:
	_set_difficulty(GameSettings.Difficulty.EASY)


func _on_medium_pressed() -> void:
	_set_difficulty(GameSettings.Difficulty.MEDIUM)


func _on_hard_pressed() -> void:
	_set_difficulty(GameSettings.Difficulty.HARD)


func _set_difficulty(difficulty: int) -> void:
	GameSettings.difficulty = difficulty
	_update_difficulty_buttons()


func _update_difficulty_buttons() -> void:
	for difficulty in difficulty_buttons:
		_style_toggle_button(difficulty_buttons[difficulty], difficulty == GameSettings.difficulty)


func _style_toggle_button(button: Button, selected: bool) -> void:
	var filled: StyleBox = play_button.get_theme_stylebox("normal")
	var filled_hover: StyleBox = play_button.get_theme_stylebox("hover")
	button.add_theme_stylebox_override("normal", filled if selected else _outline_normal)
	button.add_theme_stylebox_override("hover", filled_hover if selected else _outline_hover)
	button.add_theme_stylebox_override("focus", filled_hover if selected else _outline_hover)
	var font_color := SELECTED_FONT_COLOR if selected else _outline_font_color
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", font_color)
	button.add_theme_color_override("font_focus_color", font_color)
	button.add_theme_color_override("font_pressed_color", font_color)
