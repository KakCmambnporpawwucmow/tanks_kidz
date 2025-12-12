# tank.gd
extends CharacterBody2D

class_name Tank

@export_group("Components")
@export var _turret: Turret = null
@export var _move_component: BaseMoveComponent = null
@export var _health_component: HealthComponent = null
@export var _weapon_system: WeaponSystem = null

@export_group("Dependencies")
@export var _death_holder: PackedScene = null

enum ERotate{LEFT, RIGHT, STOP}

var is_move:bool = false
var is_rotate:bool = false
var is_death:bool = false

func _ready():
	assert(_turret != null, "Tank: Turret must be assigned")
	assert(_move_component != null, "Tank: BaseMoveComponent must be assigned")
	assert(_health_component != null, "Tank: HealthComponent must be assigned")
	assert(_weapon_system != null, "Tank: WeaponSystem must be assigned")
	
	# Подключаем сигналы здоровья
	_health_component.health_changed.connect(_on_health_changed)
	_health_component.death.connect(_on_death)
	$engine.playing = true
	var trace = $trace
	remove_child(trace)
	get_parent().call_deferred("add_child", trace)

func proc_command(command:Command):
	if is_death == false:
		command.execute(self)

func move(dir:Vector2):
	var speed = _move_component.move(dir)
	is_move = true if dir != Vector2.ZERO else false
	
	if is_move || is_rotate:
		$engine.pitch_scale = 1.5
	else:
		$engine.pitch_scale = 1.0
	return speed
		
func rotating(_rotate:ERotate):
	match _rotate:
		ERotate.LEFT:
			_move_component.rotate_left()
			is_rotate = true
		ERotate.RIGHT:
			_move_component.rotate_right()
			is_rotate = true
		ERotate.STOP:
			_move_component.rotate_stop()
			is_rotate = false
	if is_move || is_rotate:
		$engine.pitch_scale = 1.5
	else:
		$engine.pitch_scale = 1.0

func fire()->bool:
	var fire_direction = _turret.get_fire_direction()
	if fire_direction == Vector2.ZERO:
		print("Cannot fire to direction ", fire_direction)
		return false
	var success = _weapon_system.fire_projectile(_turret.get_fire_position(), _turret.get_fire_direction())
	if success:
		_turret.fire_effect()
		_turret.CD_indicator(_weapon_system.reload_time_ms)
		return true
	return false

func switch_ammo_type(new_type: WeaponSystem.ProjectileType)->bool:
	if _weapon_system.get_proj_count(new_type) > 0:
		_weapon_system.switch_ammo_type(new_type)
		print("Switched to: ", _weapon_system.get_projectile_name(new_type))
		return true
	else:
		print("Cannot switch to ", _weapon_system.get_projectile_name(new_type), " - out of ammo")
	return false

func rotating_to(_position:Vector2):
	_turret.update_position(_position)

func reload_all_ammo():
	print("Tank fully reloaded!")

# Методы для обработки здоровья
func _on_health_changed(new_health: float):
	print("Tank health changed to", new_health)

func _on_damage_taken(amount: float, _source: Node):
	print("Tank damage taken ", amount)

func _on_death():
	is_death = true
	print("Tank destroyed!")
	$animation.play("death")

func get_health_status() -> Dictionary:
	return {
		"current_health": _health_component.get_current_health(),
		"max_health": _health_component.max_health,
		"health_percentage": _health_component.get_health_percentage()
	}

func _on_animation_animation_finished(_anim_name: StringName) -> void:
	var death_holder_imp = _death_holder.instantiate()
	death_holder_imp.global_position = global_position
	get_parent().add_child(death_holder_imp)
	queue_free()

func get_health()->HealthComponent:
	return _health_component
	
func get_weapon_system():
	return _weapon_system
		
