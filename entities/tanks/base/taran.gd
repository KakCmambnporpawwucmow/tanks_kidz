extends Area2D

class_name Taran

@export var _damage:DamageComponent = null

func _ready() -> void:
	assert(_damage != null, "Taran: DamageComponent must be assigned")

func _on_body_entered(body: Node2D) -> void:
	if body != get_parent() and body.has_method("get_health") and body.get_health() != null:
		if body is Obstacle or body is Tank:
			_damage.execute(body.get_health())
