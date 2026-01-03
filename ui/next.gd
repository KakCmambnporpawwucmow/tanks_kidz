extends Button

@export var next_scene:String

func _on_button_down() -> void:
	get_tree().change_scene_to_file(next_scene)
