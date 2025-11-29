extends Projectile
class_name MissileProjectile

@export var move_component:BaseMoveComponent = null

func proc_command(command:Command):
	if is_instance_valid(move_component) and is_activate:
		command.execute(self)
	
func rotating_to(_position:Vector2):
	move_component.smooth_look_at(_position)
	
func _process(delta: float) -> void:
	if is_activate:
		move_component.move(Vector2.RIGHT)
		
func on_death(_damage:int = 0):
	is_activate = false
	move_component.move(Vector2.ZERO)
	super.on_death(_damage)

func _on_timer_timeout() -> void:
	linear_velocity = Vector2.ZERO
	$view.visible = false
	$AnimationPlayer.play("penetracion")
