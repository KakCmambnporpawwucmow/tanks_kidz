# test_damage_component.gd
extends GutTest

var damage_component: DamageComponent
var health_component: HealthComponent

func before_each():
	damage_component = DamageComponent.new()
	health_component = HealthComponent.new()
	health_component.max_health = 100
	health_component.auto_destroy_on_death = false
	
	add_child(damage_component)
	add_child(health_component)

func after_each():
	if damage_component:
		damage_component.queue_free()
	if health_component:
		health_component.queue_free()

func test_initialization():
	# Тест 1: Инициализация
	assert_eq(damage_component.damage, 0, "Начальный урон должен быть 0")
	assert_eq(damage_component.get_current_damage(), 0, "Текущий урон должен быть 0")

func test_execute_damage():
	# Тест 2: Нанесение урона
	damage_component.damage = 25
	var result = damage_component.execute(health_component)
	assert_eq(result, 25, "Должен вернуться нанесенный урон")
	assert_eq(health_component.get_current_health(), 75, "Здоровье должно уменьшиться на 25")
	
	# Тест 3: Повторное выполнение
	result = damage_component.execute(health_component)
	assert_eq(result, 25, "Повторное выполнение должно снова нанести урон")

func test_update_damage():
	# Тест 4: Обновление урона
	var new_damage = damage_component.update(15)
	assert_eq(new_damage, 15, "Должно вернуться новое значение урона")
	assert_eq(damage_component.get_current_damage(), 15, "Текущий урон должен обновиться")

func test_timer_reset():
	# Тест 6: Сброс урона по таймеру
	damage_component.damage = 25
	damage_component.update(20, 0.1)
	assert_eq(damage_component.get_current_damage(), 20, "Урон должен быть установлен")
	
	await wait_seconds(0.15)  # Ждем срабатывания таймера
	
	assert_eq(damage_component.get_current_damage(), 25, "После таймера урон должен сброситься к значению damage")
	assert_eq(damage_component.damage, 25, "Исходный урон должен остаться 25")

func test_done():
	# Тест 7: Отметка выполнения
	damage_component.damage = 30
	damage_component.done()
	
	var result = damage_component.execute(health_component)
	assert_eq(result, 0, "После done() execute должен возвращать 0")
	
	# Тест 8: Обновление после done()
	damage_component.update(10)
	assert_eq(damage_component.get_current_damage(), 10, "Update должен работать даже после done()")

func test_multiple_executions():
	# Тест 9: Несколько выполнений
	damage_component.damage = 10
	var total_damage = 0
	
	for i in range(3):
		total_damage += damage_component.execute(health_component)
	
	assert_eq(total_damage, 30, "Суммарный урон должен быть 30")
	assert_eq(health_component.get_current_health(), 70, "Здоровье должно уменьшиться на 30")
