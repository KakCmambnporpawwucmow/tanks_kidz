# base_move_component.gd
class_name BaseMoveComponent
extends Node

@export_category("Base Movement Settings")
@export var rotation_speed: float = 2.0
@export var move_speed: float = 20.0
@export var acceleration: float = 5.0
@export var deceleration: float = 8.0

@onready var parent: Node2D = get_parent()

var move_direction: Vector2 = Vector2.ZERO
var start_move_direction: Vector2 = Vector2.UP
var current_velocity: Vector2 = Vector2.ZERO

var is_rotating_to: bool = false
var is_rotating: bool = false
var is_moving_straight: bool = false
var target_angle: float = 0.0
var _target_position: Vector2 = Vector2.ZERO

# Сигналы
signal rotation_started()
signal rotation_finished()
signal movement_started()
signal movement_stopped()
signal direction_changed(new_direction: Vector2)

# === Базовые методы управления ===
func smooth_look_at(target_position: Vector2):
	_target_position = target_position
	is_rotating_to = true
	rotation_started.emit()

func rotate_left():
	target_angle = -rotation_speed
	is_rotating = true
	rotation_started.emit()

func rotate_right():
	target_angle = rotation_speed
	is_rotating = true
	rotation_started.emit()

func rotate_stop():
	target_angle = 0
	is_rotating = false
	rotation_finished.emit()
	
func move(direction:Vector2):
	if direction != Vector2.ZERO:
		start_move_direction = direction
		update_movement_direction()
		is_moving_straight = true
		movement_started.emit()
	else:
		is_moving_straight = false
		movement_stopped.emit()

# === Внутренняя логика ===
func update_movement_direction():
	var old_direction = move_direction
	move_direction = start_move_direction.rotated(parent.global_rotation)
	if old_direction != move_direction:
		direction_changed.emit(move_direction)

func _process(delta):
	_process_rotation(delta)
	_process_movement(delta)

func _process_rotation(delta):
	if is_rotating_to:
		_process_rotation_to_target(delta)
	elif is_rotating:
		_process_continuous_rotation(delta)
	
	if (is_rotating_to or is_rotating) and is_moving_straight:
		update_movement_direction()

func _process_rotation_to_target(delta):
	var target_global_angle = (_target_position - parent.global_position).angle()
	var angle_diff = wrapf(target_global_angle - parent.global_rotation, -PI, PI)
	var rotation_step = sign(angle_diff) * min(abs(angle_diff), rotation_speed * delta)
	
	_apply_rotation(rotation_step)
	
	if abs(angle_diff) < 0.01:
		_apply_rotation(target_global_angle - parent.global_rotation)
		is_rotating_to = false
		rotation_finished.emit()

func _process_continuous_rotation(delta):
	_apply_rotation(target_angle * delta)

func _process_movement(delta):
	var target_velocity = Vector2.ZERO
	if is_moving_straight:
		target_velocity = move_direction * move_speed
	
	# Плавное изменение скорости
	if is_moving_straight:
		if current_velocity.length_squared() < 0.1:
			current_velocity = target_velocity * 0.1
		else:
			current_velocity = current_velocity.move_toward(target_velocity, acceleration * move_speed * delta)
	else:
		current_velocity = current_velocity.move_toward(Vector2.ZERO, deceleration * move_speed * delta)
	
	# Применяем движение
	if current_velocity.length_squared() > 0.1:
		_apply_movement(current_velocity * delta)

# === Виртуальные методы для переопределения ===
func _apply_rotation(rotation_amount: float):
	"""Применяет поворот - переопределить в дочерних классах"""
	parent.rotation += rotation_amount

func _apply_movement(movement: Vector2):
	"""Применяет движение - переопределить в дочерних классах"""
	parent.position += movement

func _stop_physics_body():
	"""Останавливает физическое тело - переопределить при необходимости"""
	pass

# === Публичные методы ===
func get_current_direction() -> Vector2:
	return move_direction

func get_current_speed() -> float:
	return current_velocity.length()

func is_moving() -> bool:
	return is_moving_straight and current_velocity.length_squared() > 0.1

func set_movement_speed(speed: float):
	move_speed = speed

func set_rotation_speed(speed: float):
	rotation_speed = speed

func get_forward_direction() -> Vector2:
	return Vector2.UP.rotated(parent.global_rotation)
