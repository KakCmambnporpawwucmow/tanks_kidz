# test_destructible.gd
extends GutTest

var destructible: Destructible
var health_component: HealthComponent
var animation_player: AnimationPlayer
var animation_played: bool = false
var last_animation_name: StringName = ""

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
	
	# Создаем простую анимацию для тестов
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
	
	# Подписываемся на сигналы анимации
	animation_player.animation_started.connect(_on_animation_started)

func after_each():
	if destructible:
		destructible.queue_free()
	animation_played = false
	last_animation_name = ""

func _on_animation_started(anim_name: StringName):
	animation_played = true
	last_animation_name = anim_name

func _create_test_animation_player() -> AnimationPlayer:
	var anim_player = AnimationPlayer.new()
	
	# Создаем простую анимацию
	var animation = Animation.new()
	animation.length = 0.05  # Очень короткая для быстрых тестов
	
	# Добавляем трек
	var track_idx = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_idx, ".:modulate:a")
	animation.value_track_set_update_mode(track_idx, Animation.UPDATE_CONTINUOUS)
	animation.track_insert_key(track_idx, 0.0, 1.0)
	animation.track_insert_key(track_idx, 0.05, 0.0)
	
	# В Godot 4 добавляем анимацию через библиотеку анимаций
	var anim_library = AnimationLibrary.new()
	anim_library.add_animation("done", animation)
	anim_player.add_animation_library("", anim_library)
	
	return anim_player

func test_destructible_initialization():
	# Тест 1: Проверка инициализации сцены
	assert_not_null(destructible, "Destructible должен создаваться")
	assert_is(destructible, Obstacle, "Должен наследоваться от Obstacle")
	assert_is(destructible, Destructible, "Должен быть Destructible")
	
	# Тест 2: Проверка структуры сцены
	assert_not_null(health_component, "Сцена должна содержать HealthComponent")
	assert_not_null(destructible.health, "Свойство health должно быть установлено")
	assert_eq(destructible.health, health_component, "health должен ссылаться на HealthComponent из сцены")
	
	# Тест 3: Проверка наличия placeholder в сцене
	var placeholder = destructible.find_child("placeholder") as Sprite2D
	assert_not_null(placeholder, "Сцена должна содержать placeholder Sprite2D")

func test_ready_method():
	# Тест 3: Проверка метода _ready
	destructible._ready()
	
	# Проверяем, что placeholder стал невидимым
	var placeholder = destructible.find_child("placeholder") as Sprite2D
	assert_not_null(placeholder, "Должен содержать placeholder")
	assert_false(placeholder.visible, "placeholder должен быть невидимым после _ready()")
	
	# Проверяем подключение сигнала
	assert_true(health_component.death.is_connected(destructible._on_health_component_death),
		"Сигнал death должен быть подключен к _on_health_component_death")

func test_on_health_component_death_with_animation():
	# Тест 4: Обработка смерти с анимацией
	destructible._ready()
	
	# Вызываем смерть
	destructible._on_health_component_death()
	
	await wait_frames(1)
	
	# Проверяем, что анимация запускается через отслеживание сигнала
	assert_true(animation_played, "Анимация должна быть запущена (сигнал animation_started)")
	assert_eq(last_animation_name, "done", "Должна играть анимация 'done'")
	
	# Проверяем подключение сигнала completion
	assert_true(animation_player.animation_finished.is_connected(destructible._on_done_animation_finished),
		"Сигнал animation_finished должен быть подключен")

func test_on_health_component_death_without_animation():
	# Тест 5: Обработка смерти без анимации
	# Создаем отдельный экземпляр без анимации
	var destructible_scene = load("res://entities/obstacles/destructible.tscn")
	var destructible_no_anim = destructible_scene.instantiate() as Destructible
	destructible_no_anim.done_animation = null
	
	add_child(destructible_no_anim)
	destructible_no_anim._ready()
	
	# Вызываем смерть
	destructible_no_anim._on_health_component_death()
	
	# Должен сразу вызвать done_state
	#await wait_frames(1)
	assert_true(destructible_no_anim.is_queued_for_deletion(), "Должен быть помечен для удаления")
	
	destructible_no_anim.queue_free()

