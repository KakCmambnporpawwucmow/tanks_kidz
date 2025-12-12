extends TextureProgressBar

class_name HPIndicator

@export var health_component:HealthComponent = null

var _tween:Tween = null
var text:String:
	set(value):
		text = value
		if has_node("count"):
			$count.text = text

func _ready() -> void:
	if health_component == null:
		Logi.fatal("HPIndicator {0}: health_component must be assigned.".format([name]))
	assert(health_component != null, "HPIndicator: HealthComponent must be assigned")
	max_value = health_component.max_health
	value = health_component.max_health
	if not health_component.health_changed.is_connected(change_hp):
		health_component.health_changed.connect(change_hp)
	visible = false

func change_hp(new_hp:int)->bool:
	if value == 0:
		text = str(new_hp)
		return false
	visible = true
	text = str(new_hp)
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "value", new_hp, 1.0)
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.tween_callback(callback)
	return true
	
func callback():
	visible = false
	_tween = null
