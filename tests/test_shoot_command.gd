# test_shoot_command.gd
extends GutTest

class MockTankShoot:
	extends Node
	var fire_called: bool = false
	var fire_count: int = 0
	
	func fire():
		fire_called = true
		fire_count += 1

var mock_tank: MockTankShoot

func before_each():
	mock_tank = MockTankShoot.new()
	add_child(mock_tank)

func after_each():
	if mock_tank:
		mock_tank.queue_free()

func test_shoot_command_init():
	# Тест 1: Инициализация ShootCommand
	var command = ShootCommand.new().init()
	assert_eq(command.entity_id, "ShootCommand", "entity_id должен быть 'ShootCommand'")
	assert_true(command.timestamp > 0, "timestamp должен быть установлен (текущее время)")

func test_shoot_command_execute():
	# Тест 2: Выполнение команды выстрела
	var command = ShootCommand.new().init()
	command.execute(mock_tank)
	
	assert_true(mock_tank.fire_called, "Метод fire должен быть вызван")
	assert_eq(mock_tank.fire_count, 1, "Счетчик выстрелов должен увеличиться")
	
	# Тест 3: Несколько выстрелов
	command.execute(mock_tank)
	command.execute(mock_tank)
	assert_eq(mock_tank.fire_count, 3, "Должны учитываться все вызовы")

func test_shoot_command_serialize():
	# Тест 4: Сериализация
	var command = ShootCommand.new().init()
	var data = command.serialize()
	
	assert_eq(data["entity_id"], "ShootCommand", "Должен содержать правильный entity_id")
	assert_typeof(data["timestamp"], TYPE_FLOAT, "timestamp должен быть числом")
	assert_true(data["timestamp"] > 0, "timestamp должен быть положительным")
