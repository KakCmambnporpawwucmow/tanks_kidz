# tank.gd
extends Area2D

class_name Tank

@export_group("Components")
@export var turret: Turret = null
@export var move_component: BaseMoveComponent = null
@export var health_component: HealthComponent = null
@export var weapon_system: WeaponSystem = null

@export_group("Armor Components")
@export var front_armor: ArmorComponent = null
@export var rear_armor: ArmorComponent = null
@export var left_armor: ArmorComponent = null
@export var right_armor: ArmorComponent = null

enum ERotate{LEFT, RIGHT, STOP}

var current_ammo_type: WeaponSystem.ProjectileType = WeaponSystem.ProjectileType.AP
var is_move:bool = false
var is_rotate:bool = false

func _ready():
	assert(turret != null, "Tank: Turret must be assigned")
	assert(move_component != null, "Tank: BaseMoveComponent must be assigned")
	assert(health_component != null, "Tank: HealthComponent must be assigned")
	assert(weapon_system != null, "Tank: WeaponSystem must be assigned")
	
	# Подключаем сигналы здоровья
	health_component.health_changed.connect(_on_health_changed)
	health_component.damage_taken.connect(_on_damage_taken)
	health_component.death.connect(_on_death)
	
	# Подключаем сигналы брони
	var armor_components = [front_armor, rear_armor, left_armor, right_armor]
	for armor_component in armor_components:
		if armor_component:
			armor_component.armor_penetrated.connect(_on_armor_penetrated.bind(armor_component))
			armor_component.armor_ricochet.connect(_on_armor_ricochet.bind(armor_component))
			
	$engine.playing = true

func proc_command(command:Command):
	command.execute(self)

func move(dir:Vector2):
	move_component.move(dir)
	is_move = true if dir != Vector2.ZERO else false
	
	if is_move || is_rotate:
		$engine.pitch_scale = 1.5
	else:
		$engine.pitch_scale = 1.0
		
func rotating(rotate:ERotate):
	match rotate:
		ERotate.LEFT:
			move_component.rotate_left()
			is_rotate = true
		ERotate.RIGHT:
			move_component.rotate_right()
			is_rotate = true
		ERotate.STOP:
			move_component.rotate_stop()
			is_rotate = false
	if is_move || is_rotate:
		$engine.pitch_scale = 1.5
	else:
		$engine.pitch_scale = 1.0

func fire():
	var success = weapon_system.fire_projectile(current_ammo_type, turret.get_fire_position(), turret.get_fire_direction())
	if success:
		turret.fire_effect()
		print("Fired ", get_ammo_type_name(), " round")
	else:
		print("Cannot fire - reloading or out of ammo")

func switch_ammo_type(new_type: WeaponSystem.ProjectileType):
	if weapon_system.get_remaining_ammo(new_type) > 0:
		current_ammo_type = new_type
		print("Switched to: ", get_ammo_type_name())
	else:
		print("Cannot switch to ", weapon_system.get_projectile_name(new_type), " - out of ammo")

func rotating_turret_to(position:Vector2):
	turret.update_position(position)

# Новый метод для получения полной информации о точности
func get_accuracy_info() -> Dictionary:
	#var spread_info = turret.get_spread_info()
	var health_status = get_health_status()
	
	return {
		#"spread_percentage": spread_info.spread_percentage,
		#"spread_angle": spread_info.spread_angle,
		#"accuracy": spread_info.accuracy,
		"is_move": is_move,
		"is_fully_accurate": turret.is_fully_accurate(),
		"health_effect": health_status.health_percentage  # Здоровье может влиять на точность
	}

func get_ammo_type_name() -> String:
	return weapon_system.get_projectile_name(current_ammo_type)

func get_remaining_ammo() -> int:
	return weapon_system.get_remaining_ammo(current_ammo_type)

func reload_all_ammo():
	weapon_system.reload_ammo(WeaponSystem.ProjectileType.AP, 10)
	weapon_system.reload_ammo(WeaponSystem.ProjectileType.HE, 5)
	weapon_system.reload_ammo(WeaponSystem.ProjectileType.HEAT, 3)
	weapon_system.reload_ammo(WeaponSystem.ProjectileType.MISSILE, 1)
	print("Tank fully reloaded!")

# Методы для обработки здоровья
func _on_health_changed(new_health: float):
	print("Tank {0} health: {1} / {2}".format([name, new_health, health_component.max_health]))

func _on_damage_taken(amount: float, source: Node):
	print("Tank {0} took {1}, damage from {2}".format([name, amount, source.name if source else "unknown"]))

func _on_death():
	print("Tank destroyed!")
	queue_free()

# Методы для обработки брони
func _on_armor_penetrated(penetrator: ArmorComponent, total_damage: float, armor_component: ArmorComponent):
	var armor_location = get_armor_location_name(armor_component)
	print("Tank {0}, {1} armor penetrated! Damage: {2}".format([name, armor_location, total_damage]))
	create_armor_penetration_effects(armor_location)

func _on_armor_ricochet(hit_angle: float, armor_component: ArmorComponent):
	var armor_location = get_armor_location_name(armor_component)
	print("Tank ", armor_location, " armor ricochet! Angle: ", hit_angle)
	create_ricochet_effects(armor_location)

func get_armor_location_name(armor_component: ArmorComponent) -> String:
	if armor_component == front_armor:
		return "front"
	elif armor_component == rear_armor:
		return "rear"
	elif armor_component == left_armor:
		return "left"
	elif armor_component == right_armor:
		return "right"
	else:
		return "unknown"

func create_armor_penetration_effects(armor_location: String):
	# Эффекты пробития брони (искры, дым, звук) в зависимости от локации
	match armor_location:
		"front":
			# Эффекты для передней брони
			pass
		"rear":
			# Эффекты для задней брони
			pass
		"left", "right":
			# Эффекты для боковой брони
			pass

func create_ricochet_effects(armor_location: String):
	# Эффекты рикошета (искры, звук) в зависимости от локации
	match armor_location:
		"front":
			# Эффекты рикошета от передней брони
			pass
		"rear":
			# Эффекты рикошета от задней брони
			pass
		"left", "right":
			# Эффекты рикошета от боковой брони
			pass

func get_health_status() -> Dictionary:
	return {
		"current_health": health_component.get_current_health(),
		"max_health": health_component.max_health,
		"health_percentage": health_component.get_health_percentage()
	}

# Методы для получения информации о броне
func get_armor_status() -> Dictionary:
	return {
		"front_armor": front_armor.get_durability_percentage() if front_armor else 0.0,
		"rear_armor": rear_armor.get_durability_percentage() if rear_armor else 0.0,
		"left_armor": left_armor.get_durability_percentage() if left_armor else 0.0,
		"right_armor": right_armor.get_durability_percentage() if right_armor else 0.0
	}

# Метод для получения общей информации о танке
func get_tank_status() -> Dictionary:
	var status = get_health_status()
	status["armor"] = get_armor_status()
	status["current_ammo_type"] = get_ammo_type_name()
	status["remaining_ammo"] = get_remaining_ammo()
	return status
