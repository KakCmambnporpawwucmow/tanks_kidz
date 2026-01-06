extends Panel

@export var value_name:String

func _ready() -> void:
	PlayerState.send_change_data.connect(func():$value.text = str(PlayerState.get_ps().get(value_name)))
