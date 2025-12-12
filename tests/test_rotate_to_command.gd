# test_rotate_to_command.gd
extends GutTest

class MockTankRotateTo:
	extends Node
	var last_target_pos: Vector2 = Vector2.ZERO
	var rotate_to_called: bool = false
	
	func rotating_to(target_pos: Vector2):
		last_target_pos = target_pos
		rotate_to_called = true

var mock_tank: MockTankRotateTo

func before_each():
	mock_tank = MockTankRotateTo.new()
	add_child(mock_tank)

func after_each():
	if mock_tank:
		mock_tank.queue_free()

func test_rotate_to_command_init():
	# Тест 1: Инициализация RotateToCommand
	var target_position = Vector2(100, 200)
	var command = RotateToCommand.new().init(target_position)
	
	assert_eq(command.entity_id, "RotateToCommand", "entity_id должен быть 'RotateToCommand'")
	assert_eq(command.target_pos, target_position, "target_pos должен быть установлен")
	
	# Тест 2: Разные позиции
	command.init(Vector2(-50, 300))
	assert_eq(command.target_pos, Vector2(-50, 300), "Должен поддерживать отрицательные координаты")

func test_rotate_to_command_execute():
	# Тест 3: Выполнение команды
	var target_pos = Vector2(150, 250)
	var command = RotateToCommand.new().init(target_pos)
	
	command.execute(mock_tank)
	assert_eq(mock_tank.last_target_pos, target_pos, "Танк должен получить команду повернуться к цели")
	assert_true(mock_tank.rotate_to_called, "Метод rotating_to должен быть вызван")
	
	# Тест 4: Несколько целей
	var new_target = Vector2(300, 400)
	command.init(new_target).execute(mock_tank)
	assert_eq(mock_tank.last_target_pos, new_target, "Должна обновиться целевая позиция")

func test_rotate_to_command_serialize():
	# Тест 5: Сериализация
	var command = RotateToCommand.new().init(Vector2(123.45, -67.89))
	var data = command.serialize()
	
	assert_eq(data["entity_id"], "RotateToCommand", "Должен содержать правильный entity_id")
	assert_eq(Vector2(data["target_pos"][0], data["target_pos"][1]), Vector2(123.45, -67.89), "target_pos должен сохраниться")
