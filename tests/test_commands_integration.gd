# test_commands_integration.gd
extends GutTest

class TestTank:
	extends Node2D
	var move_direction: Vector2 = Vector2.ZERO
	var rotation_direction = null
	var fire_called: bool = false
	var ammo_type = null
	var target_pos: Vector2 = Vector2.ZERO
	
	func move(direction: Vector2):
		move_direction = direction
	
	func rotating(direction):
		rotation_direction = direction
	
	func fire():
		fire_called = true
	
	func switch_ammo_type(type):
		ammo_type = type
	
	func rotating_to(pos: Vector2):
		target_pos = pos

func test_command_system_integration():
	# Тест 1: Полная система команд с танком
	var tank = TestTank.new()
	
	# Создаем команды
	var move_cmd = MoveCommand.new().init(Vector2.RIGHT)
	var rotate_cmd = RotateCommand.new().init(-1)  # LEFT
	var shoot_cmd = ShootCommand.new().init()
	var ammo_cmd = SwitchAmmoCommand.new().init(1)  # HE
	var rotate_to_cmd = RotateToCommand.new().init(Vector2(500, 300))
	
	# Выполняем команды
	move_cmd.execute(tank)
	assert_eq(tank.move_direction, Vector2.RIGHT, "Танк должен двигаться вправо")
	
	rotate_cmd.execute(tank)
	assert_eq(tank.rotation_direction, -1, "Танк должен вращаться влево")
	
	shoot_cmd.execute(tank)
	assert_true(tank.fire_called, "Танк должен выстрелить")
	
	ammo_cmd.execute(tank)
	assert_eq(tank.ammo_type, 1, "Танк должен сменить боеприпасы на HE")
	
	rotate_to_cmd.execute(tank)
	assert_eq(tank.target_pos, Vector2(500, 300), "Танк должен повернуться к цели")

func test_command_serialization_roundtrip():
	# Тест 2: Сериализация и десериализация команды
	var original_command = MoveCommand.new().init(Vector2(0.7, -0.3))
	original_command.entity_id = "TestID"
	original_command.timestamp = 12345.67
	
	# Сериализуем
	var data = original_command.serialize()
	
	# Десериализуем
	var restored_command = MoveCommand.deserialize(data)
	
	# Проверяем
	assert_not_null(restored_command, "Должен восстановиться из данных")
	assert_eq(restored_command.entity_id, "TestID", "entity_id должен восстановиться")
	assert_eq(restored_command.timestamp, 12345.67, "timestamp должен восстановиться")
	assert_almost_eq(restored_command.direction.x, 0.7, 0.001, "direction.x должен восстановиться")
	assert_almost_eq(restored_command.direction.y, -0.3, 0.001, "direction.y должен восстановиться")

func test_command_polymorphism():
	# Тест 3: Полиморфизм команд
	var commands: Array[Command] = [
		MoveCommand.new().init(Vector2.UP),
		RotateCommand.new().init(1),  # RIGHT
		ShootCommand.new().init(),
		SwitchAmmoCommand.new().init(2),  # HEAT
		RotateToCommand.new().init(Vector2.ZERO)
	]
	
	var tank = TestTank.new()
	
	# Все команды должны иметь общий интерфейс
	for command in commands:
		assert_has_method(command, "execute", "Все команды должны иметь метод execute")
		assert_has_method(command, "serialize", "Все команды должны иметь метод serialize")
		
		# Не должно быть ошибок при выполнении
		command.execute(tank)
	
	# Проверяем, что все команды отработали
	assert_true(tank.move_direction != Vector2.ZERO, "MoveCommand должен был выполниться")
	assert_eq(tank.rotation_direction, 1, "Последняя команда вращения должна быть RIGHT")
	assert_true(tank.fire_called, "ShootCommand должен был выполниться")
	assert_eq(tank.ammo_type, 2, "SwitchAmmoCommand должен был выполниться")

func test_command_timestamp():
	# Тест 4: Уникальность timestamp
	var cmd1 = MoveCommand.new().init(Vector2.RIGHT)
	await get_tree().create_timer(0.01).timeout  # Небольшая задержка
	var cmd2 = MoveCommand.new().init(Vector2.LEFT)
	
	assert_ne(cmd1.timestamp, cmd2.timestamp, "Команды должны иметь разные timestamp")
	assert_true(cmd2.timestamp > cmd1.timestamp, "Более поздняя команда должна иметь больший timestamp")
