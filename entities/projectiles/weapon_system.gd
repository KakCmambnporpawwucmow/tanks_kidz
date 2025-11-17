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
@export var ap_round: Projectile = null
@export var he_round: Projectile = null
@export var heat_round: Projectile = null
@export var missile_round: Projectile = null

@export_group("Spawn Settings")
@export var projectiles_parent: Node = null

@export_group("Weapon Properties")
@export var reload_time_ms: int = 2000  # Время перезарядки в миллисекундах

@export_group("Ammunition")
@export var initial_ap_rounds: int = 20
@export var initial_he_rounds: int = 10
@export var initial_heat_rounds: int = 5
@export var initial_missile_rounds: int = 2

class ProjectileState:
	var projectile:Projectile = null
	var count:int = 0
	var max_load:int = 0
	func _init(_projectile:Projectile, _count:int) -> void:
		projectile = _projectile
		count = _count
		max_load = _count

# Хранилище боеприпасов
var projectile_storage: Dictionary = {}
var last_reload_time: int = 0

func _ready():
	# Инициализация боеприпасов из настроек редактора
	projectile_storage[ProjectileType.AP] = ProjectileState.new(ap_round, initial_ap_rounds)
	projectile_storage[ProjectileType.HE] = ProjectileState.new(he_round, initial_he_rounds)
	projectile_storage[ProjectileType.HEAT] = ProjectileState.new(heat_round, initial_heat_rounds)
	projectile_storage[ProjectileType.MISSILE] = ProjectileState.new(missile_round, initial_missile_rounds)
	print("WeaponSystem initialized")

# Основные методы стрельбы
func fire_projectile(projectile_type: ProjectileType, position: Vector2, direction: Vector2) -> bool:
	if not can_fire(projectile_type):
		return false
	
	var projectile = get_projectile_instance(projectile_type)
	if projectile == null:
		push_error("WeaponSystem: No projectile instance assigned for type: ", get_projectile_name(projectile_type))
		return false

	# Создаем копию снаряда и настраиваем
	if not setup_projectile(projectile, position, direction):
		projectile.queue_free()
		return false
	
	# Расходуем боеприпасы и обновляем таймеры
	consume_ammo(projectile_type)
	# Запускаем перезарядку
	last_reload_time = Time.get_ticks_msec()
	print("Fired ", get_projectile_name(projectile_type), " round")
	
	return true

func get_projectile_instance(projectile_type: ProjectileType) -> Projectile:
	if projectile_storage[projectile_type].projectile != null:
		return projectile_storage[projectile_type].projectile.duplicate()
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
		print("Error. No projectile with type ", get_projectile_name(projectile_type))
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
		return proj_state.projectile.describe
	return "Unknown"
