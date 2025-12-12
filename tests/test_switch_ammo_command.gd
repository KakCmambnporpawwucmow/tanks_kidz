# test_switch_ammo_command.gd
extends GutTest

class MockTankAmmo:
	extends Node
	var last_ammo_type = null
	var switch_called_count: int = 0
	
	func switch_ammo_type(ammo_type):
		last_ammo_type = ammo_type
		switch_called_count += 1

var mock_tank: MockTankAmmo

func before_each():
	mock_tank = MockTankAmmo.new()
	add_child(mock_tank)

func after_each():
	if mock_tank:
		mock_tank.queue_free()

func test_switch_ammo_command_init():
	# Тест 1: Инициализация SwitchAmmoCommand
	# Создаем enum для теста (имитация WeaponSystem.ProjectileType)
	const ProjectileType = {
		"AP": 0,
		"HE": 1,
		"HEAT": 2,
		"MISSILE": 3
	}
	
	var command = SwitchAmmoCommand.new().init(ProjectileType.AP)
	assert_eq(command.entity_id, "SwitchAmmoCommand", "entity_id должен быть 'SwitchAmmoCommand'")
	assert_eq(command.ammo_type, ProjectileType.AP, "ammo_type должен быть установлен")
	
	# Тест 2: Разные типы боеприпасов
	command.init(ProjectileType.HE)
	assert_eq(command.ammo_type, ProjectileType.HE, "Должен поддерживать HE")
	
	command.init(ProjectileType.HEAT)
	assert_eq(command.ammo_type, ProjectileType.HEAT, "Должен поддерживать HEAT")
	
	command.init(ProjectileType.MISSILE)
	assert_eq(command.ammo_type, ProjectileType.MISSILE, "Должен поддерживать MISSILE")

func test_switch_ammo_command_execute():
	# Тест 3: Выполнение команды смены боеприпасов
	const ProjectileType = {"AP": 0, "HE": 1, "HEAT": 2, "MISSILE": 3}
	
	var command = SwitchAmmoCommand.new().init(ProjectileType.HE)
	command.execute(mock_tank)
	
	assert_eq(mock_tank.last_ammo_type, ProjectileType.HE, "Танк должен получить команду сменить на HE")
	assert_eq(mock_tank.switch_called_count, 1, "Счетчик вызовов должен увеличиться")
	
	# Тест 4: Смена нескольких типов
	command.init(ProjectileType.AP).execute(mock_tank)
	assert_eq(mock_tank.last_ammo_type, ProjectileType.AP, "Должен смениться на AP")
	assert_eq(mock_tank.switch_called_count, 2, "Должно быть 2 вызова")

func test_switch_ammo_command_serialize():
	# Тест 5: Сериализация
	const ProjectileType = {"HEAT": 2}
	
	var command = SwitchAmmoCommand.new().init(ProjectileType.HEAT)
	var data = command.serialize()
	
	assert_eq(data["entity_id"], "SwitchAmmoCommand", "Должен содержать правильный entity_id")
	assert_eq(data["ammo_type"], ProjectileType.HEAT, "ammo_type должен сохраниться")
