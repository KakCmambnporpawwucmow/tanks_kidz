# weapon_system_test.gd
extends GutTest

var _tank_scene: Node
var _weapon_system: WeaponSystem
var _test_projectiles_parent: Node
var _real_projectile_scene: PackedScene

func before_all():
	# Загружаем ресурсы один раз
	_real_projectile_scene = load("res://entities/projectiles/projectile.tscn")
	assert_not_null(_real_projectile_scene, "Должен загружаться реальный снаряд")

func before_each():
	# Создаем новую сцену танка для каждого теста
	_tank_scene = load("res://entities/tanks/base/tank.tscn").instantiate()
	add_child_autofree(_tank_scene)
	
	# Находим WeaponSystem в иерархии танка
	_weapon_system = find_node_by_type(_tank_scene, WeaponSystem)
	assert_not_null(_weapon_system, "WeaponSystem должен быть в сцене танка")
	
	# Создаем тестового родителя для снарядов
	_test_projectiles_parent = Node.new()
	add_child_autofree(_test_projectiles_parent)
	_weapon_system.projectiles_parent = _test_projectiles_parent
	
	# Устанавливаем реальные снаряды
	_setup_real_ammo()
	
	# Инициализируем WeaponSystem
	_weapon_system._ready()
	
	# Сбрасываем таймеры
	_weapon_system.last_reload_time = 0
	_weapon_system.current_ammo_type = WeaponSystem.ProjectileType.AP

func find_node_by_type(root: Node, type: Script) -> Node:
	var nodes_to_check = [root]
	
	while nodes_to_check.size() > 0:
		var current = nodes_to_check.pop_front()
		
		if current.get_script() == type:
			return current
		
		for child in current.get_children():
			nodes_to_check.append(child)
	
	return null

func _setup_real_ammo():
	# Используем реальные сцены снарядов
	_weapon_system.ap_round = _real_projectile_scene
	_weapon_system.he_round = _real_projectile_scene
	_weapon_system.heat_round = _real_projectile_scene
	_weapon_system.missile_round = _real_projectile_scene

func test_weapon_system_initialization():
	# Проверка инициализации в контексте танка
	assert_eq(_weapon_system.initial_ap_rounds, 20, "AP rounds должны быть 20")
	assert_eq(_weapon_system.initial_he_rounds, 10, "HE rounds должны быть 10")
	assert_eq(_weapon_system.initial_heat_rounds, 5, "HEAT rounds должны быть 5")
	assert_eq(_weapon_system.initial_missile_rounds, 2, "Missile rounds должны быть 2")
	
	# Проверка загрузки боеприпасов
	assert_eq(_weapon_system.get_proj_count(WeaponSystem.ProjectileType.AP), 20)
	assert_eq(_weapon_system.get_proj_count(WeaponSystem.ProjectileType.HE), 10)
	assert_eq(_weapon_system.get_proj_count(WeaponSystem.ProjectileType.HEAT), 5)
	assert_eq(_weapon_system.get_proj_count(WeaponSystem.ProjectileType.MISSILE), 2)

func test_can_fire_with_ammo():
	await wait_seconds(2) # ждём уверенного релоада
	# Тестирование can_fire когда есть боеприпасы
	assert_true(_weapon_system.can_fire(WeaponSystem.ProjectileType.AP), 
		"Должна быть возможность стрелять когда есть боеприпасы")

func test_can_fire_when_reloading():
	# Симулируем перезарядку
	_weapon_system.last_reload_time = Time.get_ticks_msec()
	_weapon_system.reload_time_ms = 1000
	
	assert_false(_weapon_system.can_fire(WeaponSystem.ProjectileType.AP),
		"Не должно быть возможности стрелять во время перезарядки")
	
	# Проверяем, что после перезарядки снова можно стрелять
	await get_tree().create_timer(1.1).timeout
	assert_true(_weapon_system.can_fire(WeaponSystem.ProjectileType.AP),
		"Должна быть возможность стрелять после перезарядки")

func test_can_fire_no_ammo():
	# Устанавливаем 0 боеприпасов
	_weapon_system.projectile_storage[WeaponSystem.ProjectileType.AP].count = 0
	
	assert_false(_weapon_system.can_fire(WeaponSystem.ProjectileType.AP),
		"Не должно быть возможности стрелять без боеприпасов")

