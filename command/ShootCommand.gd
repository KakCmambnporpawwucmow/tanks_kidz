# commands/tank_commands.gd
class_name ShootCommand
extends Command

func init() -> Command:
	entity_id = "ShootCommand"
	timestamp = Time.get_ticks_msec()
	return self

func execute(entity: Node) -> void:
	if is_instance_valid(entity) and entity.has_method("fire"):
		entity.fire()

func serialize() -> Dictionary:
	var data = super()
	return data
