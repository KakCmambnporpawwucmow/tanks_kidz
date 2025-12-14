# turret_tank_test.gd
extends GutTest

var _tank_scene: Tank
var _turret: Turret
var _weapon_system: WeaponSystem
var _move_component: BaseMoveComponent
var _health_component: HealthComponent

var _mock_move_component: BaseMoveComponent
var _mock_weapon_system: WeaponSystem
var _real_projectile_scene: PackedScene

func before_all():
	# Загружаем необходимые ресурсы
	_real_projectile_scene = load("res://entities/projectiles/projectile.tscn")
	assert_not_null(_real_projectile_scene, "Должен загружаться реальный снаряд")

func before_each():
	# Создаем новую сцену танка для каждого теста
	_tank_scene = load("res://entities/tanks/base/tank.tscn").instantiate()
	add_child_autofree(_tank_scene)
	
	# Получаем компоненты из танка
	_turret = find_node_by_type(_tank_scene, Turret)
	_weapon_system = find_node_by_type(_tank_scene, WeaponSystem)
	_move_component = find_node_by_type(_tank_scene, BaseMoveComponent)
	_health_component = find_node_by_type(_tank_scene, HealthComponent)
	
	assert_not_null(_turret, "Turret должен быть в сцене танка")
	assert_not_null(_weapon_system, "WeaponSystem должен быть в сцене танка")
	assert_not_null(_move_component, "BaseMoveComponent должен быть в сцене танка")
	assert_not_null(_health_component, "HealthComponent должен быть в сцене танка")
	_weapon_system.projectiles_parent = self
	# Настраиваем снаряды для тестов
	_setup_real_ammo()
	
	# Даем время на инициализацию
	await get_tree().process_frame
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

func _setup_real_ammo():
	_weapon_system.ap_round = _real_projectile_scene
	_weapon_system.he_round = _real_projectile_scene
	_weapon_system.heat_round = _real_projectile_scene
	_weapon_system.missile_round = _real_projectile_scene
	_weapon_system._ready()

# ================ TURRET TESTS ================

func test_turret_initialization():
	# Проверка инициализации турели
	assert_not_null(_turret.mover, "Turret должен иметь mover компонент")
	assert_eq(_turret.static_spread, 20, "Static spread должен быть 20")
	assert_false(_turret.is_moving, "Изначально не должен быть в движении")
	assert_eq(_turret.last_position, _turret.global_position, "Last position должен быть равен текущей позиции")

func test_turret_check_movement():
	# Сохраняем начальную позицию
	var initial_position = _turret.global_position
	_turret.last_position = initial_position
	
	# Проверяем, что при небольшом движении не срабатывает
	_turret.global_position = initial_position + Vector2(5, 5)
	_turret.check_movement()
	
	assert_eq(_turret.last_position, initial_position, "Last position не должен измениться при малом движении")
	
	# Проверяем срабатывание при значительном движении
	_turret.movement_threshold = 5.0
	_turret.global_position = initial_position + Vector2(20, 20)
	_turret.check_movement()
	
	assert_eq(_turret.last_position, _turret.global_position, "Last position должен обновиться при движении")

func test_turret_get_fire_direction():
	# Настраиваем позиции для теста
	var turret_pos = Vector2(100, 100)
	var aim_pos = Vector2(200, 100)
	var mark_pos = Vector2(150, 100)
	
	_turret.global_position = turret_pos
	_turret.aim.global_position = aim_pos
	_turret.mark.global_position = mark_pos
	
	# Получаем направление выстрела
	var direction = _turret.get_fire_direction()
	
	assert_ne(direction, Vector2.ZERO, "Направление не должно быть нулевым")
	assert_true(direction.is_normalized(), "Направление должно быть нормализовано")
	assert_true(direction.x > 0, "Направление должно быть вправо (к цели)")

func test_turret_get_fire_direction_close_range():
	# Тестирование выстрела в упор
	var turret_pos = Vector2(100, 100)
	var aim_pos = Vector2(110, 100)  # Очень близко
	var mark_pos = Vector2(150, 100)
	
	_turret.global_position = turret_pos
	_turret.aim.global_position = aim_pos
	_turret.mark.global_position = mark_pos
	await wait_seconds(0.5)
	var direction = _turret.get_fire_direction()
	
	assert_ne(direction, Vector2.ZERO, "Направление не должно быть нулевым даже на близкой дистанции")
	assert_true(direction.is_normalized(), "Направление должно быть нормализовано")

