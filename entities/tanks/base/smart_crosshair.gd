extends Node2D

@export var move_time: float = 1.0
@export var min_scale: Vector2 = Vector2(0.3, 0.3)
@export var max_scale: Vector2 = Vector2(1.0, 1.0)
@export var scale_time: float = 1.0
@export var unscale_time: float = 2.0
var tween_move:Tween = null
var delta_scale = max_scale.x - min_scale.x
var last_position:Vector2 = Vector2.ZERO

func _input(event):
	if event is InputEventMouseMotion:
		update_position()

func move(distance:int):
	if tween_move != null && tween_move.is_valid():
		tween_move.kill()
	tween_move = create_tween()
	tween_move.tween_property(self, "position", Vector2(distance, 0), move_time)
	tween_move.parallel().tween_property(self, "scale", max_scale, scale_time)
	tween_move.tween_property(self, "scale", min_scale, unscale_time)
	tween_move.set_ease(Tween.EASE_IN_OUT)
	
func get_spread_norm()->float:
	return (scale.x - min_scale.x) / delta_scale

func update_position(position:Vector2 = Vector2.ZERO):
	if position == Vector2.ZERO:
		position = last_position
	else:
		last_position = position
	move(get_parent().global_position.distance_to(position))
