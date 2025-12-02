extends Area2D

@export var damage:DamageComponent = null

func _on_body_entered(body: Node2D) -> void:
	if damage != null and body.has_method("get_health") and body.get_health() != null:
		if body is Obstacle or body is Tank:
			damage.execute(body.get_health())
