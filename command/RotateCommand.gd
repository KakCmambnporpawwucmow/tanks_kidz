# commands/tank_commands.gd
class_name RotateCommand
extends Command

var rotation_direction: Tank.ERotate

func init(rot_dir: Tank.ERotate) -> Command:
	entity_id = "RotateCommand"
	timestamp = Time.get_ticks_msec()
	rotation_direction = rot_dir
	return self

func execute(entity: Node) -> void:
	if is_instance_valid(entity) and entity.has_method("rotating"):
		entity.rotating(rotation_direction)

func serialize() -> Dictionary:
	var data = super()
	data["rotation_direction"] = rotation_direction
	return data
