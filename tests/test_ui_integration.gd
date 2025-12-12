# test_ui_integration.gd
extends GutTest

class MockWeaponSystemForUI:
	extends Node
	var current_ammo_type = 0
	var ammo_counts = {0: 30, 1: 20, 2: 15, 3: 10}
	
	signal send_update
	
	func get_current_ammo_type():
		return current_ammo_type
	
	func get_proj_count(ammo_type: int) -> int:
		return ammo_counts.get(ammo_type, 0)

class MockTankForUI:
	extends Node2D
	var weapon_system: WeaponSystem
	
	func _init():
		weapon_system = WeaponSystem.new()
		
	func get_weapon_system()->WeaponSystem:
		return weapon_system

func test_full_ui_system():
	# Тест 1: Полная система UI с танком
	var tank = MockTankForUI.new()
	add_child(tank)
	add_child(tank.weapon_system)
	
	# Создаем AmmoStatistic
	var ammo_stat = AmmoStatistic.new()
	ammo_stat.game_object = tank
	add_child(ammo_stat)
	
	# Создаем AmmoState для каждого типа боеприпасов
	const ProjectileType = {"AP": 0, "HE": 1, "HEAT": 2, "MISSILE": 3}
	
	var textures = []
	for i in range(4):
		var texture = ImageTexture.create_from_image(Image.create(16, 16, false, Image.FORMAT_RGBA8))
		textures.append(texture)
		
		var ammo_state = AmmoState.new()
		ammo_state.texture = textures[i]
		ammo_state.title = ["AP", "HE", "HEAT", "MISSILE"][i]
		ammo_state.ammo_type = i
		ammo_stat.add_child(ammo_state)
	
	# Инициализируем
	ammo_stat._ready()
	ammo_stat.update()
	
	# Проверяем начальное состояние
	for child in ammo_stat.get_children():
		if child is AmmoState:
			if child.ammo_type == ProjectileType.AP:
				assert_true(child.bold_state, "AP должен быть выделен по умолчанию")
			else:
				assert_false(child.bold_state, "Только AP должен быть выделен")
			
			var expected_count = tank.weapon_system.get_proj_count(child.ammo_type)
			assert_eq(child.count, expected_count, "Количество должно соответствовать weapon_system")
	
	# Меняем текущий тип боеприпасов
	tank.weapon_system.current_ammo_type = ProjectileType.HEAT
	tank.weapon_system.send_update.emit()
	
	await wait_frames(2)
	
	# Проверяем обновление
	for child in ammo_stat.get_children():
		if child is AmmoState:
			if child.ammo_type == ProjectileType.HEAT:
				assert_true(child.bold_state, "HEAT должен быть выделен после смены")
			else:
				assert_false(child.bold_state, "Только HEAT должен быть выделен")
	
	tank.queue_free()
	ammo_stat.queue_free()

func test_hp_indicator_with_real_health_component():
	# Тест 2: HPIndicator с реальным HealthComponent
	var health_component = HealthComponent.new()
	health_component.max_health = 150
	health_component.auto_destroy_on_death = false
	
	var hp_indicator = HPIndicator.new()
	hp_indicator.health_component = health_component
	
	add_child(hp_indicator)
	add_child(health_component)
	
	hp_indicator._ready()
	
	# Проверяем начальные значения
	assert_eq(hp_indicator.max_value, 150, "max_value должно быть 150")
	assert_eq(hp_indicator.value, 150, "value должно быть 150")
	
	# Наносим урон
	var damage_taken = health_component.take_damage(50)
	assert_eq(damage_taken, 50, "Должен быть нанесен урон 50")
	
	# HPIndicator должен обновиться через сигнал
	await wait_frames(2)
	
	#var count_label = hp_indicator.find_child("count") as Label
	#assert_eq(count_label.text, "100", "Должен отображать 100 после урона")
	
	hp_indicator.queue_free()
	health_component.queue_free()

