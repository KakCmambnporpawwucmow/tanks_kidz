# weapon_system.gd
class_name WeaponSystem
extends Node

enum ProjectileType {
	AP,      # Бронебойный (Armor Piercing)
	HE,      # Осколочно-фугасный (High Explosive)  
	HEAT,    # Кумулятивный (High Explosive Anti-Tank)
	MISSILE  # Управляемая ракета
}

@export_group("Projectile Instances")
@export var ap_round: PackedScene = null
@export var he_round: PackedScene = null
@export var heat_round: PackedScene = null
@export var missile_round: PackedScene = null

@export_group("Spawn Settings")
@export var projectiles_parent: Node = null

@export_group("Weapon Properties")
@export var reload_time_ms: int = 2000  # Время перезарядки в миллисекундах

@export_group("Ammunition")
@export var initial_ap_rounds: int = 20
@export var initial_he_rounds: int = 10
@export var initial_heat_rounds: int = 5
@export var initial_missile_rounds: int = 2
@export var current_ammo_type: ProjectileType = WeaponSystem.ProjectileType.AP

class ProjectileState:
	var projectile:PackedScene = null
	var count:int = 0
	var max_load:int = 0
	var desc:String
	func _init(_projectile:PackedScene, _count:int, _desc:String) -> void:
		projectile = _projectile
		count = _count
		max_load = _count

# Хранилище боеприпасов
var projectile_storage: Dictionary = {}
var last_reload_time: int = 0

signal send_update()

func _ready():
	# Инициализация боеприпасов из настроек редактора
	projectile_storage[ProjectileType.AP] = ProjectileState.new(ap_round, initial_ap_rounds, "AP")
	projectile_storage[ProjectileType.HE] = ProjectileState.new(he_round, initial_he_rounds, "HE")
	projectile_storage[ProjectileType.HEAT] = ProjectileState.new(heat_round, initial_heat_rounds, "HEAT")
	projectile_storage[ProjectileType.MISSILE] = ProjectileState.new(missile_round, initial_missile_rounds, "MISSILE")
	Logi.info("WeaponSystem {0}: initialized.".format([name]))

# Основные методы стрельбы
func fire_projectile(position: Vector2, direction: Vector2) -> bool:
	if not can_fire(current_ammo_type):
		return false
	
	var projectile = get_projectile_instance(current_ammo_type)
	if projectile == null:
		push_error("WeaponSystem: No projectile instance assigned for type: ", get_projectile_name(current_ammo_type))
		return false

	# Создаем копию снаряда и настраиваем
	if not setup_projectile(projectile, position, direction):
		projectile.queue_free()
		return false
	
	# Расходуем боеприпасы и обновляем таймеры
	consume_ammo(current_ammo_type)
	check_ammo()
	send_update.emit()
	# Запускаем перезарядку
	last_reload_time = Time.get_ticks_msec()
	print("Fired ", get_projectile_name(current_ammo_type), " round")
	return true
	
func check_ammo()->bool:
	if get_proj_count(current_ammo_type) == 0:
		for ammo in ProjectileType.values():
				if switch_ammo_type(ammo):
					return true
		Logi.info("WeaponSystem {0}: All the ammo are gone.".format([name]))
	return false
		
func switch_ammo_type(new_type: WeaponSystem.ProjectileType)->bool:
	if get_proj_count(new_type) > 0:
		current_ammo_type = new_type
		send_update.emit()
		return true
	else:
		Logi.info("WeaponSystem {0}: Cannot switch to {1} - out of ammo".format([name, get_projectile_name(current_ammo_type)]))
	return false

func get_projectile_instance(projectile_type: ProjectileType) -> Projectile:
	if projectile_storage[projectile_type].projectile != null:
		return projectile_storage[projectile_type].projectile.instantiate()
	return null

func setup_projectile(projectile: Projectile, position: Vector2, direction: Vector2) -> bool:
	# Добавляем в сцену
	var parent = projectiles_parent if projectiles_parent else get_tree().current_scene
	if parent == null:
		push_error("WeaponSystem: No valid parent found for projectile")
		return false
	projectile.visible = true
	parent.add_child(projectile)
	# АКТИВИРУЕМ снаряд после добавления в сцену
	projectile.activate(position, direction)
	
	return true

# Проверки возможности стрельбы
func can_fire(projectile_type: ProjectileType) -> bool:
	var proj_state:ProjectileState = get_projectile_state(projectile_type)
	return proj_state != null and not is_reloading() and proj_state.count > 0
	
func get_projectile_state(projectile_type: ProjectileType)->ProjectileState:
	var proj_state:ProjectileState = projectile_storage.get(projectile_type, null)
	if proj_state == null:
		Logi.error("WeaponSystem {0}: No projectile with type {1}".format([name, get_projectile_name(projectile_type)]))
	if proj_state == null or not is_instance_valid(proj_state.projectile):
		proj_state = null
	return proj_state

func is_reloading() -> bool:
	return Time.get_ticks_msec() - last_reload_time < reload_time_ms

# Управление боеприпасами
func consume_ammo(projectile_type: ProjectileType)->bool:
	var proj_state:ProjectileState = get_projectile_state(projectile_type)
	if proj_state != null and proj_state.count > 0:
		proj_state.count -= 1
		return true
	return false

func reload_ammo(projectile_type: ProjectileType, amount: int)->int:
	var proj_state:ProjectileState = get_projectile_state(projectile_type)
	if proj_state != null:
		proj_state.count += amount
		if proj_state.count > proj_state.max_load:
			proj_state.count = proj_state.max_load
		return proj_state.count
	return 0

func get_projectile_name(projectile_type: ProjectileType) -> String:
	var proj_state:ProjectileState = get_projectile_state(projectile_type)
	if proj_state != null:
		return proj_state.desc
	return "Unknown"
	
func get_proj_max_load(projectile_type: ProjectileType)->int:
	var state = projectile_storage.get(projectile_type, null)
	return state.max_load if state != null else 0
	
func get_proj_count(projectile_type: ProjectileType)->int:
	var state = projectile_storage.get(projectile_type, null) 
	return state.count if state != null else 0

func get_current_ammo_type()->ProjectileType:
	return current_ammo_type
