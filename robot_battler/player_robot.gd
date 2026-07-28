extends CharacterBody3D

@export var move_speed: float = 6.0
@export var turn_speed: float = 180.0
@export var max_hp: float = 100.0
@export var camera_distance: float = 6.0
@export var camera_height: float = 3.5
@export var mouse_sensitivity: float = 0.15

@export_group("Melee")
@export var melee_damage: float = 25.0
@export var melee_range: float = 2.2
@export var melee_cooldown: float = 0.5
@export var ram_damage: float = 15.0
@export var ram_cooldown: float = 0.3

@export_group("Ranged")
@export var ranged_damage: float = 10.0
@export var ranged_speed: float = 18.0
@export var ranged_max_distance: float = 20.0
@export var ranged_cooldown: float = 0.35

enum Weapon { MELEE, RANGED }

const MELEE_HITBOX_SCENE := preload("res://robot_battler/melee_hitbox.tscn")
const PROJECTILE_SCENE := preload("res://robot_battler/projectile.tscn")

@onready var turret: Node3D = $Turret
@onready var muzzle: Marker3D = $Turret/Muzzle
@onready var camera: Camera3D = $Camera3D
@onready var weapon_label: Label = $HUD/WeaponLabel
@onready var melee_weapon_model: Node3D = $Turret/SawBlade
@onready var ranged_weapon_model: Node3D = $Turret/RangedWeaponModel
@onready var hp_bar: ProgressBar = $HUD/HPBar

var current_weapon: Weapon = Weapon.MELEE
var shots_fired: int = 0
var shots_hit: int = 0
var _top_view: bool = false
var _dead: bool = false
var hp: float = 0.0
var _spawn_point: Vector3 = Vector3.ZERO
var _melee_cooldown_remaining: float = 0.0
var _ranged_cooldown_remaining: float = 0.0
var _ram_cooldown_remaining: float = 0.0


func _ready() -> void:
	add_to_group("player")
	hp = max_hp
	hp_bar.max_value = max_hp
	_spawn_point = global_position
	_update_hp_bar()
	_update_weapon_display()
	_update_camera()
	_update_mouse_capture()


