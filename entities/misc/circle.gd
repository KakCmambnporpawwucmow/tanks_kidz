extends Node2D

class_name CircleDrawer

@export var radius: float = 50.0
#@export var color: Color = Color.YELLOW
@export var outline_color: Color = Color.GREEN
@export var outline_width: float = 2.0

func _draw():
	#draw_circle(Vector2.ZERO, radius, color)
	if outline_width > 0:
		draw_arc(Vector2.ZERO, radius, 0, TAU, 32, outline_color, outline_width)