func test_turret_get_fire_direction_safety_check():
	# Тестирование проверки безопасности (не стрелять по себе)
	var turret_pos = Vector2(100, 100)
	var aim_pos = Vector2(50, 100)  # За маркером
	var mark_pos = Vector2(150, 100)
	
	_turret.global_position = turret_pos
	_turret.aim.global_position = aim_pos
	_turret.mark.global_position = mark_pos
	await wait_seconds(0.5)
	var direction = _turret.get_fire_direction()
	
	assert_eq(direction, Vector2.ZERO, "Не должно стрелять если есть риск попасть по себе")

func test_turret_get_fire_position():
	# Проверка получения позиции выстрела
	var expected_position = _turret.mark.global_position
	var actual_position = _turret.get_fire_position()
	
	assert_eq(actual_position, expected_position, "Позиция выстрела должна быть позицией маркера")

func test_turret_update_position():
	# Тестирование обновления позиции прицеливания
	var new_position = Vector2(300, 200)
	
	# Запоминаем начальное состояние
	var initial_aim_position = _turret.aim_position
	
	# Вызываем метод
	_turret.update_position(new_position)
	
	assert_eq(_turret.aim_position, new_position, "Aim position должен обновиться")
	assert_ne(_turret.aim_position, initial_aim_position, "Aim position должен измениться")

func test_turret_cd_indicator():
	# Тестирование индикатора перезарядки
	var cooldown_time_ms = 2000.0
	
	# Проверяем начальное состояние
	assert_eq(_turret.cd_ind.max_value, 0, "Максимальное значение должно быть 0 до инициализации")
	
	# Вызываем метод
	_turret.CD_indicator(cooldown_time_ms)
	
	assert_eq(_turret.cd_ind.max_value, cooldown_time_ms, "Максимальное значение должно установиться")
	assert_eq(_turret.cd_ind2.max_value, cooldown_time_ms, "Максимальное значение второго индикатора должно установиться")
	assert_eq(_turret.cd_ind.value, 0, "Начальное значение должно быть 0")
	assert_eq(_turret.cd_ind2.value, 0, "Начальное значение второго индикатора должно быть 0")

# ================ TANK TESTS ================

func test_tank_initialization():
	# Проверка инициализации танка
	assert_not_null(_tank_scene._turret, "Танк должен иметь турель")
	assert_not_null(_tank_scene._move_component, "Танк должен иметь компонент движения")
	assert_not_null(_tank_scene._health_component, "Танк должен иметь компонент здоровья")
	assert_not_null(_tank_scene._weapon_system, "Танк должен иметь оружейную систему")
	assert_false(_tank_scene.is_death, "Танк изначально не должен быть уничтожен")
	assert_false(_tank_scene.is_move, "Танк изначально не должен двигаться")
	assert_false(_tank_scene.is_rotate, "Танк изначально не должен вращаться")

func test_tank_move():
	# Тестирование движения танка
	var initial_position = _tank_scene.global_position
	var move_direction = Vector2(1, 0)
	
	# Двигаем танк
	var speed = _tank_scene.move(move_direction)
	
	assert_true(_tank_scene.is_move, "Танк должен быть в состоянии движения")
	assert_true(speed > 0, "Скорость должна быть положительной")
	var engine:AudioStreamPlayer2D = _tank_scene.find_child("engine")
	assert_eq(engine.pitch_scale, 1.5, "Pitch scale должен измениться при движении")
	
	# Останавливаем танк
	speed = _tank_scene.move(Vector2.ZERO)
	
	assert_false(_tank_scene.is_move, "Танк не должен быть в состоянии движения после остановки")
	assert_eq(engine.pitch_scale, 1.0, "Pitch scale должен вернуться к 1.0 после остановки")

func test_tank_rotating():
	# Тестирование вращения танка
	
	# Вращаем влево
	_tank_scene.rotating(Tank.ERotate.LEFT)
	
	assert_true(_tank_scene.is_rotate, "Танк должен быть в состоянии вращения")
	var engine:AudioStreamPlayer2D = _tank_scene.find_child("engine")
	assert_eq(engine.pitch_scale, 1.5, "Pitch scale должен измениться при вращении")
	
	# Останавливаем вращение
	_tank_scene.rotating(Tank.ERotate.STOP)
	
	assert_false(_tank_scene.is_rotate, "Танк не должен быть в состоянии вращения после остановки")
	assert_eq(engine.pitch_scale, 1.0, "Pitch scale должен вернуться к 1.0 после остановки вращения")
	
	# Вращаем вправо
	_tank_scene.rotating(Tank.ERotate.RIGHT)
	
	assert_true(_tank_scene.is_rotate, "Танк должен быть в состоянии вращения вправо")
	assert_eq(engine.pitch_scale, 1.5, "Pitch scale должен измениться при вращении вправо")

