extends Node2D
class_name CharNavigationMoveComponent

@onready var parent: CharacterBody2D = get_parent()
@onready var nav2d:NavigationAgent2D = $NavigationAgent2D

@export var speed = 40.0

func _ready() -> void:
	set_physics_process(false)
	
func _physics_process (_delta: float) -> void:
	navigate_safe()
	
func move(target_point:Vector2, _speed:float):
	if nav2d.target_position.distance_to(target_point) > 5:
		nav2d.target_position = target_point
		speed = _speed
		set_physics_process(true)
		
func navigate_safe():
	if nav2d.is_navigation_finished():
		set_physics_process(false)
		return
	var next_path_position = nav2d.get_next_path_position()
	var new_velocity = global_position.direction_to(next_path_position) * speed
	nav2d.velocity = new_velocity
	if parent != null:
		parent.rotation = lerp_angle(parent.rotation, parent.velocity.angle(), 0.05)
		parent.move_and_slide()

func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	if parent != null:
		parent.velocity = safe_velocity
