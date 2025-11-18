# commands/tank_commands.gd
class_name TankRotateTurretCommand
extends Command

var target_angle: float

func init(angle: float) -> void:
	target_angle = angle

func execute(entity: Node) -> void:
	if entity is Tank:
		entity.rotate_turret(target_angle)

func serialize() -> Dictionary:
	var data = super()
	data["target_angle"] = target_angle
	return data
