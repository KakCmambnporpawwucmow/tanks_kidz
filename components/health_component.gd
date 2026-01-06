# health_component.gd
class_name HealthComponent
extends Node

@export var max_health: int = 100:
	set(value):
		max_health = value
		_current_health = max_health
@export var auto_destroy_on_death: bool = true

var _current_health: int
var is_alive: bool = true

signal health_changed(new_health: int)
signal death()
signal low_health(health_percentage: int)

func _ready():
	_current_health = max_health

func take_damage(amount: int)->int:
	if not is_alive:
		return 0
	
	var old_health = _current_health
	_current_health = max(0, _current_health - amount)
	health_changed.emit(_current_health)
	
	# Проверка критического здоровья
	if _current_health <= max_health * 0.3 and old_health > max_health * 0.3:
		low_health.emit(get_health_percentage())
	
	if _current_health <= 0:
		die()
	return old_health - _current_health

func die():
	if not is_alive:
		return
	
	is_alive = false
	death.emit()
	
	if auto_destroy_on_death:
		get_parent().queue_free()

func resurrect(health_percentage: float = 1.0)->int:
	is_alive = true
	if health_percentage > 1.0:
		health_percentage = 1.0
	if health_percentage < 0:
		health_percentage = 0
	_current_health = int(health_percentage * max_health)
	health_changed.emit(_current_health)
	return _current_health

func get_health_percentage() -> float:
	return _current_health / float(max_health)

func is_full_health() -> bool:
	return _current_health >= max_health

func heal(amount: int)->int:
	if not is_alive:
		return 0
	
	var old_health = _current_health
	_current_health = min(max_health, _current_health + amount)
	
	if old_health != _current_health:
		health_changed.emit(_current_health)
	return _current_health
	
func get_current_health()->int:
	return _current_health
