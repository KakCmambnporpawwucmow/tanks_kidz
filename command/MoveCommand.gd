# commands/tank_commands.gd
class_name MoveCommand
extends Command

var direction: Vector2

func init(dir: Vector2) -> Command:
	entity_id = "MoveCommand"
	timestamp = Time.get_ticks_msec()
	direction = dir
	return self
	
func execute(entity: Node) -> void:
	if is_instance_valid(entity) and entity.has_method("move"):
		entity.move(direction)

func serialize() -> Dictionary:
	var data = super()
	data["direction"] = {"x": direction.x, "y": direction.y}
	return data

static func deserialize(data: Dictionary) -> MoveCommand:
	var command = MoveCommand.new()
	var dir = data.get("direction", {"x":0, "y":0})
	command.init(Vector2(dir["x"], dir["y"]))
	command.entity_id = data.entity_id
	command.timestamp = data.timestamp
	return command
