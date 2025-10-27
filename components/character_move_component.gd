# character_move_component.gd
class_name CharacterMoveComponent
extends BaseMoveComponent

@export_category("CharacterBody2D Settings")
@export var use_snap: bool = true
@export var stop_on_slope: bool = true

var character_body: CharacterBody2D

func _ready():
	character_body = parent as CharacterBody2D
	assert(character_body != null, "CharacterMoveComponent requires CharacterBody2D parent")

func _apply_movement(movement: Vector2):
	# Для CharacterBody2D используем velocity и move_and_slide
	if is_moving_straight:
		character_body.velocity = current_velocity
	else:
		character_body.velocity = current_velocity
	
	if use_snap and character_body.is_on_floor():
		character_body.move_and_slide()
	else:
		character_body.move_and_slide()

func _stop_physics_body():
	character_body.velocity = Vector2.ZERO

func is_on_floor() -> bool:
	return character_body.is_on_floor()

func is_on_wall() -> bool:
	return character_body.is_on_wall()
