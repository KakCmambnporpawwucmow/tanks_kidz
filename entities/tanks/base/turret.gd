# turret.gd
extends Node2D
class_name Turret

@export_group("Turret Settings")
@export var mover: BaseMoveComponent = null
@export var movement_threshold: float = 10.0  # Порог скорости для рассеивания
@export var static_spread:int = 150
@export var hide_crosshair:bool = false:
	set(value):
		hide_crosshair = value
		if value:
			$CrosshairSprite.modulate = Color(1,1,1,0)
		else:
			$CrosshairSprite.modulate = Color(1,1,1,1)

var current_aim_position: Vector2 = Vector2.ZERO
var is_moving: bool = false
var last_position: Vector2 = Vector2.ZERO
var aim_position: Vector2 = Vector2.ZERO

@onready var aim:Sprite2D = $CrosshairSprite
@onready var mark:Marker2D = $Marker2D
@onready var cd_ind:TextureProgressBar = $CrosshairSprite/CD_progress
@onready var cd_ind2:TextureProgressBar = $CrosshairSprite/CD_progress2

signal send_ready_to_fire()

func _ready() -> void:
	assert(mover != null, "Turret: BaseMoveComponent must be assigned")
	last_position = global_position
	$AnimationPlayer.active = true

func _process(_delta):
	check_movement()

func check_movement():
	# Проверяем движение по изменению позиции
	if global_position.distance_to(last_position) > movement_threshold:
		mover.smooth_look_at(aim_position)
		aim.update_position(aim_position)
		last_position = global_position
		if (aim_position - aim.global_position).length() < 20:
			send_ready_to_fire.emit()

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
	cd_ind.value = 0
	cd_ind2.value = 0
	return mark.global_position.direction_to(spread_position).normalized()

# Получить позицию выстрела (может быть немного случайной для реализма)
func get_fire_position() -> Vector2:
	return mark.global_position
	
func fire_effect():
	$AnimationPlayer.play("fire")
	
func update_position(_position:Vector2):
	aim_position = _position
	mover.smooth_look_at(aim_position)
	aim.update_position(aim_position)
	
func CD_indicator(cooldown_time_ms:float):
	if cd_ind.max_value == 0:
		cd_ind.max_value = cooldown_time_ms
		cd_ind2.max_value = cooldown_time_ms
	cd_ind.value = 0
	cd_ind2.value = 0
	var tween = create_tween()
	tween.tween_property(cd_ind, "value", cooldown_time_ms, cooldown_time_ms / 1000)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween = create_tween()
	tween.tween_property(cd_ind2, "value", cooldown_time_ms, cooldown_time_ms / 1000)
	tween.set_ease(Tween.EASE_IN_OUT)
