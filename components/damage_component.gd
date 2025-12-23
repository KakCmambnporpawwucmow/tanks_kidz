extends Node

class_name DamageComponent

@export var damage:int = 0:
	set(value):
		damage = value
		_current_damage = damage
@onready var _current_damage:int = damage
var _is_done:bool = false
var _timer:Timer = null

func _ready() -> void:
	_timer = Timer.new()
	add_child(_timer)
	_timer.connect("timeout", _on_timer_timeout)
	_timer.one_shot = true

func execute(health:HealthComponent)->int:
	if _current_damage == 0:
		_current_damage = damage
	return health.take_damage(_current_damage) if health != null and _is_done == false else 0
	
func update(add_value:int, timeout:float = 0)->int:
	_current_damage = add_value
	if _timer != null and timeout > 0:
		_timer.wait_time = timeout
		_timer.start()
	return _current_damage

func _on_timer_timeout() -> void:
	_current_damage = damage
	
func get_current_damage()->int:
	return _current_damage
	
func done():
	_is_done = true
