# turret.gd
extends Node2D
class_name Turret

@export_group("Turret Settings")
@export var mover: BaseMoveComponent = null
@export var movement_threshold: float = 10.0  # Порог скорости для рассеивания
@export var static_spread:int = 150


var current_aim_position: Vector2 = Vector2.ZERO
var is_moving: bool = false
var last_position: Vector2 = Vector2.ZERO

@onready var aim:Sprite2D = $CrosshairSprite

func _ready() -> void:
	assert(mover != null, "Turret: BaseMoveComponent must be assigned")
	last_position = global_position

func _process(delta):
	check_movement()

func _input(event):
	if event is InputEventMouseMotion:
		mover.smooth_look_at(get_global_mouse_position())
		aim.update_position()

func check_movement():
	# Проверяем движение по изменению позиции
	if global_position.distance_to(last_position) > movement_threshold:
		mover.smooth_look_at(get_global_mouse_position())
		aim.update_position()
		last_position = global_position

# Получить направление выстрела с учетом рассеивания
func get_fire_direction() -> Vector2:
	var current_spread = static_spread * aim.get_spread_norm()
	var spread_position = aim.global_position + Vector2(randf_range(-current_spread, current_spread), randf_range(-current_spread, current_spread))
	print("Curr spread {0}, spread_position {1}, aim.global_position {2}".format([current_spread, spread_position, aim.global_position]))
	return (spread_position - global_position).normalized()

# Получить позицию выстрела (может быть немного случайной для реализма)
func get_fire_position() -> Vector2:
	return $Marker2D.global_position
