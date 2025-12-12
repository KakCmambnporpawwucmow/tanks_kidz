# test_destructible_animation.gd
extends GutTest

var destructible: Destructible
var health_component: HealthComponent
var animation_player: AnimationPlayer

func before_each():
	# Загружаем сцену destructible.tscn
	var destructible_scene = load("res://entities/obstacles/destructible.tscn")
	assert_not_null(destructible_scene, "Сцена destructible должна загружаться")
	
	# Создаем экземпляр сцены
	destructible = destructible_scene.instantiate() as Destructible
	assert_not_null(destructible, "Должен создаться экземпляр Destructible")
	
	# Находим HealthComponent в сцене
	health_component = destructible.find_child("HealthComponent") as HealthComponent
	assert_not_null(health_component, "Destructible должен содержать HealthComponent")
	health_component.auto_destroy_on_death = false
	
	# Создаем AnimationPlayer с тестовой анимацией
	animation_player = _create_test_animation_player()
	animation_player.name = "done_animation"
	
	# Заменяем существующий AnimationPlayer или добавляем новый
	var existing_animation_player = destructible.find_child("done_animation") as AnimationPlayer
	if existing_animation_player:
		# Удаляем существующий и добавляем наш тестовый
		var parent = existing_animation_player.get_parent()
		parent.remove_child(existing_animation_player)
		parent.add_child(animation_player)
		destructible.done_animation = animation_player
	else:
		destructible.done_animation = animation_player
		destructible.add_child(animation_player)
	
	add_child(destructible)

func after_each():
	if destructible:
		destructible.queue_free()

func _create_test_animation_player() -> AnimationPlayer:
	var anim_player = AnimationPlayer.new()
	
	# Создаем простую анимацию
	var animation = Animation.new()
	animation.length = 0.3
	
	# Добавляем трек для прозрачности
	var track_idx = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_idx, ".:modulate:a")
	animation.value_track_set_update_mode(track_idx, Animation.UPDATE_CONTINUOUS)
	animation.track_insert_key(track_idx, 0.0, 1.0)
	animation.track_insert_key(track_idx, 0.3, 0.0)
	
	# В Godot 4 добавляем анимацию через библиотеку анимаций
	var anim_library = AnimationLibrary.new()
	anim_library.add_animation("done", animation)
	anim_player.add_animation_library("", anim_library)
	
	return anim_player

func test_animation_playback():
	# Тест 1: Проверка воспроизведения анимации
	destructible._ready()
	
	# Подключаемся к сигналу завершения анимации
	var animation_finished_called = [false]
	animation_player.animation_finished.connect(
		func(_anim_name: StringName): 
			animation_finished_called[0] = true
	)
	
	# Вызываем смерть
	health_component.take_damage(health_component.max_health)
	
	# Проверяем, что анимация начала играть
	assert_true(animation_player.is_playing(), "Анимация должна воспроизводиться")
	assert_eq(animation_player.current_animation, "done", "Должна играть анимация 'done'")
	
	# Ждем завершения анимации
	await wait_seconds(0.4)
	
	# Проверяем завершение
	assert_true(animation_finished_called[0], "Сигнал animation_finished должен быть вызван")
	#assert_true(destructible.is_queued_for_deletion(), "Должен быть помечен для удаления после анимации")

func test_animation_callback_connection():
	# Тест 2: Проверка подключения коллбэка анимации
	destructible._ready()
	
	# Вызываем смерть
	health_component.take_damage(health_component.max_health)
	
	await wait_frames(2)
	
	# Проверяем подключение через is_connected
	assert_true(animation_player.animation_finished.is_connected(destructible._on_done_animation_finished),
		"Сигнал animation_finished должен быть подключен к _on_done_animation_finished")

func test_animation_length_and_properties():
	# Тест 4: Проверка свойств анимации
	destructible._ready()
	
	# Проверяем, что анимация существует
	assert_true(animation_player.has_animation("done"), "Должна существовать анимация 'done'")
	
	var animation = animation_player.get_animation("done")
	assert_not_null(animation, "Должен возвращать анимацию 'done'")
	
	# Проверяем свойства анимации
	#assert_eq(animation.length, 0.3, "Длина анимации должна быть 0.3")
	assert_almost_eq(animation.length, 0.3, 0.0001, "Длина анимации должна быть примерно 0.3")
	
	# Проверяем треки
	var track_count = animation.get_track_count()
	assert_true(track_count > 0, "Анимация должна содержать треки")
	
	# Проверяем первый трек
	var track_path = animation.track_get_path(0)
	assert_true("modulate:a" in str(track_path), "Трек должен анимировать прозрачность")

func test_animation_player_replacement():
	# Тест 6: Проверка замены AnimationPlayer
	var scene = load("res://entities/obstacles/destructible.tscn")
	var test_destructible = scene.instantiate() as Destructible
	
	# Проверяем исходное состояние
	var original_animation_player = test_destructible.find_child("done_animation") as AnimationPlayer
	var has_original_animation = original_animation_player != null
	
	# Создаем новую анимацию
	var new_animation_player = _create_test_animation_player()
	new_animation_player.name = "done_animation"
	
	# Заменяем анимацию
	if has_original_animation:
		var parent = original_animation_player.get_parent()
		parent.remove_child(original_animation_player)
		parent.add_child(new_animation_player)
		test_destructible.done_animation = new_animation_player
	else:
		test_destructible.done_animation = new_animation_player
		test_destructible.add_child(new_animation_player)
	
	add_child(test_destructible)
	
	# Проверяем замену
	assert_eq(test_destructible.done_animation, new_animation_player, "Анимация должна быть заменена")
	assert_true(test_destructible.has_node("done_animation"), "Должен содержать узел анимации")
	
	test_destructible.queue_free()
