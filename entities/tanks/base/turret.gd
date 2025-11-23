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
var aim_position: Vector2 = Vector2.ZERO

@onready var aim:Sprite2D = $CrosshairSprite
@onready var mark:Marker2D = $Marker2D

func _ready() -> void:
	assert(mover != null, "Turret: BaseMoveComponent must be assigned")
	last_position = global_position
	$AnimationPlayer.active = true

func _process(delta):
	check_movement()

func check_movement():
	# Проверяем движение по изменению позиции
	if global_position.distance_to(last_position) > movement_threshold:
		mover.smooth_look_at(aim_position)
		aim.update_position(aim_position)
		last_position = global_position

# Получить направление выстрела с учетом рассеивания
func get_fire_direction() -> Vector2:
	var distance_to_aim = global_position.distance_to(aim.global_position)
	var distance_to_mark = global_position.distance_to(mark.global_position)
	# Не стреляем если есть риск попасть по себе
	if distance_to_mark > distance_to_aim:
		return Vector2.ZERO
		
	var current_spread = static_spread * aim.get_spread_norm()
	var spread_position = aim.global_position + Vector2(randf_range(-current_spread, current_spread), randf_range(-current_spread, current_spread))
	# При стрельбе вупор рассеивание не играет роли, убираем его.
	if distance_to_aim < distance_to_mark * 2:
		spread_position = aim.global_position
	return mark.global_position.direction_to(spread_position).normalized()

# Получить позицию выстрела (может быть немного случайной для реализма)
func get_fire_position() -> Vector2:
	return mark.global_position
	
func fire_effect():
	$AnimationPlayer.play("fire")
	
func update_position(position:Vector2):
	aim_position = position
	mover.smooth_look_at(aim_position)
	aim.update_position(aim_position)