func test_fire_projectile_success():
	# Тестирование успешного выстрела реальным снарядом
	var initial_count = _weapon_system.get_proj_count(WeaponSystem.ProjectileType.AP)
	var position = Vector2(100, 100)
	var direction = Vector2(1, 0)
	_weapon_system.reload_time_ms = 500
	
	var result = _weapon_system.fire_projectile(position, direction)
	
	assert_true(result, "Выстрел должен быть успешным")
	assert_eq(_weapon_system.get_proj_count(WeaponSystem.ProjectileType.AP), initial_count - 1,
		"Количество боеприпасов должно уменьшиться на 1")
	
	# Даем время на создание и активацию снаряда
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Проверяем, что снаряд был создан
	var projectiles = _test_projectiles_parent.get_children()
	assert_eq(projectiles.size(), 1, "Должен быть создан один снаряд")
	
	var projectile = projectiles[0]
	assert_not_null(projectile, "Снаряд не должен быть null")
	
	# Проверяем, что это реальный снаряд
	assert_true(projectile is Area2D or projectile is Node2D, 
		"Снаряд должен быть Node2D или производным")

func test_fire_projectile_no_ammo():
	# Устанавливаем 0 боеприпасов
	_weapon_system.projectile_storage[WeaponSystem.ProjectileType.AP].count = 0
	
	var result = _weapon_system.fire_projectile(Vector2.ZERO, Vector2.RIGHT)
	
	assert_false(result, "Выстрел должен провалиться без боеприпасов")
	await get_tree().process_frame
	
	assert_eq(_test_projectiles_parent.get_children().size(), 0,
		"Не должно быть создано снарядов")

func test_fire_multiple_projectiles():
	# Тестирование нескольких последовательных выстрелов
	var shots_to_fire = 5
	var initial_count = _weapon_system.get_proj_count(WeaponSystem.ProjectileType.AP)
	_weapon_system.reload_time_ms = 1
	
	for i in range(shots_to_fire):
		var result = _weapon_system.fire_projectile(
			Vector2(i * 50, 0), 
			Vector2.RIGHT
		)
		assert_true(result, "Выстрел %d должен быть успешным" % i)
		await wait_frames(2)
	
	# Проверяем оставшиеся боеприпасы
	assert_eq(_weapon_system.get_proj_count(WeaponSystem.ProjectileType.AP), 
		initial_count - shots_to_fire,
		"Количество боеприпасов должно уменьшиться на %d" % shots_to_fire)

func test_switch_ammo_type_success():
	# Тестирование успешной смены типа боеприпасов
	var result = _weapon_system.switch_ammo_type(WeaponSystem.ProjectileType.HE)
	
	assert_true(result, "Смена боеприпасов должна быть успешной")
	assert_eq(_weapon_system.get_current_ammo_type(), WeaponSystem.ProjectileType.HE,
		"Текущий тип боеприпасов должен измениться на HE")

func test_switch_ammo_type_no_ammo():
	# Устанавливаем 0 боеприпасов для HE
	_weapon_system.projectile_storage[WeaponSystem.ProjectileType.HE].count = 0
	
	var result = _weapon_system.switch_ammo_type(WeaponSystem.ProjectileType.HE)
	
	assert_false(result, "Смена боеприпасов должна провалиться")
	assert_ne(_weapon_system.get_current_ammo_type(), WeaponSystem.ProjectileType.HE,
		"Текущий тип боеприпасов не должен измениться")

func test_consume_ammo():
	var initial_count = _weapon_system.get_proj_count(WeaponSystem.ProjectileType.AP)
	
	var result = _weapon_system.consume_ammo(WeaponSystem.ProjectileType.AP)
	
	assert_true(result, "Потребление боеприпасов должно быть успешным")
	assert_eq(_weapon_system.get_proj_count(WeaponSystem.ProjectileType.AP), initial_count - 1,
		"Количество боеприпасов должно уменьшиться на 1")

func test_reload_ammo():
	# Потребляем немного боеприпасов
	_weapon_system.consume_ammo(WeaponSystem.ProjectileType.AP)
	_weapon_system.consume_ammo(WeaponSystem.ProjectileType.AP)
	var count_before_reload = _weapon_system.get_proj_count(WeaponSystem.ProjectileType.AP)
	
	var result = _weapon_system.reload_ammo(WeaponSystem.ProjectileType.AP, 5)
	assert_eq(result, _weapon_system.get_proj_max_load(WeaponSystem.ProjectileType.AP), "Должно быть добавлено до максимума")

func test_reload_ammo_above_max():
	# Устанавливаем текущее количество близко к максимуму
	_weapon_system.projectile_storage[WeaponSystem.ProjectileType.AP].count = 18
	_weapon_system.projectile_storage[WeaponSystem.ProjectileType.AP].max_load = 20
	
	var result = _weapon_system.reload_ammo(WeaponSystem.ProjectileType.AP, 5)
	
	assert_eq(result, 20, "Количество не должно превышать максимум")
	assert_eq(_weapon_system.get_proj_count(WeaponSystem.ProjectileType.AP), 20)

