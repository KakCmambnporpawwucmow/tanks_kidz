# commands/tank_commands.gd - ДОБАВИТЬ
class_name TankReloadCommand
extends Command

func execute(entity: Node) -> void:
	if entity is Tank:
		entity.start_reload()

func serialize() -> Dictionary:
	var data = super()
	return data
