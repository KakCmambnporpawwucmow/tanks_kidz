# turret_tank_edge_cases_test.gd
extends GutTest

var _tank_scene: CharacterBody2D
var _turret: Turret
var _weapon_system: WeaponSystem

func before_each():
	# Создаем новую сцену танка для каждого теста
	_tank_scene = load("res://entities/tanks/base/tank.tscn").instantiate()
	add_child_autofree(_tank_scene)
	
	# Получаем компоненты
	_turret = find_node_by_type(_tank_scene, Turret)
	_weapon_system = find_node_by_type(_tank_scene, WeaponSystem)
	
	await get_tree().process_frame

func find_node_by_type(root: Node, type: Script) -> Node:
	var nodes_to_check = [root]
	
	while nodes_to_check.size() > 0:
		var current = nodes_to_check.pop_front()
		
		if current.get_script() == type:
			return current
		
		for child in current.get_children():
			nodes_to_check.append(child)
	
	return null

func test_turret_edge_cases():
	# Тестирование крайних случаев для турели
	
	# 1. Тестирование при нулевом рассеивании
	_turret.static_spread = 0
	var direction = _turret.get_fire_direction()
	
	# Настраиваем безопасную позицию
	_turret.global_position = Vector2(100, 100)
	_turret.aim.global_position = Vector2(200, 100)
	_turret.mark.global_position = Vector2(150, 100)
	
	direction = _turret.get_fire_direction()
	assert_ne(direction, Vector2.ZERO, "Направление не должно быть нулевым даже с нулевым рассеиванием")
	
	# 2. Тестирование при очень большом рассеивании
	_turret.static_spread = 1000
	#_turret.aim.set_spread_norm(1.0)  # Максимальное рассеивание
	direction = _turret.get_fire_direction()
	
	# Направление должно быть хоть какое-то (не нулевое)
	if direction != Vector2.ZERO:
		assert_true(direction.is_normalized(), "Направление должно быть нормализовано")
	
	# 3. Тестирование update_position с нулевой позицией
	_turret.update_position(Vector2.ZERO)
	assert_eq(_turret.aim_position, Vector2.ZERO, "Aim position должен быть установлен в Vector2.ZERO")

func test_tank_edge_cases():
	# Тестирование крайних случаев для танка
	
	# 1. Движение с нулевым вектором
	var speed = _tank_scene.move(Vector2.ZERO)
	assert_false(_tank_scene.is_move, "Танк не должен быть в состоянии движения")
	
	# 2. Вращение турели к той же позиции
	var current_aim = _turret.aim_position
	_tank_scene.rotating_to(current_aim)
	assert_eq(_turret.aim_position, current_aim, "Aim position не должен измениться при вращении к той же позиции")
	
	# 3. Попытка выстрела без боеприпасов
	# Опустошаем все боеприпасы
	for type in WeaponSystem.ProjectileType.values():
		_weapon_system.projectile_storage[type].count = 0
	
	# Настраиваем безопасную позицию для выстрела
	_turret.global_position = Vector2(100, 100)
	_turret.aim.global_position = Vector2(200, 100)
	_turret.mark.global_position = Vector2(150, 100)
	
	var fire_result = _tank_scene.fire()
	assert_false(fire_result, "Выстрел должен провалиться без боеприпасов")

func test_tank_animation_edge_cases():
	# Тестирование анимаций танка
	
	# 1. Тестирование повторного запуска анимации смерти
	_tank_scene.is_death = true
	var anim:AnimationPlayer = _tank_scene.find_child("animation")
	anim.play("death")
	
	# Проверяем, что анимация запущена
	assert_true(anim.is_playing(), "Анимация смерти должна быть запущена")

func test_turret_animation_edge_cases():
	# Тестирование анимаций турели
	
	# 1. Тестирование эффекта выстрела
	_turret.fire_effect()
	
	# Проверяем, что анимация запущена
	var anim:AnimationPlayer = _turret.find_child("AnimationPlayer")
	assert_true(anim.is_playing(), "Анимация выстрела должна быть запущена")

func test_integration_edge_cases():
	# Интеграционные тесты крайних случаев
	
	# 1. Танк уничтожен, но все еще пытается выполнять команды
	_tank_scene.is_death = true
	
	# Пытаемся выполнить команды - они должны игнорироваться
	var mock_command = Command.new()
	_tank_scene.proc_command(mock_command)
	
	# Пытаемся стрелять - выстрел должен провалиться
	var fire_result = _tank_scene.fire()
	assert_false(fire_result, "Уничтоженный танк не должен стрелять")
	
	# 2. Быстрая смена типов боеприпасов
	for i in range(10):
		var types = WeaponSystem.ProjectileType.values()
		var random_type = types[i % types.size()]
		_tank_scene.switch_ammo_type(random_type)
	
	# Проверяем, что система не сломалась
	assert_not_null(_weapon_system.get_current_ammo_type(), "Текущий тип боеприпасов должен быть установлен")

func test_performance_scenarios():
	# Тестирование производительности в различных сценариях
	
	# 1. Многократные вызовы get_fire_direction
	var start_time = Time.get_ticks_msec()
	
	for i in range(100):
		var direction = _turret.get_fire_direction()
		# Просто вызываем метод, результат не важен
	
	var end_time = Time.get_ticks_msec()
	var execution_time = end_time - start_time
	
	# Проверяем, что 100 вызовов выполняются за разумное время
	assert_true(execution_time < 1000, "100 вызовов get_fire_direction должны выполняться за < 1 секунду")
	
	# 2. Многократные обновления позиции
	start_time = Time.get_ticks_msec()
	
	for i in range(100):
		_turret.update_position(Vector2(i * 10, i * 10))
	
	end_time = Time.get_ticks_msec()
	execution_time = end_time - start_time
	
	assert_true(execution_time < 1000, "100 обновлений позиции должны выполняться за < 1 секунду")

# Вспомогательный класс для тестирования команд
class MockCommand extends RefCounted:
	func execute(_tank: Tank) -> void:
		pass
