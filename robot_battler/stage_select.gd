extends Control

const MAIN_MENU_SCENE := "res://robot_battler/main_menu.tscn"
const STAGES := [
	{"id": "harbor", "scene": "res://robot_battler/arena.tscn"},
	{"id": "narrows", "scene": "res://robot_battler/narrows.tscn"},
	{"id": "open_water", "scene": "res://robot_battler/open_water.tscn"},
]

@onready var cards: Array = [%HarborCard, %NarrowsCard, %OpenWaterCard]
@onready var status_labels: Array = [%HarborStatus, %NarrowsStatus, %OpenWaterStatus]
@onready var battle_button: Button = %BattleButton
@onready var lock_label: Label = %LockLabel

var _selected: int = 0
var _style_normal: StyleBoxFlat
var _style_hover: StyleBoxFlat
var _style_selected: StyleBoxFlat
var _style_locked: StyleBoxFlat


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_styles()
	for i in STAGES.size():
		if STAGES[i]["id"] == GameSettings.selected_stage:
			_selected = i
	if _is_locked(_selected):
		_selected = 0
	_update_cards()
	cards[_selected].grab_focus()


func _build_styles() -> void:
	_style_normal = StyleBoxFlat.new()
	_style_normal.bg_color = Color(0.137255, 0.156863, 0.2)
	_style_normal.set_border_width_all(1)
	_style_normal.border_color = Color(0.239216, 0.270588, 0.341176)
	_style_normal.set_corner_radius_all(10)
	_style_hover = _style_normal.duplicate()
	_style_hover.border_color = Color(0.298039, 0.552941, 0.796078)
	_style_selected = _style_normal.duplicate()
	_style_selected.set_border_width_all(2)
	_style_selected.border_color = Color(0.247059, 0.498039, 0.74902)
	_style_locked = _style_normal.duplicate()
	_style_locked.bg_color = Color(0.121569, 0.141176, 0.180392)
	_style_locked.border_color = Color(0.172549, 0.2, 0.25098)


func _is_locked(index: int) -> bool:
	return STAGES[index]["id"] == "open_water" and not GameSettings.is_stage_beaten("narrows")


func _update_cards() -> void:
	for i in cards.size():
		var card: Button = cards[i]
		var locked := _is_locked(i)
		card.disabled = locked
		var base: StyleBoxFlat = _style_locked if locked else (_style_selected if i == _selected else _style_normal)
		card.add_theme_stylebox_override("normal", base)
		card.add_theme_stylebox_override("hover", base if (locked or i == _selected) else _style_hover)
		card.add_theme_stylebox_override("pressed", base)
		card.add_theme_stylebox_override("focus", _style_selected if i == _selected else _style_hover)
		card.add_theme_stylebox_override("disabled", _style_locked)
		var status: Label = status_labels[i]
		if locked:
			status.text = "BEAT THE NARROWS"
			status.add_theme_color_override("font_color", Color(0.364706, 0.396078, 0.458824))
		elif i == _selected:
			status.text = "SELECTED"
			status.add_theme_color_override("font_color", Color(0.498039, 0.682353, 0.854902))
		else:
			status.text = "AVAILABLE"
			status.add_theme_color_override("font_color", Color(0.541176, 0.576471, 0.647059))
	lock_label.visible = _is_locked(2)


func _on_harbor_pressed() -> void:
	_select(0)


func _on_narrows_pressed() -> void:
	_select(1)


func _on_open_water_pressed() -> void:
	_select(2)


func _select(index: int) -> void:
	if _is_locked(index):
		return
	_selected = index
	GameSettings.selected_stage = STAGES[index]["id"]
	_update_cards()


func _on_battle_pressed() -> void:
	GameSettings.selected_stage = STAGES[_selected]["id"]
	get_tree().change_scene_to_file(STAGES[_selected]["scene"])


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
