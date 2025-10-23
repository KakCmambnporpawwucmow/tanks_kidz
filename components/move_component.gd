extends Node

class_name MoveComponent

@export var rotation_speed: float = 2.0  # Скорость поворота
@onready var parent:Node2D = get_parent()

var is_rotating: bool = false
var target_angle: float = 0.0

func smooth_look_at(target_position: Vector2):
	var direction = target_position - parent.global_position
	target_angle = direction.angle()
	is_rotating = true

func _process(delta):
	if is_rotating:
		# Плавная интерполяция угла
		parent.rotation = lerp_angle(parent.rotation, target_angle, rotation_speed * delta)
		
		# Проверка завершения поворота (с небольшой погрешностью)
		if abs(parent.rotation - target_angle) < 0.01:
			parent.rotation = target_angle
			is_rotating = false
