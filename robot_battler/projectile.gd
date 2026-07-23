extends Area3D

var _direction: Vector3 = Vector3.FORWARD
var _speed: float = 18.0
var _damage: float = 10.0
var _max_distance: float = 20.0
var _traveled: float = 0.0
var _attacker: Node = null


func setup(direction: Vector3, speed: float, damage: float, max_distance: float, attacker: Node) -> void:
	_direction = direction
	_speed = speed
	_damage = damage
	_max_distance = max_distance
	_attacker = attacker
	if direction.length() > 0.01:
		look_at(global_position + direction, Vector3.UP)


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	var step := _direction * _speed * delta
	global_position += step
	_traveled += step.length()
	if _traveled >= _max_distance:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body == _attacker:
		return
	if body.has_method("take_damage"):
		body.take_damage(_damage)
	queue_free()
