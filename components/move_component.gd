extends Node

class_name MoveComponent

@export var rotation_speed: float = 2.0  # Скорость поворота
@export var moving_straight_speed:float = 20 # скорость по прямой
@onready var parent:Node2D = get_parent()
@export var move_direction: Vector2
@export var start_move_direction: Vector2

var is_rotating_to: bool = false
var is_rotating: bool = false
var is_moving_straight:bool = false
var target_angle: float = 0.0
var _target_position:Vector2 = Vector2.ZERO

func smooth_look_at(target_position: Vector2):
	_target_position = target_position
	is_rotating_to = true
	
func rotate_left():
	target_angle = -rotation_speed
	is_rotating = true
	
func rotate_right():
	target_angle = rotation_speed
	is_rotating = true
	
func rotate_stop():
	target_angle = 0
	is_rotating = false
	
func move_forward():
	start_move_direction = Vector2.UP
	move_direction = start_move_direction.rotated(parent.global_rotation)
	is_moving_straight = true
	
func move_back():
	start_move_direction = Vector2.DOWN
	move_direction = start_move_direction.rotated(parent.global_rotation)
	is_moving_straight = true
	
func move_stop():
	move_direction = Vector2.ZERO
	is_moving_straight = false

func _process(delta):
	if is_rotating_to:
		# Плавная интерполяция угла
		var target_global_angle = (_target_position - parent.global_position).angle()
		parent.global_rotation = rotate_toward(parent.global_rotation, target_global_angle, rotation_speed * delta)
		# Проверка завершения поворота (с небольшой погрешностью)
		if abs(parent.global_rotation - target_global_angle) < 0.01:
			parent.global_rotation = target_global_angle
			is_rotating_to = false
		move_direction = start_move_direction.rotated(parent.global_rotation)
			
	if is_rotating:
		parent.rotation += target_angle * delta
		move_direction = start_move_direction.rotated(parent.global_rotation)
		
	if is_moving_straight:
		parent.position += move_direction * moving_straight_speed * delta

	
		
