extends Node2D

@export var next_scene:PackedScene = null

func game_done():
	# сохранить всю стату
	# переключиться на следующую сцену
	var tween = create_tween()
	tween.tween_property(get_parent(), "color", Color(0, 0, 0, 1), 3.0)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():get_tree().call_deferred("change_scene_to_packed", next_scene))
