extends StaticBody2D

# держим место уничтожения танка указаное время и освобождаем его.
func _on_timer_timeout() -> void:
	queue_free()
