extends TextureProgressBar

class_name HPIndicator

@export var health_component:HealthComponent = null

func _ready() -> void:
	assert(health_component != null, "HPIndicator: HealthComponent must be assigned")
	max_value = health_component.max_health
	value = health_component.max_health
	health_component.health_changed.connect(change_hp)

func change_hp(new_hp:int)->bool:
	if value == 0:
		return false
	visible = true
	$count.text = str(new_hp)
	var tween = create_tween()
	tween.tween_property(self, "value", new_hp, 1.0)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(callback)
	return true
	
func callback():
	visible = false
