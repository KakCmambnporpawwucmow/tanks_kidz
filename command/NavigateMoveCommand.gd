class_name NavigateMoveCommand
extends Command

var target_pos: Vector2

func init(pos: Vector2) -> Command:
	entity_id = "NavigateMoveCommand"
	timestamp = Time.get_ticks_msec()
	target_pos = pos
	return self

func execute(entity: Node) -> void:
	if is_instance_valid(entity) and entity.has_method("move_to"):
		entity.move_to(target_pos)

func serialize() -> Dictionary:
	var data = super()
	data["target_pos"] = target_pos
	return data
