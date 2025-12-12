# test_move_command.gd
extends GutTest

class MockTank:
	extends Node
	var last_move_direction: Vector2 = Vector2.ZERO
	
	func move(direction: Vector2):
		last_move_direction = direction

var mock_tank: MockTank

func before_each():
	mock_tank = MockTank.new()
	add_child(mock_tank)

func after_each():
	if mock_tank:
		mock_tank.queue_free()

func test_move_command_init():
	# Тест 1: Инициализация MoveCommand
	var command = MoveCommand.new().init(Vector2.RIGHT)
	assert_eq(command.entity_id, "MoveCommand", "entity_id должен быть 'MoveCommand'")
	assert_typeof(command.timestamp, TYPE_FLOAT, "timestamp должен быть числом")
	assert_eq(command.direction, Vector2.RIGHT, "direction должен быть установлен")

func test_move_command_execute():
	# Тест 2: Выполнение команды
	var command = MoveCommand.new().init(Vector2(1, 0))
	command.execute(mock_tank)
	
	assert_eq(mock_tank.last_move_direction, Vector2(1, 0), "Танк должен получить команду двигаться вправо")
	
	# Тест 3: Остановка
	command.init(Vector2.ZERO)
	command.execute(mock_tank)
	assert_eq(mock_tank.last_move_direction, Vector2.ZERO, "Танк должен получить команду остановиться")

func test_move_command_serialize():
	# Тест 4: Сериализация
	var command = MoveCommand.new().init(Vector2(0.5, -0.5))
	var data = command.serialize()
	
	assert_eq(data["entity_id"], "MoveCommand", "Должен содержать правильный entity_id")
	assert_has(data, "direction", "Должен содержать поле direction")
	assert_eq(Vector2(data["direction"]["x"], data["direction"]["y"]), Vector2(0.5, -0.5), "Направление должно сериализоваться правильно")

func test_move_command_deserialize():
	# Тест 5: Десериализация MoveCommand
	var test_data = {
		"entity_id": "MoveCommand123",
		"timestamp": 987654.0,
		"direction": {"x": -1.0, "y": 0.0},
		"type": "MoveCommand"
	}
	
	var command = MoveCommand.deserialize(test_data)
	assert_not_null(command, "Должен создаться MoveCommand")
	assert_eq(command.entity_id, "MoveCommand123", "entity_id должен загрузиться")
	assert_eq(command.timestamp, 987654.0, "timestamp должен загрузиться")
	assert_eq(command.direction, Vector2(-1.0, 0.0), "direction должен загрузиться")
	
	# Тест 6: Проверка выполнения после десериализации
	command.execute(mock_tank)
	assert_eq(mock_tank.last_move_direction, Vector2(-1.0, 0.0), "Десериализованная команда должна работать")
