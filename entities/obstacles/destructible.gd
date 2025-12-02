extends Obstacle
class_name Destructible

@export var done_animation:AnimationPlayer = null

func  _ready() -> void:
	$placeholder.visible = false

func _on_health_component_death() -> void:
	if done_animation != null: #and done_animation.current_animation == "done":
		done_animation.animation_finished.connect(_on_done_animation_finished)
		done_animation.play("done")
	else:
		done_state()

func _on_done_animation_finished(anim_name: StringName) -> void:
	done_state()
	
func done_state():
	var glob_pos = $placeholder.global_position
	var ph = $placeholder
	remove_child(ph)
	get_parent().call_deferred("add_child", ph)
	ph.global_position = glob_pos
	queue_free()
