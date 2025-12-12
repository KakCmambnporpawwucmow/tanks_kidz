# test_integration.gd
extends GutTest

func test_tank_with_components():
	# Тест 1: Интеграционный тест танка с компонентами
	var tank_scene = load("res://entities/tanks/base/tank.tscn")
	assert_not_null(tank_scene, "Сцена танка должна загружаться")
	
	var tank_instance = tank_scene.instantiate()
	add_child(tank_instance)
	
	# Ищем компоненты
	var move_component = tank_instance.find_child("*MoveComponent*", true, false)
	var health_component = tank_instance.find_child("*HealthComponent*", true, false)
	
	assert_not_null(move_component, "Танк должен иметь компонент движения")
	assert_not_null(health_component, "Танк должен иметь компонент здоровья")
	
	# Проверяем базовую функциональность
	if move_component is BaseMoveComponent:
		var initial_pos = tank_instance.position
		move_component.move(Vector2.RIGHT)
		await wait_frames(10)
		
		assert_ne(tank_instance.position, initial_pos, "Танк должен двигаться")
	
	if health_component is HealthComponent:
		var initial_health = health_component.get_current_health()
		health_component.take_damage(20)
		
		assert_eq(health_component.get_current_health(), initial_health - 20, "Танк должен получать урон")
	
	tank_instance.queue_free()

func test_obstacle_damage_interaction():
	# Тест 2: Взаимодействие препятствия с танком
	var box_scene = load("res://entities/obstacles/box.tscn")
	var tank_scene = load("res://entities/tanks/base/tank.tscn")
	
	assert_not_null(box_scene, "Сцена коробки должна загружаться")
	assert_not_null(tank_scene, "Сцена танка должна загружаться")
	
	var box = box_scene.instantiate()
	var tank = tank_scene.instantiate()
	
	add_child(box)
	add_child(tank)
	
	# Ищем компоненты здоровья
	var tank_health = tank.find_child("*HealthComponent*", true, false)
	assert_not_null(tank_health, "Танк должен иметь HealthComponent")
	
	var initial_health = tank_health.get_current_health()
	
	# Симулируем столкновение с уроном (в реальном проекте это делалось бы через Area2D)
	var damage_component = DamageComponent.new()
	damage_component.damage = 30
	damage_component.execute(tank_health)
	
	assert_eq(tank_health.get_current_health(), initial_health - 30, "Танк должен получить урон от препятствия")
	
	box.queue_free()
	tank.queue_free()
	damage_component.queue_free()

func test_scene_load():
	# Тест 3: Загрузка тестовой сцены
	var test_scene = load("res://tests/test_runner.tscn")
	assert_not_null(test_scene, "Тестовая сцена должна загружаться")
	
	var instance = test_scene.instantiate()
	add_child(instance)
	
	# Проверяем наличие ключевых узлов
	var terrain = instance.find_child("terrain")
	var player_tank = instance.find_child("PlayerTank")
	var obstacles = instance.find_child("obstacles")
	
	assert_not_null(terrain, "Должен присутствовать terrain")
	assert_not_null(player_tank, "Должен присутствовать PlayerTank")
	assert_not_null(obstacles, "Должны присутствовать obstacles")
	
	# Проверяем наличие компонентов у танка игрока
	if player_tank:
		var move_component = player_tank.find_child("*MoveComponent*", true, false)
		var health_component = player_tank.find_child("*HealthComponent*", true, false)
		
		assert_not_null(move_component, "PlayerTank должен иметь компонент движения")
		assert_not_null(health_component, "PlayerTank должен иметь компонент здоровья")
	
	instance.queue_free()
