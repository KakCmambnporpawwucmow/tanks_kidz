# projectile.gd
extends RigidBody2D
class_name Projectile

@export_group("Projectile Settings")
@export var initial_speed: float = 300.0
@export var max_travel_distance: float = 1000.0
@export var payload_damage: float = 30.0
@export var show_trajectory: bool = true  # Показывать ли траекторию для отладки

@export_group("Dependencies")
@export var armor_component: ArmorComponent = null
@export var health_component: HealthComponent = null

@export_group("Projectile describe")
@export var describe:String

@onready var visible_notifier = $VisibleOnScreenNotifier2D

var start_position: Vector2
var distance_traveled: float = 0.0
var original_direction: Vector2  # Исходное направление без рассеивания

func _ready():
	assert(armor_component != null, "Projectile: ArmorComponent must be assigned")
	assert(health_component != null, "Projectile: HealthComponent must be assigned")
	
	armor_component.set_payload_damage(payload_damage)
	
	health_component.death.connect(_on_death)
	visible_notifier.screen_exited.connect(_on_screen_exited)

func activate(fire_position: Vector2, fire_direction: Vector2):
	global_position = fire_position
	global_rotation = fire_direction.angle()
	start_position = global_position
	original_direction = fire_direction
	
	linear_velocity = fire_direction * initial_speed
	
	# Визуализация траектории для отладки
	if show_trajectory and Engine.is_editor_hint():
		draw_trajectory_debug()

func _physics_process(delta):
	distance_traveled = global_position.distance_to(start_position)
	
	if distance_traveled >= max_travel_distance:
		health_component.take_damage(health_component.max_health)

func _on_death():
	create_destruction_effects()
	queue_free()

func _on_screen_exited():
	health_component.take_damage(health_component.max_health)

func create_destruction_effects():
	print("Projectile destroyed at distance: ", distance_traveled)

# Визуализация траектории для отладки рассеивания
func draw_trajectory_debug():
	var line = Line2D.new()
	line.width = 2
	line.default_color = Color.YELLOW
	line.add_point(Vector2.ZERO)
	line.add_point(original_direction * 100)
	get_parent().add_child(line)
