# test_obstacles_integration.gd
extends GutTest

class MockTank:
	extends Node2D
	var weapon_system = null
	var last_damage_taken: int = 0
	
	func take_damage(amount: int) -> int:
		last_damage_taken = amount
		return amount

func test_obstacle_damage_interaction():
	# Тест 1: Взаимодействие танка с препятствием
	# Загружаем сцену obstacle.tscn
	var obstacle_scene = load("res://entities/obstacles/obstacle.tscn")
	assert_not_null(obstacle_scene, "Сцена obstacle должна загружаться")
	
	var obstacle = obstacle_scene.instantiate() as Obstacle
	assert_not_null(obstacle, "Должен создаться экземпляр Obstacle")
	
	# Добавляем HealthComponent к obstacle
	var health_component = HealthComponent.new()
	health_component.max_health = 100
	obstacle.add_child(health_component)
	obstacle.health = health_component
	
	var tank = MockTank.new()
	
	add_child(obstacle)
	add_child(tank)
	
	# Наносим урон препятствию
	var damage_taken = health_component.take_damage(30)
	assert_eq(damage_taken, 30, "Препятствие должно получать урон")
	assert_eq(health_component.get_current_health(), 70, "Здоровье препятствия должно уменьшиться")
	
	# Наносим смертельный урон
	health_component.take_damage(70)
	assert_false(health_component.is_alive, "Препятствие должно умереть")
	
	obstacle.queue_free()
	tank.queue_free()

func test_destructible_destruction_flow():
	# Тест 2: Полный поток разрушения Destructible
	# Загружаем сцену destructible.tscn
	var destructible_scene = load("res://entities/obstacles/destructible.tscn")
	assert_not_null(destructible_scene, "Сцена destructible должна загружаться")
	
	var destructible = destructible_scene.instantiate() as Destructible
	assert_not_null(destructible, "Должен создаться экземпляр Destructible")
	
	# Находим HealthComponent в сцене
	var health_component = destructible.find_child("HealthComponent") as HealthComponent
	assert_not_null(health_component, "Destructible должен содержать HealthComponent")
	health_component.max_health = 50
	health_component.auto_destroy_on_death = false
	
	# Убеждаемся, что есть placeholder
	var placeholder = destructible.find_child("placeholder") as Sprite2D
	if not placeholder:
		# Если нет placeholder в сцене, создаем его
		placeholder = Sprite2D.new()
		placeholder.name = "placeholder"
		destructible.add_child(placeholder)
	
	# Создаем AnimationPlayer с правильным Godot 4 синтаксисом
	var animation_player = AnimationPlayer.new()
	
	# Создаем простую анимацию
	var animation = Animation.new()
	animation.length = 0.5
	
	# Добавляем трек
	var track_idx = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_idx, ".:modulate:a")
	animation.track_insert_key(track_idx, 0.0, 1.0)
	animation.track_insert_key(track_idx, 0.5, 0.0)
	
	# Добавляем анимацию через библиотеку (Godot 4 способ)
	var anim_library = AnimationLibrary.new()
	anim_library.add_animation("done", animation)
	animation_player.add_animation_library("", anim_library)
	
	# Заменяем существующий AnimationPlayer или добавляем новый
	var existing_animation_player = destructible.find_child("done_animation") as AnimationPlayer
	if existing_animation_player:
		var parent = existing_animation_player.get_parent()
		parent.remove_child(existing_animation_player)
		parent.add_child(animation_player)
		destructible.done_animation = animation_player
	else:
		destructible.done_animation = animation_player
		destructible.add_child(animation_player)
	
	add_child(destructible)
	
	# Инициализируем
	destructible._ready()
	
	# Проверяем начальное состояние
	assert_false(placeholder.visible, "placeholder должен быть невидимым")
	assert_true(health_component.is_alive, "Должен быть жив вначале")
	
	# Наносим смертельный урон
	watch_signals(health_component)
	health_component.take_damage(50)
	
	# Проверяем сигналы
	assert_signal_emitted(health_component, "death", "Сигнал death должен быть испущен")
	
	destructible.queue_free()

func test_multiple_obstacles_in_scene():
	# Тест 3: Несколько препятствий в сцене
	var obstacles = []
	
	# Создаем разные типы препятствий
	for i in range(3):
		var obstacle_scene = load("res://entities/obstacles/obstacle.tscn")
		var obstacle = obstacle_scene.instantiate() as Obstacle
		
		# Добавляем HealthComponent
		var health = HealthComponent.new()
		health.max_health = 100
		obstacle.add_child(health)
		obstacle.health = health
		
		obstacles.append(obstacle)
		add_child(obstacle)
	
	# Проверяем создание
	assert_eq(obstacles.size(), 3, "Должно быть создано 3 препятствия")
	
	# Наносим урон всем
	for i in range(obstacles.size()):
		var health = obstacles[i].get_health()
		var damage = health.take_damage((i + 1) * 20)
		assert_eq(damage, (i + 1) * 20, "Урон должен наноситься")
	
	# Проверяем состояние
	assert_eq(obstacles[0].get_health().get_current_health(), 80, "Первое препятствие должно иметь 80 HP")
	assert_eq(obstacles[1].get_health().get_current_health(), 60, "Второе препятствие должно иметь 60 HP")
	assert_eq(obstacles[2].get_health().get_current_health(), 40, "Третье препятствие должно иметь 40 HP")
	
	# Очищаем
	for obstacle in obstacles:
		obstacle.queue_free()

