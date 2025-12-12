# commands/tank_commands.gd - ДОБАВИТЬ
class_name ReloadCommand
extends Command

func init() -> Command:
	entity_id = "ReloadCommand"
	timestamp = Time.get_ticks_msec()
	return self

func execute(entity: Node) -> void:
	if entity is Tank:
		entity.start_reload()

func serialize() -> Dictionary:
	var data = super()
	return data
