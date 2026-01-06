extends Area2D


func _on_body_entered(body: Node2D) -> void:
	if body is Tank:
		body.reload_all_ammo()