func test_obstacle_collision_simulation():
	# Тест 4: Симуляция столкновения с препятствием
	var obstacle_scene = load("res://entities/obstacles/obstacle.tscn")
	var obstacle = obstacle_scene.instantiate() as Obstacle
	
	var health_component = HealthComponent.new()
	health_component.max_health = 200
	
	# Создаем DamageComponent для симуляции урона от снаряда
	var damage_component = DamageComponent.new()
	damage_component.damage = 40
	
	obstacle.add_child(health_component)
	obstacle.health = health_component
	
	add_child(obstacle)
	add_child(damage_component)
	
	# Симулируем попадание снаряда
	var initial_health = health_component.get_current_health()
	var damage_taken = damage_component.execute(health_component)
	
	assert_eq(damage_taken, 40, "Должен быть нанесен урон 40")
	assert_eq(health_component.get_current_health(), initial_health - 40, "Здоровье должно уменьшиться")
	
	# Несколько попаданий
	damage_component.execute(health_component)
	damage_component.execute(health_component)
	
	# После 3 попаданий (40 * 3 = 120)
	assert_eq(health_component.get_current_health(), 80, "После 3 попаданий должно остаться 80 HP")
	
	obstacle.queue_free()
	damage_component.queue_free()

func test_destructible_placeholder_transfer():
	# Тест 5: Проверка передачи placeholder родителю
	var parent_node = Node2D.new()
	
	# Загружаем сцену destructible.tscn
	var destructible_scene = load("res://entities/obstacles/destructible.tscn")
	var destructible = destructible_scene.instantiate() as Destructible
	
	# Находим HealthComponent в сцене
	var health_component = destructible.find_child("HealthComponent") as HealthComponent
	assert_not_null(health_component, "Destructible должен содержать HealthComponent")
	health_component.max_health = 50
	
	# Убеждаемся, что есть placeholder
	var placeholder = destructible.find_child("placeholder") as Sprite2D
	if not placeholder:
		# Если нет placeholder в сцене, создаем его
		placeholder = Sprite2D.new()
		placeholder.name = "placeholder"
		destructible.add_child(placeholder)
	
	parent_node.add_child(destructible)
	add_child(parent_node)
	
	# Сохраняем позицию
	var original_position = placeholder.global_position
	
	# Вызываем разрушение
	health_component.take_damage(50)
	
	# Ждем обработки (пропускаем анимацию)
	destructible.done_state()
	
	#await wait_frames(2)
	
	# Проверяем, что destructible удаляется
	assert_true(destructible.is_queued_for_deletion(), "Destructible должен быть помечен для удаления")
	
	parent_node.queue_free()

func test_obstacle_hierarchy():
	# Тест 6: Проверка иерархии классов препятствий
	# Проверяем наследование
	var obstacle_class = load("res://entities/obstacles/obstacle.gd")
	var destructible_class = load("res://entities/obstacles/destructible.gd")
	
	assert_not_null(obstacle_class, "Класс obstacle.gd должен загружаться")
	assert_not_null(destructible_class, "Класс destructible.gd должен загружаться")
	
	# Создаем экземпляры через new() для проверки наследования
	var obstacle_instance = obstacle_class.new()
	var destructible_instance = destructible_class.new()
	
	# Проверяем наследование
	assert_is(obstacle_instance, Node2D, "Obstacle должен наследоваться от Node2D")
	assert_is(destructible_instance, Obstacle, "Destructible должен наследоваться от Obstacle")
	assert_is(destructible_instance, Node2D, "Destructible также должен наследоваться от Node2D")
	
	# Проверяем методы
	assert_true(obstacle_instance.has_method("get_health"), "Obstacle должен иметь метод get_health")
	
	obstacle_instance.queue_free()
	destructible_instance.queue_free()

func test_real_destructible_scenes():
	# Тест 7: Тестирование реальных сцен разрушаемых объектов
	var destructible_scenes = [
		"res://entities/obstacles/box.tscn",
		"res://entities/obstacles/box_iron.tscn",
		"res://entities/obstacles/barrel.tscn"
	]
	
	for scene_path in destructible_scenes:
		var scene = load(scene_path)
		if scene:
			var instance = scene.instantiate()
			assert_not_null(instance, "Должен создаться экземпляр из " + scene_path)
			
			# Проверяем, что это Destructible
			assert_is(instance, Destructible, "Должен быть Destructible: " + scene_path)
			
			# Проверяем наличие HealthComponent
			var health_component = instance.find_child("HealthComponent") as HealthComponent
			assert_not_null(health_component, "Должен содержать HealthComponent: " + scene_path)
			
			# Проверяем наличие placeholder
			var placeholder = instance.find_child("placeholder") as Sprite2D
			assert_not_null(placeholder, "Должен содержать placeholder: " + scene_path)
			
			instance.queue_free()
