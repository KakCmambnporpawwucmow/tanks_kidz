# commands/tank_commands.gd
class_name TankRotateCommand
extends Command

var rotation_direction: Tank.ERotate

func init(rot_dir: Tank.ERotate) -> Command:
	entity_id = "TankRotateCommand"
	timestamp = Time.get_ticks_msec()
	rotation_direction = rot_dir
	return self

func execute(entity: Node) -> void:
	if entity is Tank:
		entity.rotating(rotation_direction)

func serialize() -> Dictionary:
	var data = super()
	data["rotation_direction"] = rotation_direction
	return data
