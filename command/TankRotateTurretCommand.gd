# commands/tank_commands.gd
class_name TankRotateTurretCommand
extends Command

var target_pos: Vector2

func init(pos: Vector2) -> Command:
	entity_id = "TankRotateTurretCommand"
	timestamp = Time.get_ticks_msec()
	target_pos = pos
	return self

func execute(entity: Node) -> void:
	if entity is Tank:
		entity.rotating_turret_to(target_pos)

func serialize() -> Dictionary:
	var data = super()
	data["target_pos"] = target_pos
	return data