func _physics_process(delta: float) -> void:
	_update_cooldowns(delta)
	_handle_rotation(delta)
	_handle_movement()
	move_and_slide()
	_handle_ram_damage()
	if global_position.y < -8.0:
		take_damage(max_hp)
	_update_camera()
	if melee_weapon_model.visible:
		melee_weapon_model.rotate_y(deg_to_rad(540.0) * delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		attack()
	elif event.is_action_pressed("weapon_swap"):
		swap_weapon()
	elif event.is_action_pressed("toggle_view"):
		toggle_view()
		_update_mouse_capture()
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_apply_mouse_turn(event.relative.x)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif what == NOTIFICATION_UNPAUSED:
		_update_mouse_capture()


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _update_mouse_capture() -> void:
	if _should_capture_mouse():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _should_capture_mouse() -> bool:
	return GameSettings.control_mode == GameSettings.ControlMode.MOUSE


func _apply_mouse_turn(horizontal_motion: float) -> void:
	rotate_y(-horizontal_motion * deg_to_rad(mouse_sensitivity))


func _update_cooldowns(delta: float) -> void:
	_melee_cooldown_remaining = maxf(0.0, _melee_cooldown_remaining - delta)
	_ranged_cooldown_remaining = maxf(0.0, _ranged_cooldown_remaining - delta)
	_ram_cooldown_remaining = maxf(0.0, _ram_cooldown_remaining - delta)


func _handle_ram_damage() -> void:
	if current_weapon != Weapon.MELEE or _ram_cooldown_remaining > 0.0:
		return
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider == null:
			continue
		var turret: Node = null
		if collider.is_in_group("enemy_turret"):
			turret = collider
		elif collider.is_in_group("island"):
			turret = _nearest_living_turret(collision.get_position(), 3.0)
		if turret != null and not turret.is_destroyed():
			turret.take_damage(ram_damage)
			_ram_cooldown_remaining = ram_cooldown
			break


func _nearest_living_turret(point: Vector3, max_distance: float) -> Node:
	var nearest: Node = null
	var best := max_distance
	for turret in get_tree().get_nodes_in_group("enemy_turret"):
		if turret.is_destroyed():
			continue
		var distance: float = turret.global_position.distance_to(point)
		if distance < best:
			best = distance
			nearest = turret
	return nearest


func _handle_rotation(delta: float) -> void:
	if GameSettings.control_mode == GameSettings.ControlMode.MOUSE:
		return
	var turn_input := Input.get_action_strength("turn_right") - Input.get_action_strength("turn_left")
	rotate_y(-turn_input * deg_to_rad(turn_speed) * delta)


func _handle_movement() -> void:
	if GameSettings.control_mode == GameSettings.ControlMode.MOUSE:
		_handle_free_movement()
		return
	var move_input := Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
	var forward := -global_transform.basis.z
	velocity.x = forward.x * move_input * move_speed
	velocity.z = forward.z * move_input * move_speed


func _handle_free_movement() -> void:
	var input := Input.get_vector("turn_left", "turn_right", "move_forward", "move_back")
	var cam_basis := camera.global_transform.basis
	var forward := -cam_basis.z
	forward.y = 0.0
	if forward.length() < 0.01:
		forward = cam_basis.y
		forward.y = 0.0
	if forward.length() < 0.01:
		forward = -global_transform.basis.z
	forward = forward.normalized()
	var right := cam_basis.x
	right.y = 0.0
	right = right.normalized() if right.length() > 0.01 else global_transform.basis.x
	var move := right * input.x - forward * input.y
	if move.length() > 1.0:
		move = move.normalized()
	velocity.x = move.x * move_speed
	velocity.z = move.z * move_speed


func toggle_view() -> void:
	_top_view = not _top_view
	if _top_view:
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = 16.0
	else:
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	_update_camera()


func _update_camera() -> void:
	if _top_view:
		camera.global_position = global_position + Vector3(0, 14, 0)
		camera.rotation_degrees = Vector3(-90, 0, 0)
	else:
		var behind := global_transform.basis.z
		camera.global_position = global_position + behind * camera_distance + Vector3(0, camera_height, 0)
		camera.look_at(global_position + Vector3(0, 1.5, 0))


func swap_weapon() -> void:
	current_weapon = Weapon.RANGED if current_weapon == Weapon.MELEE else Weapon.MELEE
	_update_weapon_display()


func attack() -> void:
	if current_weapon == Weapon.MELEE:
		_attack_melee()
	else:
		_attack_ranged()


func _attack_melee() -> void:
	if _melee_cooldown_remaining > 0.0:
		return
	_melee_cooldown_remaining = melee_cooldown
	var hitbox := MELEE_HITBOX_SCENE.instantiate()
	get_tree().current_scene.add_child(hitbox)
	hitbox.global_transform = muzzle.global_transform
	hitbox.setup(melee_damage, melee_range, self)


func _attack_ranged() -> void:
	if _ranged_cooldown_remaining > 0.0:
		return
	_ranged_cooldown_remaining = ranged_cooldown
	shots_fired += 1
	var projectile := PROJECTILE_SCENE.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_transform = muzzle.global_transform
	var direction := -muzzle.global_transform.basis.z
	projectile.setup(direction, ranged_speed, ranged_damage, ranged_max_distance, self)


func _update_weapon_display() -> void:
	var is_melee := current_weapon == Weapon.MELEE
	weapon_label.text = "Weapon: Melee" if is_melee else "Weapon: Ranged"
	melee_weapon_model.visible = is_melee
	ranged_weapon_model.visible = not is_melee


func on_projectile_hit() -> void:
	shots_hit += 1


func take_damage(amount: float) -> void:
	if _dead:
		return
	hp = max(0.0, hp - amount)
	_update_hp_bar()
	if hp <= 0.0:
		_die()


func _die() -> void:
	_dead = true
	get_tree().call_group("stage_manager", "on_player_defeated")


func _update_hp_bar() -> void:
	hp_bar.value = hp
