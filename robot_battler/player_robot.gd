extends CharacterBody3D

@export var move_speed: float = 6.0
@export var turn_speed: float = 180.0
@export var max_hp: float = 100.0

@export_group("Melee")
@export var melee_damage: float = 25.0
@export var melee_range: float = 2.2
@export var melee_cooldown: float = 0.5

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
@onready var melee_weapon_model: MeshInstance3D = $Turret/TurretMesh
@onready var ranged_weapon_model: Node3D = $Turret/RangedWeaponModel
@onready var hp_bar: ProgressBar = $HUD/HPBar

var current_weapon: Weapon = Weapon.MELEE
var hp: float = 0.0
var _spawn_point: Vector3 = Vector3.ZERO
var _melee_cooldown_remaining: float = 0.0
var _ranged_cooldown_remaining: float = 0.0


func _ready() -> void:
	add_to_group("player")
	hp = max_hp
	hp_bar.max_value = max_hp
	_spawn_point = global_position
	_update_hp_bar()
	_update_weapon_display()
	_update_camera()


func _physics_process(delta: float) -> void:
	_update_cooldowns(delta)
	_handle_rotation(delta)
	_handle_movement()
	move_and_slide()
	_update_camera()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		attack()
	elif event.is_action_pressed("weapon_swap"):
		swap_weapon()


func _update_cooldowns(delta: float) -> void:
	_melee_cooldown_remaining = maxf(0.0, _melee_cooldown_remaining - delta)
	_ranged_cooldown_remaining = maxf(0.0, _ranged_cooldown_remaining - delta)


func _handle_rotation(delta: float) -> void:
	var turn_input := Input.get_action_strength("turn_right") - Input.get_action_strength("turn_left")
	rotate_y(-turn_input * deg_to_rad(turn_speed) * delta)


func _handle_movement() -> void:
	var move_input := Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
	var forward := -global_transform.basis.z
	velocity.x = forward.x * move_input * move_speed
	velocity.z = forward.z * move_input * move_speed


func _update_camera() -> void:
	camera.global_position = global_position + Vector3(0, 14, 0)


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


func take_damage(amount: float) -> void:
	hp = max(0.0, hp - amount)
	_update_hp_bar()
	if hp <= 0.0:
		_respawn()


func _respawn() -> void:
	hp = max_hp
	global_position = _spawn_point
	_update_hp_bar()
	for turret in get_tree().get_nodes_in_group("enemy_turret"):
		turret.reset()


func _update_hp_bar() -> void:
	hp_bar.value = hp
