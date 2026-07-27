extends Control

const STAGE_SELECT_SCENE := "res://robot_battler/stage_select.tscn"

const SELECTED_FONT_COLOR := Color(0.913725, 0.94902, 0.980392)

@onready var play_button: Button = %PlayButton
@onready var main_vbox: VBoxContainer = %VBox
@onready var options_vbox: VBoxContainer = %OptionsVBox
@onready var difficulty_buttons := {
	GameSettings.Difficulty.EASY: %EasyButton,
	GameSettings.Difficulty.MEDIUM: %MediumButton,
	GameSettings.Difficulty.HARD: %HardButton,
}

var _outline_normal: StyleBox
var _outline_hover: StyleBox
var _outline_font_color: Color


func _ready() -> void:
	var reference: Button = difficulty_buttons[GameSettings.Difficulty.EASY]
	_outline_normal = reference.get_theme_stylebox("normal")
	_outline_hover = reference.get_theme_stylebox("hover")
	_outline_font_color = reference.get_theme_color("font_color")
	play_button.grab_focus()


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(STAGE_SELECT_SCENE)


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_options_pressed() -> void:
	main_vbox.visible = false
	options_vbox.visible = true
	_update_difficulty_buttons()
	difficulty_buttons[GameSettings.difficulty].grab_focus()


func _on_back_pressed() -> void:
	options_vbox.visible = false
	main_vbox.visible = true
	play_button.grab_focus()


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
	var filled: StyleBox = play_button.get_theme_stylebox("normal")
	var filled_hover: StyleBox = play_button.get_theme_stylebox("hover")
	for difficulty in difficulty_buttons:
		var button: Button = difficulty_buttons[difficulty]
		var selected: bool = difficulty == GameSettings.difficulty
		button.add_theme_stylebox_override("normal", filled if selected else _outline_normal)
		button.add_theme_stylebox_override("hover", filled_hover if selected else _outline_hover)
		button.add_theme_stylebox_override("focus", filled_hover if selected else _outline_hover)
		var font_color := SELECTED_FONT_COLOR if selected else _outline_font_color
		button.add_theme_color_override("font_color", font_color)
		button.add_theme_color_override("font_hover_color", font_color)
		button.add_theme_color_override("font_focus_color", font_color)
		button.add_theme_color_override("font_pressed_color", font_color)
