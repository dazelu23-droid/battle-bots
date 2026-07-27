extends Node

enum Difficulty { EASY, MEDIUM, HARD }

var difficulty: Difficulty = Difficulty.MEDIUM
var selected_stage: String = "harbor"
var stages_beaten: Array[String] = []


func mark_stage_beaten(stage_id: String) -> void:
	if not stages_beaten.has(stage_id):
		stages_beaten.append(stage_id)


func is_stage_beaten(stage_id: String) -> bool:
	return stages_beaten.has(stage_id)


func turret_fire_cooldown_scale() -> float:
	match difficulty:
		Difficulty.EASY:
			return 1.6
		Difficulty.HARD:
			return 0.6
		_:
			return 1.0


func turret_damage_scale() -> float:
	match difficulty:
		Difficulty.EASY:
			return 0.5
		Difficulty.HARD:
			return 1.5
		_:
			return 1.0
