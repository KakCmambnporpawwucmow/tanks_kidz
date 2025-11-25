# commands/tank_commands.gd - ДОБАВИТЬ
class_name TankReloadCommand
extends Command

func init() -> Command:
	entity_id = "TankReloadCommand"
	timestamp = Time.get_ticks_msec()
	return self

func execute(entity: Node) -> void:
	if entity is Tank:
		entity.start_reload()

func serialize() -> Dictionary:
	var data = super()
	return data
