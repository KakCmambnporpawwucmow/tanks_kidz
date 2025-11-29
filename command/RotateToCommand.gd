# commands/tank_commands.gd
class_name RotateToCommand
extends Command

var target_pos: Vector2

func init(pos: Vector2) -> Command:
	entity_id = "RotateToCommand"
	timestamp = Time.get_ticks_msec()
	target_pos = pos
	return self

func execute(entity: Node) -> void:
		entity.rotating_to(target_pos)

func serialize() -> Dictionary:
	var data = super()
	data["target_pos"] = target_pos
	return data