func test_on_done_animation_finished():
	# Тест 6: Завершение анимации
	destructible._ready()
	
	# Сохраняем placeholder для проверки
	var placeholder = destructible.find_child("placeholder") as Sprite2D
	var original_parent = placeholder.get_parent()
	
	# Симулируем завершение анимации
	destructible._on_done_animation_finished("done")
	
	#await wait_frames(2)
	
	# Проверяем, что destructible помечен для удаления
	assert_true(destructible.is_queued_for_deletion(), "Должен быть помечен для удаления после анимации")

func test_done_state_method():
	# Тест 7: Метод done_state
	destructible._ready()
	
	var placeholder = destructible.find_child("placeholder") as Sprite2D
	var original_parent = placeholder.get_parent()
	
	# Вызываем done_state
	var result = destructible.done_state()
	
	# Проверяем результат
	assert_false(result, "done_state должен вернуть false после перемещения placeholder")
	
	# Проверяем, что destructible помечен для удаления
	assert_true(destructible.is_queued_for_deletion(), "Должен быть помечен для удаления")
	
	# Проверяем, что placeholder больше не является дочерним узлом
	assert_ne(placeholder.get_parent(), original_parent, "placeholder должен быть перемещен")

func test_destructible_health_interaction():
	# Тест 8: Взаимодействие с HealthComponent
	destructible._ready()
	
	# Сбрасываем отслеживание анимации
	animation_played = false
	last_animation_name = ""
	
	# Наносим урон, но не смертельный
	var damage_taken = health_component.take_damage(50)
	assert_eq(damage_taken, 50, "Должен получить урон")
	assert_eq(health_component.get_current_health(), 50, "Здоровье должно уменьшиться")
	
	# Наносим смертельный урон
	health_component.take_damage(50)
	
	#await wait_frames(3)
	
	# Должен обработать смерть
	assert_false(health_component.is_alive, "HealthComponent должен быть мертв")
	assert_true(animation_played, "Должен запустить анимацию при смерти")
	assert_eq(last_animation_name, "done", "Должен играть анимацию 'done'")

func test_scene_integrity():
	# Тест 9: Проверка целостности сцены
	# Загружаем и проверяем несколько экземпляров
	for i in range(3):
		var scene = load("res://entities/obstacles/destructible.tscn")
		var instance = scene.instantiate() as Destructible
		
		assert_not_null(instance, "Должен создаваться экземпляр " + str(i))
		assert_is(instance, Destructible, "Должен быть Destructible")
		
		# Проверяем обязательные компоненты
		var health = instance.find_child("HealthComponent") as HealthComponent
		assert_not_null(health, "Должен содержать HealthComponent")
		
		var placeholder = instance.find_child("placeholder") as Sprite2D
		assert_not_null(placeholder, "Должен содержать placeholder")
		
		instance.queue_free()

func test_multiple_destructibles():
	# Тест 10: Несколько разрушаемых объектов
	var destructibles = []
	
	for i in range(3):
		var scene = load("res://entities/obstacles/destructible.tscn")
		var instance = scene.instantiate() as Destructible
		
		# Модифицируем для тестов
		var health = instance.find_child("HealthComponent") as HealthComponent
		health.max_health = 30 + i * 10
		health.auto_destroy_on_death = true
		
		# Создаем тестовую анимацию
		var anim_player = _create_test_animation_player()
		instance.done_animation = anim_player
		instance.add_child(anim_player)
		
		add_child(instance)
		destructibles.append({"instance": instance, "health": health})
	
	# Проверяем создание
	assert_eq(destructibles.size(), 3, "Должно быть создано 3 разрушаемых объекта")
	
	# Разрушаем все
	for data in destructibles:
		data.health.take_damage(data.health.max_health)
	
	#await wait_seconds(0.2)
	
	# Проверяем, что все помечены для удаления
	for data in destructibles:
		assert_true(data.instance.is_queued_for_deletion(), "Все должны быть помечены для удаления")
		data.instance.queue_free()
