# test_command_producer.gd
extends GutTest

class MockReceiver:
	extends Node2D
	var received_commands: Array[Command] = []
	var proc_command_called: bool = false
	
	func proc_command(command: Command):
		received_commands.append(command)
		proc_command_called = true

var command_producer: CommandProducer
var mock_receiver: MockReceiver

func before_each():
	command_producer = CommandProducer.new()
	mock_receiver = MockReceiver.new()
	
	command_producer.add_receiver(mock_receiver)
	add_child(command_producer)
	add_child(mock_receiver)

func after_each():
	if command_producer:
		command_producer.queue_free()
	if mock_receiver:
		mock_receiver.queue_free()

func test_command_producer_initialization():
	# Тест 1: Инициализация CommandProducer
	assert_not_null(command_producer, "CommandProducer должен создаваться")
	assert_has_method(command_producer, "add_receiver", "Должен иметь метод add_receiver")
	
	# Тест 2: Должен создавать команды при инициализации
	assert_not_null(command_producer.tankMoveCommand, "Должен создать MoveCommand")
	assert_not_null(command_producer.tankRotateCommand, "Должен создать RotateCommand")
	assert_not_null(command_producer.tankFireCommand, "Должен создать ShootCommand")
	assert_not_null(command_producer.tankSwitchAmmoCommand, "Должен создать SwitchAmmoCommand")
	assert_not_null(command_producer.rotateToCommand, "Должен создать RotateToCommand")

func test_add_receiver():
	# Тест 3: Добавление получателя
	var new_receiver = MockReceiver.new()
	add_child(new_receiver)
	
	var result = command_producer.add_receiver(new_receiver)
	assert_true(result, "add_receiver должен вернуть true для валидного получателя")
	assert_eq(command_producer.get_receivers_count(), 2, "Должен добавить получателя в массив")
	
	# Тест 4: Добавление невалидного получателя
	var invalid_node = Node2D.new()  # Без метода proc_command
	add_child(invalid_node)
	
	result = command_producer.add_receiver(invalid_node)
	assert_false(result, "add_receiver должен вернуть false для невалидного получателя")
	assert_eq(command_producer.get_receivers_count(), 2, "Не должен добавлять невалидный узел")
	
	invalid_node.queue_free()

func test_input_handling():
	# Тест 5: Обработка ввода - движение вперед
	var event = InputEventAction.new()
	event.action = "move_forward"
	event.pressed = true
	
	command_producer._input(event)
	
	assert_eq(mock_receiver.received_commands.size(), 1, "Получатель должен получить команду")
	assert_is(mock_receiver.received_commands[0], MoveCommand, "Должен быть MoveCommand")
	
	# Тест 6: Остановка движения
	var stop_event = InputEventAction.new()
	stop_event.action = "move_forward"
	stop_event.pressed = false
	
	command_producer._input(stop_event)
	assert_eq(mock_receiver.received_commands.size(), 2, "Должна добавиться команда остановки")

func test_different_commands():
	# Тест 7: Разные типы команд
	# Вращение влево
	var rotate_event = InputEventAction.new()
	rotate_event.action = "rotate_left"
	rotate_event.pressed = true
	command_producer._input(rotate_event)
	
	# Выстрел
	var fire_event = InputEventAction.new()
	fire_event.action = "fire"
	fire_event.pressed = true
	command_producer._input(fire_event)
	
	# Смена боеприпасов
	var ammo_event = InputEventAction.new()
	ammo_event.action = "ammo_ap"
	ammo_event.pressed = true
	command_producer._input(ammo_event)
	
	assert_eq(mock_receiver.received_commands.size(), 3, "Должны обработаться все команды")
	assert_is(mock_receiver.received_commands[0], RotateCommand, "Первая команда должна быть RotateCommand")
	assert_is(mock_receiver.received_commands[1], ShootCommand, "Вторая команда должна быть ShootCommand")
	assert_is(mock_receiver.received_commands[2], SwitchAmmoCommand, "Третья команда должна быть SwitchAmmoCommand")

func test_invalid_receiver_filtering():
	# Тест 8: Фильтрация невалидных получателей
	var invalid_receiver = Node2D.new()  # Без proc_command
	command_producer.add_receiver(invalid_receiver)
	
	# Создаем событие
	var event = InputEventAction.new()
	event.action = "move_forward"
	event.pressed = true
	
	# Должен отфильтровать невалидного получателя
	command_producer._input(event)
	
	# Проверяем, что невалидный получатель был удален
	assert_eq(command_producer.get_receivers_count(), 1, "Должен удалить невалидного получателя")
	assert_eq(command_producer.get_receiver(0), mock_receiver, "Должен остаться только валидный получатель")
	
	invalid_receiver.queue_free()

func test_mouse_input():
	# Тест 9: Обработка движения мыши
	var mouse_event = InputEventMouseMotion.new()
	var glob_pos = command_producer.get_global_mouse_position()
	mouse_event.global_position = glob_pos
	
	command_producer._input(mouse_event)
	
	assert_eq(mock_receiver.received_commands.size(), 1, "Должна обработаться команда от мыши")
	assert_is(mock_receiver.received_commands[0], RotateToCommand, "Должен быть RotateToCommand")
	
	var rotate_command = mock_receiver.received_commands[0] as RotateToCommand
	assert_eq(rotate_command.target_pos, glob_pos, "Целевая позиция должна быть позицией мыши")
