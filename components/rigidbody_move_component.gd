# rigidbody_move_component.gd
class_name RigidBodyMoveComponent
extends BaseMoveComponent

@export_category("RigidBody2D Settings")
@export var use_force: bool = true
@export var force_multiplier: float = 100.0
@export var max_force: float = 1000.0

var rigidbody: RigidBody2D = null

func _ready():
	rigidbody = parent as RigidBody2D
	if rigidbody == null:
		Logi.fatal("CharacterMoveComponent {0}: parent {1} has'nt type RigidBody2D.".format([name, parent.name]))
	assert(rigidbody != null, "RigidBodyMoveComponent requires RigidBody2D parent")
	
	# Настройки по умолчанию для RigidBody2D
	rigidbody.gravity_scale = 0.0
	rigidbody.linear_damp = 2.0

func _apply_rotation(rotation_amount: float):
	rigidbody.rotation += rotation_amount

func _apply_movement(movement: Vector2):
	# Для RigidBody2D используем физические силы
	if is_moving_straight:
		var target_velocity = move_direction * move_speed
		if use_force:
			var force = (target_velocity - rigidbody.linear_velocity) * force_multiplier
			force = force.limit_length(max_force)
			rigidbody.apply_central_force(force)
		else:
			# Альтернатива: прямое управление velocity (менее реалистично)
			rigidbody.linear_velocity = rigidbody.linear_velocity.move_toward(
				target_velocity, acceleration * move_speed * get_process_delta_time()
			)
	else:
		# Плавная остановка через демпфирование
		rigidbody.linear_velocity = rigidbody.linear_velocity.move_toward(
			Vector2.ZERO, deceleration * move_speed * get_process_delta_time()
		)
	
	# Обновляем current_velocity для отслеживания состояния
	current_velocity = rigidbody.linear_velocity

func _stop_physics_body():
	rigidbody.linear_velocity = Vector2.ZERO
	rigidbody.angular_velocity = 0.0

func set_gravity_enabled(enabled: bool)->float:
	rigidbody.gravity_scale = 1.0 if enabled else 0.0
	return rigidbody.gravity_scale

func apply_impulse(impulse: Vector2, position: Vector2 = Vector2.ZERO)->Vector2:
	if position == Vector2.ZERO:
		rigidbody.apply_central_impulse(impulse)
	else:
		rigidbody.apply_impulse(impulse, position)
	return rigidbody.linear_velocity
