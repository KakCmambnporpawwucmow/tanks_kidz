extends Node2D
class_name AmmoStat

@export var weapon_system:WeaponSystem = null

func _ready() -> void:
	assert(weapon_system != null, "AmmoStat: WeaponSystem must be assigned")
	$ap.max_value = weapon_system.get_proj_max_load(WeaponSystem.ProjectileType.AP)
	$he.max_value = weapon_system.get_proj_max_load(WeaponSystem.ProjectileType.HE)
	$heat.max_value = weapon_system.get_proj_max_load(WeaponSystem.ProjectileType.HEAT)
	$missile.max_value = weapon_system.get_proj_max_load(WeaponSystem.ProjectileType.MISSILE)
	update()
	
func update():
	$ap.value = weapon_system.get_proj_count(WeaponSystem.ProjectileType.AP)
	$ap.visible = true if $ap.value > 0 else false
	$ap/count.text = str(int($ap.value))
	
	$he.value = weapon_system.get_proj_count(WeaponSystem.ProjectileType.HE)
	$he.visible = true if $he.value > 0 else false
	$he/count.text = str(int($he.value))
	
	$heat.value = weapon_system.get_proj_count(WeaponSystem.ProjectileType.HEAT)
	$heat.visible = true if $heat.value > 0 else false
	$heat/count.text = str(int($heat.value))
	
	$missile.value = weapon_system.get_proj_count(WeaponSystem.ProjectileType.MISSILE)
	$missile.visible = true if $missile.value > 0 else false
	$missile/count.text = str(int($missile.value))
	
func set_ammo_type(type:WeaponSystem.ProjectileType):
	$v_ap.visible = false
	$v_he.visible = false
	$v_heat.visible = false
	$v_missile.visible = false
	match type:
		WeaponSystem.ProjectileType.AP:
			$v_ap.visible = true
		WeaponSystem.ProjectileType.HE:
			$v_he.visible = true
		WeaponSystem.ProjectileType.HEAT:
			$v_heat.visible = true
		WeaponSystem.ProjectileType.MISSILE:
			$v_missile.visible = true
