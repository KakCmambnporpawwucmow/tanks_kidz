# test_obstacle.gd
extends GutTest

var obstacle: Obstacle
var mock_health_component: HealthComponent

func before_each():
	# Создаем Obstacle
	obstacle = Obstacle.new()
	
	# Создаем mock HealthComponent
	mock_health_component = HealthComponent.new()
	mock_health_component.max_health = 50
	mock_health_component.auto_destroy_on_death = false
	
	# Добавляем HealthComponent как дочерний узел
	obstacle.add_child(mock_health_component)
	obstacle.health = mock_health_component
	
	add_child(obstacle)

func after_each():
	if obstacle:
		obstacle.queue_free()

func test_obstacle_initialization():
	# Тест 1: Проверка инициализации
	assert_not_null(obstacle, "Obstacle должен создаваться")
	assert_is(obstacle, Node2D, "Должен быть Node2D")
	assert_is(obstacle, Obstacle, "Должен быть Obstacle")
	
	# Тест 2: Проверка наличия HealthComponent
	assert_not_null(obstacle.health, "HealthComponent должен быть установлен")
	assert_eq(obstacle.health, mock_health_component, "Должен ссылаться на правильный HealthComponent")

func test_get_health_method():
	# Тест 3: Метод get_health
	var health_component = obstacle.get_health()
	assert_not_null(health_component, "get_health должен возвращать HealthComponent")
	assert_eq(health_component, mock_health_component, "Должен возвращать установленный HealthComponent")
	assert_is(health_component, HealthComponent, "Должен возвращать HealthComponent")

func test_obstacle_without_health():
	# Тест 4: Obstacle без HealthComponent
	var obstacle_no_health = Obstacle.new()
	add_child(obstacle_no_health)
	
	# Не должно быть ошибок
	assert_null(obstacle_no_health.health, "health должен быть null если не установлен")
	assert_null(obstacle_no_health.get_health(), "get_health должен возвращать null если health не установлен")
	
	obstacle_no_health.queue_free()

func test_obstacle_scene_loading():
	# Тест 5: Загрузка сцены obstacle.tscn
	var obstacle_scene = load("res://entities/obstacles/obstacle.tscn")
	assert_not_null(obstacle_scene, "Сцена obstacle должна загружаться")
	
	var instance = obstacle_scene.instantiate()
	assert_not_null(instance, "Должен создаться экземпляр")
	assert_is(instance, Obstacle, "Должен быть Obstacle")
	
	# Проверяем структуру
	assert_true(instance.get_child_count() > 0, "Должен иметь дочерние элементы")
	
	# Проверяем наличие Sprite2D
	var view = instance.find_child("view") as Sprite2D
	assert_not_null(view, "Должен содержать Sprite2D 'view'")
	
	instance.queue_free()

func test_obstacle_inheritance():
	# Тест 6: Проверка наследования
	var obstacle_class = load("res://entities/obstacles/obstacle.gd")
	assert_not_null(obstacle_class, "Скрипт obstacle.gd должен загружаться")
	
	var instance = obstacle_class.new()
	assert_is(instance, Node2D, "Должен наследоваться от Node2D")
	assert_true(instance.has_method("get_health"), "Должен иметь метод get_health")
	
	instance.queue_free()
