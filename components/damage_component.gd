extends Node

class_name DamageComponent

@export var damage:int = 0
var _current_damage:int = 0
var _is_done:bool = false

func _ready() -> void:
	_current_damage = damage

func execute(health:HealthComponent)->int:
	return health.take_damage(_current_damage) if _is_done == false else 0
	
func update(add_value:int, timeout:int = 0):
	_current_damage += add_value
	if timeout > 0:
		$Timer.wait_time = timeout
		$Timer.start()

func _on_timer_timeout() -> void:
	_current_damage = damage
	
func get_current_damage()->int:
	return _current_damage
	
func done():
	_is_done = true