func test_check_ammo_switches_when_empty():
	# Опустошаем текущие боеприпасы
	_weapon_system.projectile_storage[WeaponSystem.ProjectileType.AP].count = 0
	
	var result = _weapon_system.check_ammo()
	
	assert_true(result, "check_ammo должна вернуть true при успешной смене")
	assert_ne(_weapon_system.get_current_ammo_type(), WeaponSystem.ProjectileType.AP,
		"Должен переключиться на другой тип боеприпасов")

func test_check_ammo_all_empty():
	# Опустошаем все типы боеприпасов
	for type in WeaponSystem.ProjectileType.values():
		_weapon_system.projectile_storage[type].count = 0
	
	var result = _weapon_system.check_ammo()
	
	assert_false(result, "check_ammo должна вернуть false когда все боеприпасы кончились")
	
	# Проверяем, что выводится сообщение об отсутствии боеприпасов
	# (это можно проверить через перехват вывода, но для простоты проверяем состояние)
	assert_eq(_weapon_system.get_proj_count(_weapon_system.current_ammo_type), 0,
		"Все типы боеприпасов должны быть на 0")

func test_send_update_signal():
	# Тестирование сигнала send_update с реальной системой
	var signal_called = [false]
	var call_data = {"count": 0}
	
	_weapon_system.send_update.connect(func(): 
		signal_called[0] = true
		call_data["count"] += 1
	)
	
	# Вызываем метод, который должен испускать сигнал
	_weapon_system.switch_ammo_type(WeaponSystem.ProjectileType.HE)
	await wait_seconds(0.5)
	assert_true(signal_called[0], "Сигнал send_update должен быть испущен")
	assert_eq(call_data["count"], 1, "Сигнал должен быть вызван 1 раз")

func test_is_reloading():
	# Проверка состояния перезарядки
	_weapon_system.last_reload_time = Time.get_ticks_msec()
	_weapon_system.reload_time_ms = 100
	
	assert_true(_weapon_system.is_reloading(), "Должен быть в состоянии перезарядки")
	
	# Ждем больше времени перезарядки
	await wait_seconds(2.1)
	assert_false(_weapon_system.is_reloading(), "Не должен быть в состоянии перезарядки после таймера")

func test_integration_fire_and_switch():
	# Интеграционный тест: стрельба и автоматическое переключение
	_weapon_system.current_ammo_type = WeaponSystem.ProjectileType.AP
	_weapon_system.reload_time_ms = 10
	
	# Стреляем пока не кончатся AP
	for i in range(20):
		var result = _weapon_system.fire_projectile(Vector2(i * 10, 0), Vector2.RIGHT)
		assert_true(result, "Выстрел %d должен быть успешным" % i)
		await wait_seconds(0.1)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Проверяем автоматическое переключение
	assert_ne(_weapon_system.get_current_ammo_type(), WeaponSystem.ProjectileType.AP,
		"Должен автоматически переключиться после израсходования AP")
	
	var new_ammo_type = _weapon_system.get_current_ammo_type()
	var new_ammo_count = _weapon_system.get_proj_count(new_ammo_type)
	
	assert_true(new_ammo_count > 0, "У нового типа боеприпасов должно быть что-то в запасе")
	assert_true(_weapon_system.can_fire(new_ammo_type),
		"Должна быть возможность стрелять новым типом боеприпасов")

func test_projectile_activation():
	# Тестирование активации реального снаряда
	var position = Vector2(200, 200)
	var direction = Vector2(0, -1)
	
	var result = _weapon_system.fire_projectile(position, direction)
	assert_true(result, "Выстрел должен быть успешным")
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	var projectiles = _test_projectiles_parent.get_children()
	assert_eq(projectiles.size(), 1, "Должен быть создан один снаряд")
	
	var projectile = projectiles[0]
	
	# Проверяем базовые свойства реального снаряда
	assert_true(is_instance_valid(projectile), "Снаряд должен быть валидным экземпляром")
	assert_true(projectile.visible, "Снаряд должен быть видимым")
	
	# Проверяем, что снаряд был добавлен в правильного родителя
	assert_eq(projectile.get_parent(), _test_projectiles_parent,
		"Снаряд должен быть добавлен к projectiles_parent")

func after_each():
	# Вручную очищаем снаряды, если они еще не удалены
	for child in _test_projectiles_parent.get_children():
		if is_instance_valid(child):
			child.queue_free()
	
	await get_tree().process_frame
	# Объекты будут автоматически удалены через add_child_autofree()
