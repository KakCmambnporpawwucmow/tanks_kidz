extends Projectile
class_name MissileProjectile

@export var move_component:BaseMoveComponent = null

func _ready() -> void:
	if move_component == null:
		LOG.fatal("MissileProjectile {0}: move_component must be assigned.".format([name]))
	assert(move_component != null, "MissileProjectile: BaseMoveComponent must be assigned")
	for item in get_tree().get_nodes_in_group("CommandProducers"):
		if item is CommandProducer:
			if item.add_receiver(self) != true:
				print("Error. Projectile {0}, not registred in CommandProducer".format([name]))

func proc_command(command:Command):
	if is_instance_valid(move_component) and is_instance_valid(command):
		command.execute(self)
	
func rotating_to(_position:Vector2):
	move_component.smooth_look_at(_position)
	
func _process(_delta: float) -> void:
	if move_component != null:
		move_component.move(Vector2.RIGHT)
		
func on_death(_damage:int = 0):
	move_component.move(Vector2.ZERO)
	super.on_death(_damage)

func _on_timer_timeout() -> void:
	linear_velocity = Vector2.ZERO
	$view.visible = false
	$AnimationPlayer.play("penetracion")
