# commands/tank_commands.gd
class_name SwitchAmmoCommand
extends Command

var ammo_type: WeaponSystem.ProjectileType

func init(ammo: WeaponSystem.ProjectileType) -> Command:
	entity_id = "SwitchAmmoCommand"
	timestamp = Time.get_ticks_msec()
	ammo_type = ammo
	return self

func execute(entity: Node) -> void:
	if is_instance_valid(entity) and entity.has_method("switch_ammo_type"):
		entity.switch_ammo_type(ammo_type)

func serialize() -> Dictionary:
	var data = super()
	data["ammo_type"] = ammo_type
	return data
