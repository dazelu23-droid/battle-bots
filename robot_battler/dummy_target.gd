extends StaticBody3D

@export var max_hp: float = 60.0
@export var reset_delay: float = 1.5

var hp: float = 0.0

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var health_fill: MeshInstance3D = $HealthBar/Fill

const DAMAGE_NUMBER_SCENE := preload("res://robot_battler/damage_number.tscn")

var _flash_tween: Tween = null
var _destroyed: bool = false


func _ready() -> void:
	hp = max_hp
	_update_health_bar()


func take_damage(amount: float) -> void:
	if _destroyed:
		return
	hp = max(0.0, hp - amount)
	_update_health_bar()
	_spawn_damage_number(amount)
	_flash()
	if hp <= 0.0:
		_on_depleted()


func _update_health_bar() -> void:
	var ratio: float = clampf(hp / max_hp, 0.0, 1.0) if max_hp > 0.0 else 0.0
	health_fill.scale.x = ratio


func _flash() -> void:
	if _flash_tween != null and _flash_tween.is_running():
		_flash_tween.kill()
	mesh.scale = Vector3(1.15, 1.15, 1.15)
	_flash_tween = create_tween()
	_flash_tween.tween_property(mesh, "scale", Vector3.ONE, 0.12)


func _spawn_damage_number(amount: float) -> void:
	var number := DAMAGE_NUMBER_SCENE.instantiate()
	get_tree().current_scene.add_child(number)
	number.global_position = global_position + Vector3(0, 2.6, 0)
	number.setup(amount)


func _on_depleted() -> void:
	_destroyed = true
	visible = false
	collision_shape.disabled = true
	get_tree().create_timer(reset_delay).timeout.connect(_reset)


func _reset() -> void:
	hp = max_hp
	_destroyed = false
	visible = true
	collision_shape.disabled = false
	_update_health_bar()
