# tank.gd
extends CharacterBody2D

class_name Tank

@export_group("Components")
@export var _turret: Turret = null
@export var _move_component: BaseMoveComponent = null
@export var _health_component: HealthComponent = null
@export var _weapon_system: WeaponSystem = null
@export var _nav_component:CharNavigationMoveComponent = null
@export var _ai_crew:AICrew = null

@export_group("Dependencies")
@export var _death_holder: PackedScene = null

@export_group("State")

@export var _player_command:EPlayers = EPlayers.ENEMY

enum ERotate{LEFT, RIGHT, STOP}
enum EPlayers{MY, ENEMY}

var is_move:bool = false
var is_rotate:bool = false
var is_death:bool = false
var is_ai_managing:bool = true
var start_time_in_battle:int = 0

func _ready():
	assert(_turret != null, "Tank: Turret must be assigned")
	assert(_move_component != null, "Tank: BaseMoveComponent must be assigned")
	assert(_health_component != null, "Tank: HealthComponent must be assigned")
	assert(_weapon_system != null, "Tank: WeaponSystem must be assigned")
	assert(_nav_component != null, "Tank: CharNavigationMoveComponent must be assigned")
	assert(_ai_crew != null, "Tank: _ai_crew must be assigned")
	
	if _ai_crew.get_enable():
		_turret.hide_crosshair = true
	
	# Подключаем сигналы здоровья
	_health_component.health_changed.connect(_on_health_changed)
	_health_component.death.connect(_on_death)
	_weapon_system.send_ammo_empty.connect(_ai_crew.ammo_empty)
	
	$engine.playing = true
	Logi.info("Tank {0}: initialized".format([name]))

func proc_command(command:Command):
	if is_death == false:
		command.execute(self)
		if is_ai_managing == true and command is MoveCommand:
			_ai_crew.set_enable(false)
			_turret.hide_crosshair = false
			is_ai_managing = false
			_weapon_system.to_statistic = true
			start_time_in_battle = Time.get_ticks_msec()

func move(dir:Vector2):
	var speed = _move_component.move(dir)
	is_move = true if dir != Vector2.ZERO else false
	
	if is_move || is_rotate:
		$engine.pitch_scale = 1.5
	else:
		$engine.pitch_scale = 1.0
	return speed
	
func move_to(pos:Vector2):
	_nav_component.move(pos, _move_component.move_speed)
		
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
		Logi.debug("Tank {0}: Cannot fire to direction {1}".format([name, fire_direction]))
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
		Logi.debug("Tank {0}: Switched to:  {1}".format([name, _weapon_system.get_projectile_name(new_type)]))
		return true
	else:
		Logi.debug("Tank {0}: Cannot switch to:  {1} - out of ammo".format([name, _weapon_system.get_projectile_name(new_type)]))
	return false

func rotating_to(_position:Vector2):
	_turret.update_position(_position)
	
func rotating_tank_to(_position:Vector2):
	_move_component.smooth_look_at(_position)

func reload_all_ammo():
	_weapon_system.reload_all_ammo()

# Методы для обработки здоровья
func _on_health_changed(new_health: float):
	Logi.debug("Tank health changed to {0}".format([new_health]))

func _on_damage_taken(amount: float, _source: Node):
	Logi.debug("Tank {0}: damage taken {1}".format([name, amount]))
	if is_ai_managing == false:
		PlayerState.get_ps().battle_get_damage += amount

func _on_death():
	is_death = true
	Logi.info("Tank {0} destroyed!".format([name]))
	var frag_bar = get_tree().get_first_node_in_group("frag_bar")
	if is_instance_valid(frag_bar) and frag_bar is FragBar:
		frag_bar.frag_count_changed(self)
	else:
		Logi.error("Tank {0}: No frag bar in scene".format([name]))
	$animation.play("death")
	if is_ai_managing == false:
		PlayerState.get_ps().battle_get_frag += 1
		if start_time_in_battle > 0:
			PlayerState.get_ps().battle_time_s += (Time.get_ticks_msec() - start_time_in_battle) / 1000

func get_health_status() -> Dictionary:
	return {
		"current_health": _health_component.get_current_health(),
		"max_health": _health_component.max_health,
		"health_percentage": _health_component.get_health_percentage()
	}

func _on_animation_animation_finished(_anim_name: StringName) -> void:
	var death_holder_imp = _death_holder.instantiate()
	death_holder_imp.global_position = global_position
	get_tree().current_scene.add_child(death_holder_imp)
	queue_free()

func get_health()->HealthComponent:
	return _health_component
	
func get_weapon_system():
	return _weapon_system
		
func get_player_command()->EPlayers:
	return _player_command
	
func set_player_command(player_command:EPlayers):
	_player_command = player_command

func get_nav_component()->CharNavigationMoveComponent:
	return _nav_component
