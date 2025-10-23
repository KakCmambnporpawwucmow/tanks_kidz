extends Node2D

func _input(event):
	# Одиночные нажатия
	if Input.is_action_just_pressed("ui_turn_left"):
		$MoveComponent.rotate_left()
	if Input.is_action_just_released("ui_turn_left"):
		$MoveComponent.rotate_stop()
	if Input.is_action_just_pressed("ui_turn_right"):
		$MoveComponent.rotate_right()
	if Input.is_action_just_released("ui_turn_right"):
		$MoveComponent.rotate_stop()
