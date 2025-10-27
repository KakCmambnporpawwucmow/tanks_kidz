extends Area2D

@onready var move_component = $AreaMoveComponent

func _input(event):
	# Одиночные нажатия
	if Input.is_action_just_pressed("ui_turn_left"):
		move_component.rotate_left()
	if Input.is_action_just_released("ui_turn_left") or Input.is_action_just_released("ui_turn_right"):
		move_component.rotate_stop()
	if Input.is_action_just_pressed("ui_turn_right"):
		move_component.rotate_right()
		
	if Input.is_action_just_pressed("ui_forward"):
		move_component.move_forward()
	if Input.is_action_just_released("ui_forward") or Input.is_action_just_released("ui_back"):
		move_component.move_stop()
	if Input.is_action_just_pressed("ui_back"):
		move_component.move_back()
