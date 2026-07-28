extends Node3D

const STAGE_SELECT_SCENE := "res://robot_battler/stage_select.tscn"
const DEFEAT_SCREEN_SCENE := preload("res://robot_battler/defeat_screen.tscn")
const VICTORY_SCREEN_SCENE := preload("res://robot_battler/victory_screen.tscn")

@export var stage_id: String = "harbor"

var _cleared: bool = false
var _defeated: bool = false
var _elapsed: float = 0.0


func _ready() -> void:
	add_to_group("stage_manager")


func _process(delta: float) -> void:
	if not _cleared and not _defeated:
		_elapsed += delta


func on_player_defeated() -> void:
	if _cleared or _defeated:
		return
	_defeated = true
	var player := get_tree().get_first_node_in_group("player")
	var screen := DEFEAT_SCREEN_SCENE.instantiate()
	add_child(screen)
	screen.show_defeat(_elapsed, player.shots_fired, player.shots_hit)


func on_turret_destroyed() -> void:
	if _cleared:
		return
	for turret in get_tree().get_nodes_in_group("enemy_turret"):
		if not turret.is_destroyed():
			return
	_cleared = true
	GameSettings.mark_stage_beaten(stage_id)
	var player := get_tree().get_first_node_in_group("player")
	var screen := VICTORY_SCREEN_SCENE.instantiate()
	add_child(screen)
	screen.show_victory(_elapsed, player.shots_fired, player.shots_hit)
