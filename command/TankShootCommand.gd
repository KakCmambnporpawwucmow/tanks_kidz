# commands/tank_commands.gd
class_name ShootCommand
extends Command

func init() -> Command:
	entity_id = "ShootCommand"
	timestamp = Time.get_ticks_msec()
	return self

func execute(entity: Node) -> void:
	if entity is Tank:
		entity.fire()

func serialize() -> Dictionary:
	var data = super()
	return data
