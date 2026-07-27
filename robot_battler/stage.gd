extends Node3D

const STAGE_SELECT_SCENE := "res://robot_battler/stage_select.tscn"

@export var stage_id: String = "harbor"

var _cleared: bool = false


func _ready() -> void:
	add_to_group("stage_manager")


func on_turret_destroyed() -> void:
	if _cleared:
		return
	for turret in get_tree().get_nodes_in_group("enemy_turret"):
		if not turret.is_destroyed():
			return
	_cleared = true
	GameSettings.mark_stage_beaten(stage_id)
	_show_stage_clear()


func _show_stage_clear() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 9
	add_child(layer)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)
	var label := Label.new()
	label.text = "STAGE CLEAR!"
	label.add_theme_font_size_override("font_size", 80)
	label.add_theme_color_override("font_color", Color(0.941, 0.949, 0.961))
	label.add_theme_color_override("font_outline_color", Color(0.102, 0.114, 0.141))
	label.add_theme_constant_override("outline_size", 12)
	center.add_child(label)
	await get_tree().create_timer(2.5).timeout
	get_tree().change_scene_to_file(STAGE_SELECT_SCENE)