func test_ammo_state_scene_loading():
	# Тест 3: Загрузка сцены ammo_st.tscn
	var ammo_state_scene = load("res://entities/misc/ammo_st.tscn")
	assert_not_null(ammo_state_scene, "Сцена ammo_st должна загружаться")
	
	var instance = ammo_state_scene.instantiate()
	assert_not_null(instance, "Должен создаться экземпляр")
	assert_is(instance, AmmoState, "Должен быть AmmoState")
	
	# Проверяем свойства
	instance.texture = ImageTexture.create_from_image(Image.create(16, 16, false, Image.FORMAT_RGBA8))
	instance.title = "TEST"
	instance.count = 99
	instance.bold_state = true
	instance.ammo_type = 2
	
	# Проверяем, что свойства установились
	assert_eq(instance.title, "TEST", "Заголовок должен сохраниться")
	assert_eq(instance.count, 99, "Количество должно сохраниться")
	assert_true(instance.bold_state, "Выделение должно быть включено")
	assert_eq(instance.ammo_type, 2, "Тип боеприпасов должен сохраниться")
	
	instance.queue_free()

func test_ammo_stat_scene_loading():
	# Тест 4: Загрузка сцены ammo_stat.tscn
	var ammo_stat_scene = load("res://entities/misc/ammo_stat.tscn")
	assert_not_null(ammo_stat_scene, "Сцена ammo_stat должна загружаться")
	
	var instance = ammo_stat_scene.instantiate()
	assert_not_null(instance, "Должен создаться экземпляр")
	assert_is(instance, AmmoStatistic, "Должен быть AmmoStatistic")
	
	# Проверяем структуру
	assert_true(instance.get_child_count() > 0, "Должен иметь дочерние элементы")
	
	# Проверяем, что дети - это AmmoState
	for child in instance.get_children():
		assert_is(child, AmmoState, "Дети должны быть AmmoState")
	
	instance.queue_free()

func test_ui_components_together():
	# Тест 5: Все UI-компоненты вместе
	# Создаем HealthComponent и HPIndicator
	var health = HealthComponent.new()
	health.max_health = 200
	
	var hp_indicator = HPIndicator.new()
	hp_indicator.health_component = health
	
	# Создаем WeaponSystem и AmmoStatistic
	var weapon_system = WeaponSystem.new()
	var tank = MockTankForUI.new()
	tank.weapon_system = weapon_system
	
	var ammo_stat = AmmoStatistic.new()
	ammo_stat.game_object = tank
	
	# Добавляем AmmoState
	for i in range(4):
		var ammo_state = AmmoState.new()
		ammo_state.ammo_type = i
		ammo_state.title = str(i)
		ammo_stat.add_child(ammo_state)
	
	# Добавляем все в сцену
	add_child(health)
	add_child(hp_indicator)
	add_child(tank)
	add_child(weapon_system)
	add_child(ammo_stat)
	
	# Инициализируем
	hp_indicator._ready()
	ammo_stat._ready()
	ammo_stat.update()
	
	# Проверяем, что все работает
	assert_eq(hp_indicator.max_value, 200, "HPIndicator настроен правильно")
	assert_eq(ammo_stat.get_child_count(), 4, "AmmoStatistic имеет 4 AmmoState")
	
	# Симулируем игровые события
	health.take_damage(50)
	weapon_system.current_ammo_type = 3
	weapon_system.send_update.emit()
	
	await wait_frames(3)
	
	# Проверяем обновления
	assert_eq(health.get_current_health(), 150, "Здоровье уменьшилось")
	
	for child in ammo_stat.get_children():
		if child is AmmoState:
			if child.ammo_type == 3:
				assert_true(child.bold_state, "Последний тип должен быть выделен")
	
	# Очищаем
	health.queue_free()
	hp_indicator.queue_free()
	tank.queue_free()
	weapon_system.queue_free()
	ammo_stat.queue_free()
