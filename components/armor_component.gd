# armor_component.gd
class_name ArmorComponent
extends Area2D

@export_group("Armor Properties")
@export var thickness: float = 50.0  # Толщина брони
@export var hardness: float = 1.2    # Твёрдость брони

@export_group("Collision Settings")
@export var min_impact_speed: float = 50.0  # Минимальная скорость для пробития

@export_group("Dependencies")
@export var health_component: HealthComponent = null

var entity: Node2D
var payload_damage: float = 0.0  # Урон от содержимого (для снарядов)

signal armor_penetrated(penetrator: ArmorComponent, total_damage: float)
signal armor_ricochet(hit_angle: float)

func _ready():
	entity = get_parent()
	
	# Обязательно должен быть назначен HealthComponent
	assert(health_component != null, "ArmorComponent: HealthComponent must be assigned in editor or code")
	
	area_entered.connect(_on_armor_collision)

func set_payload_damage(damage: float):
	"""Устанавливает урон от содержимого (для снарядов)"""
	payload_damage = damage

func _on_armor_collision(other_area: Area2D):
	var other_armor = other_area as ArmorComponent
	if not other_armor:
		return
	
	# Получаем данные о столкновении
	var impact_velocity = calculate_impact_velocity(other_armor)
	var hit_angle = calculate_hit_angle(other_armor)
	
	# Проверяем пробитие
	if check_penetration(other_armor, hit_angle, impact_velocity):
		# Пробитие произошло - обрабатываем пробитие
		handle_penetration(other_armor, hit_angle, impact_velocity)
	else:
		# Рикошет
		handle_ricochet(hit_angle)

func calculate_impact_velocity(other_armor: ArmorComponent) -> float:
	var my_velocity = get_entity_velocity()
	var other_velocity = other_armor.get_entity_velocity()
	var relative_velocity = other_velocity - my_velocity
	
	# Скорость вдоль направления удара
	var collision_direction = (other_armor.global_position - global_position).normalized()
	return abs(relative_velocity.dot(collision_direction))

func get_entity_velocity() -> Vector2:
	if entity is RigidBody2D:
		return (entity as RigidBody2D).linear_velocity
	elif entity is CharacterBody2D:
		return (entity as CharacterBody2D).velocity
	return Vector2.ZERO

func calculate_hit_angle(other_armor: ArmorComponent) -> float:
	# Угол между нормалью брони и направлением удара
	var my_normal = Vector2.RIGHT.rotated(global_rotation)
	var impact_direction = (other_armor.global_position - global_position).normalized()
	var angle = rad_to_deg(my_normal.angle_to(impact_direction))
	return abs(wrapf(angle, -90, 90))

func check_penetration(other_armor: ArmorComponent, hit_angle: float, impact_velocity: float) -> bool:
	# Проверка минимальной скорости
	if impact_velocity < min_impact_speed:
		return false
	
	# Эффективная толщина с учетом угла
	var effective_thickness = thickness / cos(deg_to_rad(hit_angle))
	
	# Вероятность пробития на основе скорости, толщины и твердости
	var penetration_chance = (impact_velocity / min_impact_speed) * (other_armor.hardness / hardness) * (1.0 / effective_thickness)
	
	# Чем больше угол - тем меньше вероятность пробития
	var angle_penalty = 1.0 - (hit_angle / 90.0) * 0.5
	penetration_chance *= angle_penalty
	
	return randf() < penetration_chance

func handle_penetration(penetrator: ArmorComponent, hit_angle: float, impact_velocity: float):
	# Рассчитываем кинетический урон от скорости
	var kinetic_damage = calculate_kinetic_damage(impact_velocity, hit_angle)
	
	# Общий урон = кинетический + урон от содержимого
	var total_damage = kinetic_damage + penetrator.payload_damage
	
	# Наносим урон здоровью родительской сущности
	apply_damage_to_health(penetrator, total_damage)
	
	# Сигнал о пробитии
	armor_penetrated.emit(penetrator, total_damage)

func handle_ricochet(hit_angle: float):
	# Сигнал о рикошете
	armor_ricochet.emit(hit_angle)

func calculate_kinetic_damage(impact_velocity: float, hit_angle: float) -> float:
	# Базовый кинетический урон от скорости
	var base_damage = impact_velocity * 0.1
	
	# Модификатор угла (прямые удары наносят больше урона)
	var angle_modifier = 1.0 - (hit_angle / 90.0) * 0.3
	
	return base_damage * angle_modifier

func apply_damage_to_health(penetrator: ArmorComponent, total_damage: float):
	# Проверка не нужна, так как мы уже убедились что health_component существует
	health_component.take_damage(total_damage, penetrator.entity)
