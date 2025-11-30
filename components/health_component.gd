# health_component.gd
class_name HealthComponent
extends Node

@export var max_health: float = 100.0
@export var auto_destroy_on_death: bool = true

var current_health: float
var is_alive: bool = true

signal health_changed(new_health: float)
signal death()
signal low_health(health_percentage: float)

func _ready():
	current_health = max_health

func take_damage(amount: float)->int:
	if not is_alive:
		return 0
	
	var old_health = current_health
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health)
	
	# Проверка критического здоровья
	if current_health <= max_health * 0.3 and old_health > max_health * 0.3:
		low_health.emit(get_health_percentage())
	
	if current_health <= 0:
		die()
	return old_health - current_health

func die():
	if not is_alive:
		return
	
	is_alive = false
	death.emit()
	
	if auto_destroy_on_death:
		get_parent().queue_free()

func resurrect(health_percentage: float = 1.0):
	is_alive = true
	current_health = max_health * health_percentage
	health_changed.emit(current_health)

func get_health_percentage() -> float:
	return current_health / max_health

func is_full_health() -> bool:
	return current_health >= max_health

func heal(amount: float):
	if not is_alive:
		return
	
	var old_health = current_health
	current_health = min(max_health, current_health + amount)
	
	if old_health != current_health:
		health_changed.emit(current_health)
