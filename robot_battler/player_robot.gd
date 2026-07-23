extends CharacterBody3D

@export var move_speed: float = 6.0

@onready var turret: Node3D = $Turret
@onready var camera: Camera3D = $Camera3D

var aim_point: Vector3 = Vector3.ZERO


func _physics_process(_delta: float) -> void:
	_handle_movement()
	_handle_aim()
	move_and_slide()


func _handle_movement() -> void:
	var input_dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	)
	var direction := Vector3(input_dir.x, 0.0, input_dir.y)
	if direction.length() > 1.0:
		direction = direction.normalized()
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed


func _handle_aim() -> void:
	var mouse_pos := get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_dir := camera.project_ray_normal(mouse_pos)
	if absf(ray_dir.y) < 0.0001:
		return
	var t := -ray_origin.y / ray_dir.y
	if t < 0.0:
		return
	aim_point = ray_origin + ray_dir * t
	var look_target := Vector3(aim_point.x, turret.global_position.y, aim_point.z)
	if look_target.distance_to(turret.global_position) > 0.01:
		turret.look_at(look_target, Vector3.UP)