func test_tank_rotating_to():
	# Тестирование вращения турели к цели
	var target_position = Vector2(500, 300)
	
	# Вызываем метод
	_tank_scene.rotating_to(target_position)
	
	# Проверяем, что турель получила команду на вращение
	assert_eq(_turret.aim_position, target_position, "Turret должен получить новую позицию цели")

func test_tank_fire_success():
	# Настраиваем позиции для успешного выстрела
	var turret_pos = Vector2(100, 100)
	var aim_pos = Vector2(200, 100)
	var mark_pos = Vector2(150, 100)
	
	_turret.global_position = turret_pos
	_turret.aim.global_position = aim_pos
	_turret.mark.global_position = mark_pos
	
	# Проверяем успешный выстрел
	await wait_seconds(0.5)
	var result = _tank_scene.fire()
	assert_true(result, "Выстрел должен быть успешным")
	assert_true(_weapon_system.get_proj_count(_weapon_system.get_current_ammo_type()) < 20, 
		"Количество боеприпасов должно уменьшиться")

func test_tank_fire_fail():
	# Настраиваем позиции для неудачного выстрела (опасная дистанция)
	var turret_pos = Vector2(100, 100)
	var aim_pos = Vector2(50, 100)  # За маркером
	var mark_pos = Vector2(20, 20)
	
	_turret.global_position = turret_pos
	_turret.aim.global_position = aim_pos
	_turret.mark.global_position = mark_pos
	
	# Проверяем неудачный выстрел
	var result = _tank_scene.fire()
	
	assert_false(result, "Выстрел должен провалиться из-за опасной дистанции")

func test_tank_switch_ammo_type():
	# Тестирование смены типа боеприпасов
	var initial_type = _weapon_system.get_current_ammo_type()
	var new_type = WeaponSystem.ProjectileType.HE
	
	# Проверяем успешную смену
	var result = _tank_scene.switch_ammo_type(new_type)
	
	assert_true(result, "Смена боеприпасов должна быть успешной")
	assert_eq(_weapon_system.get_current_ammo_type(), new_type, 
		"Текущий тип боеприпасов должен измениться")
	
	# Проверяем неудачную смену (нет боеприпасов)
	_weapon_system.projectile_storage[WeaponSystem.ProjectileType.HEAT].count = 0
	result = _tank_scene.switch_ammo_type(WeaponSystem.ProjectileType.HEAT)
	
	assert_false(result, "Смена боеприпасов должна провалиться")
	assert_ne(_weapon_system.get_current_ammo_type(), WeaponSystem.ProjectileType.HEAT,
		"Текущий тип боеприпасов не должен измениться")

func test_tank_health_management():
	# Тестирование управления здоровьем танка
	var initial_health = _health_component.get_current_health()
	
	# Получаем статус здоровья
	var health_status = _tank_scene.get_health_status()
	
	assert_eq(health_status["current_health"], initial_health, "Текущее здоровье должно совпадать")
	assert_eq(health_status["max_health"], _health_component.max_health, "Максимальное здоровье должно совпадать")
	assert_true(health_status["health_percentage"] >= 0 and health_status["health_percentage"] <= 1,
		"Процент здоровья должен быть в диапазоне 0-1")
	
	# Наносим урон
	var damage_amount = 100.0
	_health_component.take_damage(damage_amount)
	
	# Проверяем обработку урона
	assert_lt(_health_component.get_current_health(), initial_health,
		"Здоровье должно уменьшиться после получения урона")

func test_tank_death_sequence():
	# Тестирование последовательности уничтожения танка
	assert_false(_tank_scene.is_death, "Танк изначально не должен быть уничтожен")
	
	# Уничтожаем танк
	_health_component.take_damage(_health_component.max_health * 2)
	
	# Даем время на обработку
	await get_tree().process_frame
	await get_tree().process_frame
	
	assert_true(_tank_scene.is_death, "Танк должен быть помечен как уничтоженный")
	
	# Проверяем, что анимация смерти запущена
	var anim:AnimationPlayer = _tank_scene.find_child("animation")
	assert_true(anim.is_playing(), "Анимация смерти должна быть запущена")
	
func test_tank_get_health_component():
	# Тестирование получения компонента здоровья
	var health_component = _tank_scene.get_health()
	
	assert_not_null(health_component, "Должен возвращаться компонент здоровья")
	assert_eq(health_component, _health_component, "Должен возвращаться правильный компонент здоровья")

