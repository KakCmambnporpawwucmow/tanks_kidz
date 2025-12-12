# commands/command.gd
class_name Command
extends RefCounted

var entity_id: String
var timestamp: float

func execute(_entity: Node) -> void:
	print("Command.execute() not implemented")

func serialize() -> Dictionary:
	return {
		"entity_id": entity_id,
		"timestamp": timestamp,
		"type": get_script().resource_path.get_file()
	}

static func deserialize(data: Dictionary) -> Command:
	var script_path = "res://command/%s.gd" % data.type
	if not ResourceLoader.exists(script_path):
		print("Error. Command script not found: " + script_path)
		return null
	
	var command_script = load(script_path)
	var command = command_script.new()
	command.entity_id = data.get("entity_id", "")
	command.timestamp = data.get("timestamp", 0.0)
	return command
