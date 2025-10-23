extends Node

class_name MoveComponent

@export var rotation_speed: float = 2.0  # Скорость поворота
@onready var parent:Node2D = get_parent()

var is_rotating_to: bool = false
var target_angle: float = 0.0
var is_rotating: bool = false
var _target_position:Vector2 = Vector2.ZERO

func smooth_look_at(target_position: Vector2):
	_target_position = target_position
	is_rotating_to = true
	print("Info. Turn smooth_look_at.")
	
func rotate_left():
	target_angle = -rotation_speed
	is_rotating = true
	print("Info. Turn left.")
	
func rotate_right():
	target_angle = rotation_speed
	is_rotating = true
	print("Info. Turn right.")
	
func rotate_stop():
	target_angle = 0
	is_rotating = false
	print("Info. Turn stop.")

func _process(delta):
	if is_rotating_to:
		
		# Плавная интерполяция угла
		var target_global_angle = (_target_position - parent.global_position).angle()
		parent.global_rotation = rotate_toward(parent.global_rotation, target_global_angle, rotation_speed * delta)
		# Проверка завершения поворота (с небольшой погрешностью)
		if abs(parent.global_rotation - target_global_angle) < 0.01:
			parent.global_rotation = target_global_angle
			is_rotating_to = false
	if is_rotating:
		parent.rotation += target_angle * delta
