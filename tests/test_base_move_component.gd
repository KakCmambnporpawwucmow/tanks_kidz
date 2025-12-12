# test_base_move_component.gd
extends GutTest

var move_component: BaseMoveComponent
var parent_node: Node2D

func before_each():
	parent_node = Node2D.new()
	move_component = BaseMoveComponent.new()
	parent_node.add_child(move_component)
	
	move_component.rotation_speed = 2.0
	move_component.move_speed = 100.0
	move_component.reverse_speed = 50.0
	move_component.acceleration = 5.0
	move_component.deceleration = 8.0
	
	add_child(parent_node)

func after_each():
	if parent_node:
		parent_node.queue_free()

func test_initialization():
	# Тест 1: Инициализация компонента
	assert_not_null(move_component.parent, "Родитель должен быть установлен")
	assert_eq(move_component.move_direction, Vector2.ZERO, "Начальное направление должно быть ZERO")
	assert_eq(move_component.start_move_direction, Vector2.UP, "Начальное направление движения должно быть UP")
	assert_eq(move_component.current_velocity, Vector2.ZERO, "Начальная скорость должна быть ZERO")

func test_rotation_methods():
	# Тест 2: Вращение влево
	move_component.rotate_left()
	assert_true(move_component.is_rotating, "При rotate_left() is_rotating должно быть true")
	assert_eq(move_component.target_angle, -2.0, "Целевой угол должен быть -2.0")
	
	# Тест 3: Вращение вправо
	move_component.rotate_stop()
	move_component.rotate_right()
	assert_true(move_component.is_rotating, "При rotate_right() is_rotating должно быть true")
	assert_eq(move_component.target_angle, 2.0, "Целевой угол должен быть 2.0")
	
	# Тест 4: Остановка вращения
	move_component.rotate_stop()
	assert_false(move_component.is_rotating, "После rotate_stop() is_rotating должно быть false")
	assert_eq(move_component.target_angle, 0.0, "Целевой угол должен быть 0.0")

func test_smooth_look_at():
	# Тест 5: Плавный поворот к цели
	var target_position = Vector2(100, 100)
	parent_node.global_position = Vector2.ZERO
	
	move_component.smooth_look_at(target_position)
	assert_true(move_component.is_rotating_to, "При smooth_look_at() is_rotating_to должно быть true")
	assert_eq(move_component._target_position, target_position, "Целевая позиция должна быть установлена")

func test_movement():
	# Тест 6: Движение вперед
	var speed = move_component.move(Vector2.UP)
	assert_true(move_component.is_moving_straight, "При move() is_moving_straight должно быть true")
	assert_eq(speed, 100.0, "При движении вперед должна использоваться move_speed")
	
	# Тест 7: Движение назад
	move_component.move(Vector2.ZERO)  # Останавливаемся
	speed = move_component.move(Vector2.LEFT)
	assert_eq(speed, 50.0, "При движении назад должна использоваться reverse_speed")
	
	# Тест 8: Остановка
	move_component.move(Vector2.ZERO)
	assert_false(move_component.is_moving_straight, "При move(Vector2.ZERO) is_moving_straight должно быть false")

func test_direction_update():
	# Тест 9: Обновление направления при вращении
	parent_node.rotation = PI / 4  # 45 градусов
	
	var direction_changed = false
	move_component.direction_changed.connect(func(_dir): direction_changed = true)
	
	var result = move_component.update_movement_direction(parent_node.rotation)
	assert_true(result, "Направление должно быть изменено.")
	
	var expected_direction = Vector2.UP.rotated(PI / 4)
	assert_almost_eq(move_component.move_direction.x, expected_direction.x, 0.001, "Направление должно быть повернуто на 45 градусов")
	assert_almost_eq(move_component.move_direction.y, expected_direction.y, 0.001)

func test_process_movement():
	# Тест 10: Обработка движения в _process
	move_component.move(Vector2.UP)
	move_component._process(0.016)  # Примерно 1 кадр при 60 FPS
	
	assert_true(move_component.get_current_speed() > 0, "Скорость должна увеличиться")
	assert_true(move_component.is_moving(), "is_moving() должно возвращать true при движении")

func test_getters():
	# Тест 12: Методы получения состояния
	move_component.move(Vector2.UP)
	move_component._process(0.1)
	
	var direction = move_component.get_current_direction()
	var speed = move_component.get_current_speed()
	
	assert_almost_eq(direction.length(), 1.0, 0.001, "Направление должно быть нормализовано")
	assert_true(speed > 0, "Скорость должна быть больше 0")

func test_signals():
	# Тест 13: Сигналы вращения
	watch_signals(move_component)
	
	move_component.rotate_right()
	assert_signal_emitted(move_component, "rotation_started", "Должен быть испущен сигнал rotation_started")
	
	move_component.rotate_stop()
	assert_signal_emitted(move_component, "rotation_finished", "Должен быть испущен сигнал rotation_finished")
	
	# Тест 14: Сигналы движения
	move_component.move(Vector2.UP)
	assert_signal_emitted(move_component, "movement_started", "Должен быть испущен сигнал movement_started")
	
	move_component.move(Vector2.ZERO)
	assert_signal_emitted(move_component, "movement_stopped", "Должен быть испущен сигнал movement_stopped")
