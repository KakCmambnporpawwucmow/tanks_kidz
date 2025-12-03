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

var is_move:bool = false
var is_rotate:bool = false
var is_death:bool = false

func _ready():
	assert(turret != null, "Tank: Turret must be assigned")
	assert(move_component != null, "Tank: BaseMoveComponent must be assigned")
	assert(health_component != null, "Tank: HealthComponent must be assigned")
	assert(weapon_system != null, "Tank: WeaponSystem must be assigned")
	
	# Подключаем сигналы здоровья
	health_component.health_changed.connect(_on_health_changed)
	health_component.death.connect(_on_death)
	$engine.playing = true
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
	var success = weapon_system.fire_projectile(turret.get_fire_position(), turret.get_fire_direction())
	if success:
		turret.fire_effect()
		turret.CD_indicator(weapon_system.reload_time_ms)
		return true
	return false

func switch_ammo_type(new_type: WeaponSystem.ProjectileType)->bool:
	if weapon_system.get_proj_count(new_type) > 0:
		weapon_system.switch_ammo_type(new_type)
		print("Switched to: ", weapon_system.get_projectile_name(new_type))
		return true
	else:
		print("Cannot switch to ", weapon_system.get_projectile_name(new_type), " - out of ammo")
	return false

func rotating_to(position:Vector2):
	turret.update_position(position)

func reload_all_ammo():
	weapon_system.reload_ammo(WeaponSystem.ProjectileType.AP, 10)
	weapon_system.reload_ammo(WeaponSystem.ProjectileType.HE, 5)
	weapon_system.reload_ammo(WeaponSystem.ProjectileType.HEAT, 3)
	weapon_system.reload_ammo(WeaponSystem.ProjectileType.MISSILE, 1)
	print("Tank fully reloaded!")

# Методы для обработки здоровья
func _on_health_changed(new_health: float):
	pass

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

func _on_animation_animation_finished(anim_name: StringName) -> void:
	var death_holder_imp = death_holder.instantiate()
	death_holder_imp.global_position = global_position
	get_parent().add_child(death_holder_imp)
	queue_free()

func get_health()->HealthComponent:
	return health_component
		
