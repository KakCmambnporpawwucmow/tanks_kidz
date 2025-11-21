# projectile.gd
extends RigidBody2D
class_name Projectile

@export_group("Projectile Settings")
@export var initial_speed: float = 300.0
@export var show_trajectory: bool = true  # Показывать ли траекторию для отладки

@export_group("Dependencies")
@export var armor_component: ArmorComponent = null
@export var health_component: HealthComponent = null

@export_group("Projectile describe")
@export var describe:String

@onready var visible_notifier = $VisibleOnScreenNotifier2D

var _start_position: Vector2
var _distance_traveled: float = 0.0
var _original_direction: Vector2  # Исходное направление без рассеивания
var _damage:int = 0

func _ready():
	assert(armor_component != null, "Projectile: ArmorComponent must be assigned")
	assert(health_component != null, "Projectile: HealthComponent must be assigned")
	$PenetrationMarker.visible = false
	
func set_damage(damage:int):
	_damage = damage
	
func activate(fire_position: Vector2, fire_direction: Vector2):
	global_position = fire_position
	global_rotation = fire_direction.angle()
	_start_position = global_position
	_original_direction = fire_direction
	
	linear_velocity = fire_direction * initial_speed
	
	# Визуализация траектории для отладки
	if show_trajectory and Engine.is_editor_hint():
		draw_trajectory_debug()

func _physics_process(delta):
	if linear_velocity < _original_direction * 200:
		on_death()

func on_death():
	set_physics_process(false)
	linear_velocity = Vector2.ZERO
	$view.visible = false
	create_destruction_effects()
	if _damage > 0:
		$PenetrationMarker/Label.text = str(_damage)
		$AnimationPlayer.play("view_damage")
	else:
		queue_free()

func create_destruction_effects():
	print("Projectile destroyed at distance: ", _distance_traveled)

# Визуализация траектории для отладки рассеивания
func draw_trajectory_debug():
	var line = Line2D.new()
	line.width = 2
	line.default_color = Color.YELLOW
	line.add_point(Vector2.ZERO)
	line.add_point(_original_direction * 100)
	get_parent().add_child(line)

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	queue_free()

func _on_armor_component_damage_done(damage: int) -> void:
	_damage = damage

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
