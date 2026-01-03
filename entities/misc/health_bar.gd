extends TextureProgressBar
class_name HealthBar

@export var _health_component:HealthComponent = null

func _on_health_changed(new_health: int):
	$Label.text = str(new_health)
	if is_instance_valid(_health_component):
		var tween = create_tween()
		tween.tween_property(self, "value", new_health, 0.5)
		tween.set_ease(Tween.EASE_IN_OUT)
	
func set_game_object(tank:Tank)->bool:
	if is_instance_valid(_health_component):
		return false
	_health_component = tank.get_health()
	_health_component.health_changed.connect(_on_health_changed)
	$Label.text = str(_health_component.max_health)
	max_value = _health_component.max_health
	value = max_value
	return true
