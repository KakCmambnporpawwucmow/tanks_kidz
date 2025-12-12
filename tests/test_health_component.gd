# test_health_component.gd
extends GutTest

var health_component: HealthComponent

func before_each():
	health_component = HealthComponent.new()
	health_component.max_health = 100
	health_component.auto_destroy_on_death = false
	add_child(health_component)

func after_each():
	if health_component:
		health_component.queue_free()
		await wait_frames(1)  # Даем время для обработки queue_free

func test_initialization():
	# Тест 1: Инициализация значений
	assert_eq(health_component.get_current_health(), 100, "Здоровье должно быть равно максимальному")
	assert_true(health_component.is_alive, "При инициализации is_alive должно быть true")
	assert_true(health_component.is_full_health(), "При полном здоровье is_full_health должен возвращать true")

func test_take_damage():
	# Тест 2: Получение урона
	var damage_taken = health_component.take_damage(30)
	assert_eq(damage_taken, 30, "Должно вернуться количество полученного урона")
	assert_eq(health_component.get_current_health(), 70, "Здоровье должно уменьшиться на 30")
	
	# Тест 3: Получение чрезмерного урона
	damage_taken = health_component.take_damage(80)
	assert_eq(damage_taken, 70, "Урон не должен превышать текущее здоровье")
	assert_eq(health_component.get_current_health(), 0, "Здоровье должно быть 0")
	assert_false(health_component.is_alive, "После смерти is_alive должно быть false")
	
	# Тест 4: Получение урона после смерти
	damage_taken = health_component.take_damage(10)
	assert_eq(damage_taken, 0, "После смерти урон не должен наноситься")

func test_healing():
	# Тест 5: Лечение
	health_component.take_damage(50)
	var healed_amount = health_component.heal(20)
	assert_eq(healed_amount, 70, "Должно вернуться новое значение здоровья")
	assert_eq(health_component.get_current_health(), 70, "Здоровье должно увеличиться на 20")
	
	# Тест 6: Лечение сверх максимума
	healed_amount = health_component.heal(40)
	assert_eq(healed_amount, 100, "Здоровье не должно превышать максимум")
	assert_eq(health_component.get_current_health(), 100, "Здоровье должно быть 100")
	assert_true(health_component.is_full_health(), "При полном здоровье is_full_health должен возвращать true")
	
	# Тест 7: Лечение после смерти
	health_component.die()
	healed_amount = health_component.heal(50)
	assert_eq(healed_amount, 0, "После смерти лечение не должно работать")

func test_die_and_resurrect():
	# Тест 8: Смерть
	watch_signals(health_component)
	health_component.die()
	assert_false(health_component.is_alive, "После die() is_alive должно быть false")
	assert_signal_emitted(health_component, "death", "Должен быть испущен сигнал death")
	
	# Тест 9: Воскрешение
	var resurrected_health = health_component.resurrect(0.5)
	assert_true(health_component.is_alive, "После resurrect() is_alive должно быть true")
	assert_eq(resurrected_health, 50, "Должно вернуться 50% здоровья")
	assert_eq(health_component.get_current_health(), 50, "Здоровье должно быть установлено в 50")
	
	# Тест 10: Полное воскрешение
	health_component.resurrect()
	assert_eq(health_component.get_current_health(), 100, "При воскрешении без параметров здоровье должно быть 100%")

func test_signals():
	# Тест 11: Сигнал health_changed
	var signal_data = []
	health_component.health_changed.connect(func(value): signal_data.append(value))
	
	health_component.take_damage(20)
	assert_eq(signal_data.size(), 1, "Сигнал health_changed должен быть испущен")
	assert_eq(signal_data[0], 80, "Сигнал должен содержать новое значение здоровья")
	
	# Тест 12: Сигнал low_health
	signal_data = {"low_health": false}
	health_component.low_health.connect(func(health_percentage: float): 
		signal_data["low_health"] = true)
	var test = signal_data["low_health"]
	health_component.take_damage(60)  # 80 -> 20 (20% < 30%)
	assert_true(signal_data["low_health"], "Сигнал low_health должен быть испущен при падении здоровья ниже 30%")

func test_health_percentage():
	health_component.max_health = 100
	# Тест 13: Процент здоровья
	health_component.take_damage(25)
	assert_eq(health_component.get_health_percentage(), 0.75, "Должен вернуться правильный процент здоровья")
	
	health_component.heal(25)
	assert_eq(health_component.get_health_percentage(), 1.0, "При полном здоровье должен вернуться 100%")
	
	health_component.take_damage(100)
	assert_eq(health_component.get_health_percentage(), 0.0, "При смерти должен вернуться 0%")

func test_auto_destroy():
	# Тест 14: Автоуничтожение при смерти
	var test_node = Node2D.new()
	var test_health = HealthComponent.new()
	test_health.max_health = 50
	test_health.auto_destroy_on_death = true
	test_node.add_child(test_health)
	
	# Используем массив для захвата значения по ссылке
	var signal_data = {"death_received": false}
	test_health.death.connect(func(): signal_data["death_received"] = true)
	
	# Наносим смертельный урон
	var damage_taken = test_health.take_damage(50)
	
	# Проверяем результаты
	assert_eq(damage_taken, 50, "Должен быть нанесен смертельный урон")
	assert_true(signal_data["death_received"], "Сигнал death должен быть испущен")
	assert_false(test_health.is_alive, "is_alive должно быть false после смерти")
	
	# Ждем немного и проверяем состояние
	await wait_frames(1)
	
	# Проверяем, что компонент помечен для удаления
	assert_true(!is_instance_valid(test_health), "HealthComponent должен быть удалён")
	assert_true(!is_instance_valid(test_node), "Родительский узел должен быть удалён")
