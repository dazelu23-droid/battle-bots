extends Area3D

const LIFETIME := 0.15

var _damage: float = 0.0
var _attacker: Node = null
var _hit_bodies: Array[Node] = []


func setup(damage: float, reach: float, attacker: Node) -> void:
	_damage = damage
	_attacker = attacker
	var shape := $CollisionShape3D.shape as BoxShape3D
	shape.size = Vector3(1.6, 1.2, reach)
	translate_object_local(Vector3(0, 0, -reach * 0.5))


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(LIFETIME).timeout.connect(queue_free)


func _on_body_entered(body: Node) -> void:
	if body == _attacker or body in _hit_bodies:
		return
	if body.has_method("take_damage"):
		_hit_bodies.append(body)
		body.take_damage(_damage)
