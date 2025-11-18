# commands/tank_commands.gd
class_name TankShootCommand
extends Command

func execute(entity: Node) -> void:
	if entity is Tank:
		entity.fire()

func serialize() -> Dictionary:
	var data = super()
	return data
