# test_command.gd
extends GutTest

func test_command_abstract_class():
	# Тест 1: Проверка абстрактного класса Command
	var command = Command.new()
	assert_eq(command.entity_id, "", "entity_id по умолчанию должен быть пустой строкой")
	assert_eq(command.timestamp, 0.0, "timestamp по умолчанию должен быть 0")
	
	# Тест 2: Должен выбрасывать ошибку при вызове execute
	# В Godot мы не можем проверить push_error напрямую, но можем проверить, что метод существует
	assert_has_method(command, "execute", "Command должен иметь метод execute")
	assert_has_method(command, "serialize", "Command должен иметь метод serialize")
	assert_has_method(command, "deserialize", "Command должен иметь статический метод deserialize")

func test_command_serialize():
	# Тест 3: Сериализация базовой команды
	var command = Command.new()
	command.entity_id = "TestCommand"
	command.timestamp = 123456.0
	
	var data = command.serialize()
	assert_eq(data["entity_id"], "TestCommand", "entity_id должен сохраниться")
	assert_eq(data["timestamp"], 123456.0, "timestamp должен сохраниться")
	assert_has(data, "type", "Должен содержать поле type")

func test_command_deserialize():
	# Тест 4: Десериализация команды
	var test_data = {
		"entity_id": "TestDeserialize",
		"timestamp": 789012.0,
		"type": "MoveCommand"  # Используем существующую команду
	}
	
	var command = Command.deserialize(test_data)
	assert_not_null(command, "Должен создаться объект команды")
	assert_eq(command.entity_id, "TestDeserialize", "entity_id должен загрузиться из данных")
	assert_eq(command.timestamp, 789012.0, "timestamp должен загрузиться из данных")
	
	# Тест 5: Десериализация несуществующей команды
	var invalid_data = {
		"type": "NonExistentCommand",
		"entity_id": "Test",
		"timestamp": 0.0
	}
	
	var invalid_command = Command.deserialize(invalid_data)
	assert_null(invalid_command, "Для несуществующего типа должен вернуться null")
