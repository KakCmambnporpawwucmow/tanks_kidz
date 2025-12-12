# test_ammo_statistic.gd
extends GutTest

class MockTank:
	extends Node2D
	var weapon_system = null
	func get_weapon_system():
		return weapon_system 
	
#class MockWeaponSystem:
	#extends Node
	#var current_ammo_type = 0
	#var ammo_counts = {0: 10, 1: 5, 2: 3, 3: 2}
	#
	#signal send_update
	#
	#func get_current_ammo_type():
		#return current_ammo_type
	#
	#func get_proj_count(ammo_type: int) -> int:
		#return ammo_counts.get(ammo_type, 0)
	#
	#func set_current_ammo_type(type: int):
		#current_ammo_type = type
		#send_update.emit()

var ammo_statistic: AmmoStatistic
var mock_tank: MockTank
var mock_weapon_system: WeaponSystem

func before_each():
	# Создаем mock объекты
	mock_tank = MockTank.new()
	mock_weapon_system = WeaponSystem.new()
	mock_weapon_system.ap_round = preload("res://entities/projectiles/ap_round.tscn")
	mock_tank.weapon_system = mock_weapon_system
	
	# Создаем AmmoStatistic
	ammo_statistic = AmmoStatistic.new()
	ammo_statistic.game_object = mock_tank
	
	# Создаем несколько AmmoState для тестирования
	for i in range(4):
		var ammo_state = AmmoState.new()
		ammo_state.ammo_type = i
		ammo_state.title = "TYPE_" + str(i)
		ammo_state.count = 0
		ammo_statistic.add_child(ammo_state)
	
	add_child(ammo_statistic)
	add_child(mock_tank)
	add_child(mock_weapon_system)

func after_each():
	if ammo_statistic:
		ammo_statistic.queue_free()
	if mock_tank:
		mock_tank.queue_free()
	if mock_weapon_system:
		mock_weapon_system.queue_free()

func test_ammo_statistic_initialization():
	# Тест 1: Проверка инициализации
	assert_not_null(ammo_statistic, "AmmoStatistic должен создаваться")
	assert_is(ammo_statistic, HBoxContainer, "Должен быть HBoxContainer")
	assert_is(ammo_statistic, AmmoStatistic, "Должен быть AmmoStatistic")
	
	# Тест 2: Должен иметь детей типа AmmoState
	var ammo_state_children = ammo_statistic.get_children().filter(func(node): return node is AmmoState)
	assert_eq(ammo_state_children.size(), 4, "Должен содержать 4 AmmoState")

func test_ready_method():
	# Тест 3: Проверка метода _ready
	ammo_statistic._ready()
	
	assert_eq(ammo_statistic.get_weapon_system(), mock_weapon_system, "weapon_system должен быть установлен")
	
	# Проверяем подключение сигнала
	assert_true(mock_weapon_system.send_update.is_connected(ammo_statistic.update),
		"Сигнал send_update должен быть подключен к update")

func test_update_method():
	# Тест 4: Проверка метода update
	ammo_statistic._ready()
	
	# Устанавливаем текущий тип боеприпасов
	mock_weapon_system.current_ammo_type = 1  # HE
	
	# Вызываем обновление
	ammo_statistic.update()
	
	# Проверяем, что только HE подсвечен
	for child in ammo_statistic.get_children():
		if child is AmmoState:
			if child.ammo_type == 1:
				assert_true(child.bold_state, "Текущий тип боеприпасов должен быть выделен")
			else:
				assert_false(child.bold_state, "Другие типы не должны быть выделены")
			
			# Проверяем количество
			var expected_count = mock_weapon_system.get_proj_count(child.ammo_type)
			assert_eq(child.count, expected_count, "Количество должно соответствовать weapon_system")

func test_update_signal():
	# Тест 5: Обновление по сигналу
	ammo_statistic._ready()
	
	# Изначально тип AP (0)
	mock_weapon_system.current_ammo_type = 0
	ammo_statistic.update()
	
	# Меняем тип через сигнал
	mock_weapon_system.switch_ammo_type(2)  # HEAT
	
	await wait_frames(2)
	
	# Проверяем, что update был вызван по сигналу
	var heath_ammo_state = ammo_statistic.get_children().filter(
		func(node): return node is AmmoState and node.ammo_type == 2
	)[0] as AmmoState
	
	assert_true(heath_ammo_state.bold_state, "HEAT должен быть выделен после сигнала")

func test_different_ammo_types():
	# Тест 6: Проверка разных типов боеприпасов
	ammo_statistic._ready()
	
	# Проходим по всем типам
	for ammo_type in range(4):
		mock_weapon_system.current_ammo_type = ammo_type
		ammo_statistic.update()
		
		for child in ammo_statistic.get_children():
			if child is AmmoState:
				if child.ammo_type == ammo_type:
					assert_true(child.bold_state, "Тип %d должен быть выделен" % ammo_type)
				else:
					assert_false(child.bold_state, "Тип %d не должен быть выделен" % child.ammo_type)

func test_ammo_counts_update():
	# Тест 7: Обновление количества боеприпасов
	ammo_statistic._ready()
	
	var old_count = mock_weapon_system.get_proj_count(0)
	# Меняем количество в weapon_system
	mock_weapon_system.consume_ammo(0)
	
	# Обновляем
	ammo_statistic.update()
	assert_eq(ammo_statistic.get_children()[0].count, old_count - 1, "Количество должно обновиться")

func test_empty_ammo_state():
	# Тест 8: Проверка с пустыми AmmoState
	var empty_stat = AmmoStatistic.new()
	empty_stat.game_object = mock_tank
	add_child(empty_stat)
	
	empty_stat._ready()
	
	# Не должно быть ошибок при пустых детях
	empty_stat.update()
	
	# Добавляем один AmmoState
	var ammo_state = AmmoState.new()
	ammo_state.ammo_type = 0
	empty_stat.add_child(ammo_state)
	
	empty_stat.update()
	
	assert_true(ammo_state.bold_state, "Без установки типа не должно быть выделения")
	
	empty_stat.queue_free()
