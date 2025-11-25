# commands/tank_commands.gd
class_name TankSwitchAmmoCommand
extends Command

var ammo_type: WeaponSystem.ProjectileType

func init(ammo: WeaponSystem.ProjectileType) -> Command:
	entity_id = "TankSwitchAmmoCommand"
	timestamp = Time.get_ticks_msec()
	ammo_type = ammo
	return self

func execute(entity: Node) -> void:
	if entity is Tank:
		entity.switch_ammo_type(ammo_type)

func serialize() -> Dictionary:
	var data = super()
	data["ammo_type"] = ammo_type
	return data
