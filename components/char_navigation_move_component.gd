extends Node2D
class_name CharNavigationMoveComponent

@onready var parent: CharacterBody2D = get_parent()
@onready var nav2d:NavigationAgent2D = $NavigationAgent2D

@export var speed = 40.0

signal send_moving_state(is_moving:bool)

var _target_position: Vector2 = Vector2.ZERO
var _is_moving: bool = false
var _enable:bool = true

func _ready() -> void:
	assert(parent != null, "CharNavigationMoveComponent: parent must be assigned")
	Logi.info("CharNavigationMoveComponent: tank {0}".format([parent.name]))
	
func _physics_process (_delta: float) -> void:
	if not _is_moving or _enable == false:
		return
	navigate_safe()
	
func move(global_target_point:Vector2, _speed:float = 200)->bool:
	if parent.global_position.distance_to(global_target_point) > 5 and _enable == true:
		nav2d.target_position = global_target_point
		_target_position = global_target_point
		speed = _speed
		Logi.debug("CharNavigationMoveComponent: tank {0}, move to {1}".format([parent.name, global_target_point]))
		send_moving_state.emit(true)
		navigate_safe()
		_is_moving = true
		return true
	return false
		
func navigate_safe():
	if nav2d.is_navigation_finished():
		send_moving_state.emit(false)
		return
	var next_path_position = nav2d.get_next_path_position()
	var new_velocity = global_position.direction_to(next_path_position) * speed
	nav2d.velocity = new_velocity
	if parent != null:
		parent.velocity = new_velocity
		parent.rotation = lerp_angle(parent.rotation, parent.velocity.angle(), 0.01)

func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	if _enable == true:
		if safe_velocity == Vector2.ZERO:
			navigate_safe()
		else:
			parent.velocity = safe_velocity
			parent.move_and_slide()
			parent.rotation = lerp_angle(parent.rotation, parent.velocity.angle(), 0.01)
		_handle_stuck_situation()
		
func stop():
	_enable = false
	if parent != null:
		parent.velocity = Vector2.ZERO
		nav2d.velocity = Vector2.ZERO
		Logi.debug("CharNavigationMoveComponent: tank {0}, stop".format([parent.name]))
	
		
func _handle_stuck_situation():
	if not _is_moving:
		return
	
	# Если скорость низкая слишком долго
	if parent.velocity.length() < speed * 0.1:
		parent.rotation += lerp_angle(deg_to_rad(5), parent.velocity.angle(), 0.03)
		_update_navigation_path()
		
func _update_navigation_path():
	nav2d.target_position = _target_position