func test_tank_get_weapon_system():
	# Тестирование получения оружейной системы
	var weapon_system = _tank_scene.get_weapon_system()
	
	assert_not_null(weapon_system, "Должна возвращаться оружейная система")
	assert_eq(weapon_system, _weapon_system, "Должна возвращаться правильная оружейная система")

func test_tank_engine_sound():
	# Тестирование звука двигателя
	var engine = _tank_scene.find_child("engine")
	
	assert_not_null(engine, "Должен быть нод звука двигателя")
	assert_true(engine.playing, "Звук двигателя должен играть")
	assert_eq(engine.pitch_scale, 1.0, "Изначальный pitch должен быть 1.0")
	
	# Проверяем изменение pitch при движении
	_tank_scene.move(Vector2(1, 0))
	assert_eq(engine.pitch_scale, 1.5, "Pitch должен увеличиться при движении")
	
	# Проверяем возврат pitch при остановке
	_tank_scene.move(Vector2.ZERO)
	assert_eq(engine.pitch_scale, 1.0, "Pitch должен вернуться к 1.0 при остановке")

# ================ INTEGRATION TESTS ================

func test_tank_turret_integration():
	# Интеграционный тест взаимодействия танка и турели
	var target_position = Vector2(400, 300)
	
	# Танк поворачивает турель к цели
	_tank_scene.rotating_to(target_position)
	
	assert_eq(_turret.aim_position, target_position, "Turret должен получить позицию цели")
	await wait_seconds(0.5)
	# Проверяем, что турель готова к выстрелу
	var fire_position = _turret.get_fire_position()
	var fire_direction = _turret.get_fire_direction()
	
	assert_ne(fire_position, Vector2.ZERO, "Позиция выстрела не должна быть нулевой")
	assert_ne(fire_direction, Vector2.ZERO, "Направление выстрела не должно быть нулевым")
	
	# Пробуем выстрелить
	var fire_result = _tank_scene.fire()
	
	# Проверяем результат (может зависеть от расстояния до цели)
	if fire_direction != Vector2.ZERO:
		assert_true(fire_result, "Выстрел должен быть успешным при правильном направлении")
	else:
		assert_false(fire_result, "Выстрел должен провалиться при нулевом направлении")

func test_tank_full_command_sequence():
	# Полная последовательность команд для танка
	var commands_executed = 0
	
	# Создаем мок-команду
	var mock_command = MockCommand.new()
	mock_command.execute_result = true
	
	# Выполняем команду через танк
	_tank_scene.proc_command(mock_command)
	commands_executed += 1
	
	# Двигаем танк
	var move_result = _tank_scene.move(Vector2(1, 0))
	assert_true(move_result > 0, "Танк должен двигаться")
	commands_executed += 1
	
	# Вращаем танк
	_tank_scene.rotating(Tank.ERotate.LEFT)
	assert_true(_tank_scene.is_rotate, "Танк должен вращаться")
	commands_executed += 1
	
	# Вращаем турель
	_tank_scene.rotating_to(Vector2(500, 300))
	assert_eq(_turret.aim_position, Vector2(500, 300), "Турель должна получить команду")
	commands_executed += 1
	
	# Проверяем, что все команды выполнены
	assert_eq(commands_executed, 4, "Все 4 команды должны быть выполнены")

func test_tank_damage_and_death_integration():
	# Интеграционный тест получения урона и смерти
	var initial_health = _health_component.get_current_health()
	
	# Наносим урон
	var damage_amount = 500.0
	_health_component.take_damage(damage_amount)
	
	# Проверяем, что здоровье уменьшилось
	assert_lt(_health_component.get_current_health(), initial_health,
		"Здоровье должно уменьшиться после получения урона")
	
	# Проверяем, что танк еще жив
	assert_false(_tank_scene.is_death, "Танк еще не должен быть уничтожен")
	
	# Наносим смертельный урон
	_health_component.take_damage(_health_component.max_health)
	
	# Даем время на обработку
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Проверяем, что танк уничтожен
	assert_true(_tank_scene.is_death, "Танк должен быть уничтожен")
	var anim:AnimationPlayer = _tank_scene.find_child("animation")
	assert_true(anim.is_playing(), "Должна запуститься анимация смерти")

# Вспомогательный класс для тестирования команд
class MockCommand extends Command:
	var execute_result: bool = true
	
	func execute(_tank: Node) -> void:
		execute_result = true
