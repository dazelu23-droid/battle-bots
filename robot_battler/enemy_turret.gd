extends StaticBody3D

@export var max_hp: float = 60.0
@export var fire_cooldown: float = 1.5
@export var range: float = 18.0
@export var projectile_speed: float = 12.0
@export var projectile_damage: float = 10.0
@export var projectile_max_distance: float = 22.0
@export var use_own_island: bool = true

const DAMAGE_NUMBER_SCENE := preload("res://robot_battler/damage_number.tscn")
const ENEMY_PROJECTILE_SCENE := preload("res://robot_battler/enemy_projectile.tscn")

@onready var model: Node3D = $Model
@onready var muzzle: Marker3D = $Model/Muzzle
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var health_fill: MeshInstance3D = $HealthBar/Fill
@onready var island: StaticBody3D = $Island
@onready var island_collision: CollisionShape3D = $Island/CollisionShape3D

var hp: float = 0.0
var _flash_tween: Tween = null
var _destroyed: bool = false
var _fire_cooldown_remaining: float = 0.0


func _ready() -> void:
	add_to_group("enemy_turret")
	fire_cooldown *= GameSettings.turret_fire_cooldown_scale()
	projectile_damage *= GameSettings.turret_damage_scale()
	if not use_own_island:
		island.visible = false
		island_collision.disabled = true
	hp = max_hp
	_update_health_bar()


func _physics_process(delta: float) -> void:
	if _destroyed:
		return
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return
	var to_player := player.global_position - global_position
	to_player.y = 0.0
	if to_player.length() > range:
		return
	var look_target := Vector3(player.global_position.x, global_position.y, player.global_position.z)
	if look_target.distance_to(global_position) > 0.01:
		model.look_at(look_target, Vector3.UP)
	_fire_cooldown_remaining -= delta
	if _fire_cooldown_remaining <= 0.0 and _has_line_of_sight(player):
		_fire_cooldown_remaining = fire_cooldown
		_fire_at(player.global_position)


func _has_line_of_sight(player: Node3D) -> bool:
	var space := get_world_3d().direct_space_state
	var from := muzzle.global_position
	var to := player.global_position + Vector3(0, 0.5, 0)
	var query := PhysicsRayQueryParameters3D.create(from, to, 3)
	query.exclude = [get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return true
	return hit.collider == player


func take_damage(amount: float) -> void:
	if _destroyed:
		return
	hp = max(0.0, hp - amount)
	_update_health_bar()
	_spawn_damage_number(amount)
	_flash()
	if hp <= 0.0:
		_on_depleted()


func reset() -> void:
	hp = max_hp
	_destroyed = false
	visible = true
	collision_shape.disabled = false
	island_collision.disabled = not use_own_island
	_update_health_bar()


func _update_health_bar() -> void:
	var ratio: float = clampf(hp / max_hp, 0.0, 1.0) if max_hp > 0.0 else 0.0
	health_fill.scale.x = ratio


func _flash() -> void:
	if _flash_tween != null and _flash_tween.is_running():
		_flash_tween.kill()
	model.scale = Vector3(1.15, 1.15, 1.15)
	_flash_tween = create_tween()
	_flash_tween.tween_property(model, "scale", Vector3.ONE, 0.12)


func _spawn_damage_number(amount: float) -> void:
	var number := DAMAGE_NUMBER_SCENE.instantiate()
	get_tree().current_scene.add_child(number)
	number.global_position = global_position + Vector3(0, 2.6, 0)
	number.setup(amount)


func is_destroyed() -> bool:
	return _destroyed


func _on_depleted() -> void:
	_destroyed = true
	visible = false
	collision_shape.disabled = true
	island_collision.disabled = true
	get_tree().call_group("stage_manager", "on_turret_destroyed")


func _fire_at(target_pos: Vector3) -> void:
	var projectile := ENEMY_PROJECTILE_SCENE.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_transform = muzzle.global_transform
	var direction := target_pos - muzzle.global_position
	direction.y = 0.0
	if direction.length() > 0.01:
		direction = direction.normalized()
	else:
		direction = -muzzle.global_transform.basis.z
	projectile.setup(direction, projectile_speed, projectile_damage, projectile_max_distance, self)
