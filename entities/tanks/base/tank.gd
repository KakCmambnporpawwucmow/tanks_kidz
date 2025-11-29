# tank.gd
extends CharacterBody2D

class_name Tank

@export_group("Components")
@export var turret: Turret = null
@export var move_component: BaseMoveComponent = null
@export var health_component: HealthComponent = null
@export var weapon_system: WeaponSystem = null

@export_group("Dependencies")
@export var death_holder: PackedScene = null

enum ERotate{LEFT, RIGHT, STOP}

var current_ammo_type: WeaponSystem.ProjectileType = WeaponSystem.ProjectileType.AP
var is_move:bool = false
var is_rotate:bool = false
var is_death:bool = false

func _ready():
	assert(turret != null, "Tank: Turret must be assigned")
	assert(move_component != null, "Tank: BaseMoveComponent must be assigned")
	assert(health_component != null, "Tank: HealthComponent must be assigned")
	assert(weapon_system != null, "Tank: WeaponSystem must be assigned")
	assert(death_holder != null, "Tank: death_holder must be assigned")
	
	# Подключаем сигналы здоровья
	health_component.health_changed.connect(_on_health_changed)
	health_component.death.connect(_on_death)
	
	$engine.playing = true
	$HP_progress.max_value = health_component.max_health
	$HP_progress.value = health_component.max_health
	$ammo_stat.set_ammo_type(current_ammo_type)
	
	var trace = $trace
	remove_child(trace)
	get_parent().call_deferred("add_child", trace)

func proc_command(command:Command):
	if is_death == false:
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

func fire()->bool:
	var fire_direction = turret.get_fire_direction()
	if fire_direction == Vector2.ZERO:
		print("Cannot fire to direction ", fire_direction)
		return false
	var success = weapon_system.fire_projectile(current_ammo_type, turret.get_fire_position(), turret.get_fire_direction())
	if success:
		turret.fire_effect()
		turret.CD_indicator(weapon_system.reload_time_ms)
		if weapon_system.get_proj_count(current_ammo_type) == 0:
			for ammo in WeaponSystem.ProjectileType.values():
				if switch_ammo_type(ammo):
					break
		$ammo_stat.update()
		print("Fired ", get_ammo_type_name(), " round")
	else:
		print("Cannot fire - reloading or out of ammo")
		return false
	return true

func switch_ammo_type(new_type: WeaponSystem.ProjectileType)->bool:
	if weapon_system.get_proj_count(new_type) > 0:
		$ammo_stat.set_ammo_type(new_type)
		current_ammo_type = new_type
		print("Switched to: ", get_ammo_type_name())
		return true
	else:
		print("Cannot switch to ", weapon_system.get_projectile_name(new_type), " - out of ammo")
	return false

func rotating_to(position:Vector2):
	turret.update_position(position)

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
	#print("Tank {0} health: {1} / {2}".format([name, new_health, health_component.max_health]))
	$HP_progress/count.text = "{0}/{1}".format([int(new_health), int(health_component.max_health)])
	var tween = create_tween()
	tween.tween_property($HP_progress, "value", new_health, 1.0)
	tween.set_ease(Tween.EASE_IN_OUT)

func _on_damage_taken(amount: float, source: Node):
	print("Tank {0} took {1}, damage from {2}".format([name, amount, source.name if source else "unknown"]))

func _on_death():
	is_death = true
	print("Tank destroyed!")
	$animation.play("death")

func get_health_status() -> Dictionary:
	return {
		"current_health": health_component.get_current_health(),
		"max_health": health_component.max_health,
		"health_percentage": health_component.get_health_percentage()
	}

# Метод для получения общей информации о танке
func get_tank_status() -> Dictionary:
	var status = get_health_status()
	status["current_ammo_type"] = get_ammo_type_name()
	status["remaining_ammo"] = get_remaining_ammo()
	return status

func _on_animation_animation_finished(anim_name: StringName) -> void:
	var death_holder_imp = death_holder.instantiate()
	death_holder_imp.global_position = global_position
	get_parent().add_child(death_holder_imp)
	queue_free()

#func _process(delta: float) -> void:
	#if $front_check.is_colliding() or $back_check.is_colliding():
		#move(Vector2.ZERO)
		
