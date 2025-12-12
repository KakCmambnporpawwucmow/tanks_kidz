# test_rotate_command.gd
extends GutTest

class MockTankRotate:
	extends Node
	var last_rotation_direction = null
	
	func rotating(direction):
		last_rotation_direction = direction

var mock_tank: MockTankRotate

func before_each():
	mock_tank = MockTankRotate.new()
	add_child(mock_tank)

func after_each():
	if mock_tank:
		mock_tank.queue_free()

func test_rotate_command_init():
	# Тест 1: Инициализация RotateCommand
	# Создаем enum для теста (имитация Tank.ERotate)
	const ERotate = {
		"LEFT": -1,
		"STOP": 0,
		"RIGHT": 1
	}
	
	var command = RotateCommand.new().init(ERotate.LEFT)
	assert_eq(command.entity_id, "RotateCommand", "entity_id должен быть 'RotateCommand'")
	assert_eq(command.rotation_direction, ERotate.LEFT, "rotation_direction должен быть установлен")
	
	# Тест 2: Другие направления
	command.init(ERotate.RIGHT)
	assert_eq(command.rotation_direction, ERotate.RIGHT, "Должен поддерживать поворот вправо")
	
	command.init(ERotate.STOP)
	assert_eq(command.rotation_direction, ERotate.STOP, "Должен поддерживать остановку вращения")

func test_rotate_command_execute():
	# Тест 3: Выполнение команды
	# Создаем enum внутри теста
	const ERotate = {"LEFT": -1, "STOP": 0, "RIGHT": 1}
	
	var command = RotateCommand.new().init(ERotate.LEFT)
	command.execute(mock_tank)
	assert_eq(mock_tank.last_rotation_direction, ERotate.LEFT, "Танк должен получить команду вращаться влево")
	
	command.init(ERotate.RIGHT)
	command.execute(mock_tank)
	assert_eq(mock_tank.last_rotation_direction, ERotate.RIGHT, "Танк должен получить команду вращаться вправо")
	
	command.init(ERotate.STOP)
	command.execute(mock_tank)
	assert_eq(mock_tank.last_rotation_direction, ERotate.STOP, "Танк должен получить команду остановить вращение")

func test_rotate_command_serialize():
	# Тест 4: Сериализация
	const ERotate = {"LEFT": -1, "RIGHT": 1}
	
	var command = RotateCommand.new().init(ERotate.LEFT)
	var data = command.serialize()
	
	assert_eq(data["entity_id"], "RotateCommand", "Должен содержать правильный entity_id")
	assert_eq(data["rotation_direction"], ERotate.LEFT, "rotation_direction должен сохраниться")
