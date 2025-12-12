# test_obstacles_types.gd
extends GutTest

func test_box_obstacle():
	# Тест 1: Загрузка коробки
	var box_scene = load("res://entities/obstacles/box.tscn")
	assert_not_null(box_scene, "Сцена box должна загружаться")
	
	var box = box_scene.instantiate()
	assert_not_null(box, "Должен создаться экземпляр box")
	assert_is(box, Destructible, "Коробка должна быть Destructible")
	
	# Проверяем компоненты
	var health_component = box.find_child("HealthComponent") as HealthComponent
	assert_not_null(health_component, "Должен иметь HealthComponent")
	
	box.queue_free()

func test_iron_box_obstacle():
	# Тест 2: Загрузка железной коробки
	var iron_box_scene = load("res://entities/obstacles/box_iron.tscn")
	assert_not_null(iron_box_scene, "Сцена iron_box должна загружаться")
	
	var iron_box = iron_box_scene.instantiate()
	assert_not_null(iron_box, "Должен создаться экземпляр iron_box")
	
	iron_box.queue_free()

func test_barrel_obstacle():
	# Тест 3: Загрузка бочки
	var barrel_scene = load("res://entities/obstacles/barrel.tscn")
	assert_not_null(barrel_scene, "Сцена barrel должна загружаться")
	
	var barrel = barrel_scene.instantiate()
	assert_not_null(barrel, "Должен создаться экземпляр barrel")
	
	barrel.queue_free()

func test_stopper_obstacle():
	# Тест 4: Загрузка стоппера
	var stopper_scene = load("res://entities/obstacles/stopper.tscn")
	assert_not_null(stopper_scene, "Сцена stopper должна загружаться")
	
	var stopper = stopper_scene.instantiate()
	assert_not_null(stopper, "Должен создаться экземпляр stopper")
	
	stopper.queue_free()

func test_hedgehog_obstacle():
	# Тест 5: Загрузка ежа
	var hedgehog_scene = load("res://entities/obstacles/hedgehog.tscn")
	assert_not_null(hedgehog_scene, "Сцена hedgehog должна загружаться")
	
	var hedgehog = hedgehog_scene.instantiate()
	assert_not_null(hedgehog, "Должен создаться экземпляр hedgehog")
	
	hedgehog.queue_free()

func test_house_obstacle():
	# Тест 6: Загрузка дома
	var house_scene = load("res://entities/obstacles/house.tscn")
	assert_not_null(house_scene, "Сцена house должна загружаться")
	
	var house = house_scene.instantiate()
	assert_not_null(house, "Должен создаться экземпляр house")
	
	house.queue_free()

func test_all_obstacles_inheritance():
	# Тест 7: Проверка наследования всех препятствий
	var obstacle_files = [
		"res://entities/obstacles/box.tscn",
		"res://entities/obstacles/box_iron.tscn",
		"res://entities/obstacles/barrel.tscn",
		"res://entities/obstacles/stopper.tscn",
		"res://entities/obstacles/hedgehog.tscn",
		"res://entities/obstacles/house.tscn"
	]
	
	for file_path in obstacle_files:
		var scene = load(file_path)
		if scene:
			var instance = scene.instantiate()
			assert_not_null(instance, "Должен создаться экземпляр из " + file_path)
			
			# Все должны быть Node2D или его наследниками
			assert_true(instance is Node2D, "Должен быть Node2D или его наследником")
			
			instance.queue_free()
