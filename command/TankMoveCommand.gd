# commands/tank_commands.gd
class_name TankMoveCommand
extends Command

var direction: Vector2

func init(dir: Vector2) -> Command:
	direction = dir
	return self
	
func execute(entity: Node) -> void:
	if entity is Tank:
		entity.move(direction)

func serialize() -> Dictionary:
	var data = super()
	data["direction"] = {"x": direction.x, "y": direction.y}
	return data

static func deserialize(data: Dictionary) -> TankMoveCommand:
	var command = TankMoveCommand.new()
	command.init(data.direction)
	command.entity_id = data.entity_id
	command.timestamp = data.timestamp
	return command
