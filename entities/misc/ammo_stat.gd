extends HBoxContainer
class_name AmmoStatistic

@export var tank:Tank = null
var weapon_system:WeaponSystem = null

func _ready() -> void:
	assert(tank != null, "AmmoStat: tank must be assigned")
	weapon_system =  tank.weapon_system
	assert(weapon_system != null, "AmmoStat: weapon_system must be assigned")
	weapon_system.send_update.connect(update)
	update()
	
func update():
	var current_ammo_type = weapon_system.get_current_ammo_type()
	for child in get_children():
		if child is AmmoState:
			child.bold_state = child.ammo_type ==  current_ammo_type
			child.count = weapon_system.get_proj_count(child.ammo_type)
