# test_area_move_component.gd
extends GutTest

var area_move_component: AreaMoveComponent
var parent_node: Area2D

func before_each():
	parent_node = Area2D.new()
	area_move_component = AreaMoveComponent.new()
	parent_node.add_child(area_move_component)
	
	# Настройка компонента
	area_move_component.rotation_speed = 1.5
	area_move_component.move_speed = 80.0
	
	add_child(parent_node)

func after_each():
	if parent_node:
		parent_node.queue_free()

func test_inheritance():
	# Тест 1: Проверка наследования
	assert_is(area_move_component, BaseMoveComponent, "AreaMoveComponent должен наследоваться от BaseMoveComponent")
	
	# Тест 2: Должен работать как базовый компонент
	var initial_pos = parent_node.position
	area_move_component.move(Vector2.RIGHT)
	area_move_component._process(0.1)
	
	assert_ne(parent_node.position, initial_pos, "Позиция должна измениться после движения")
	
	# Тест 3: Вращение должно работать
	var initial_rotation = parent_node.rotation
	area_move_component.rotate_right()
	area_move_component._process(0.1)
	
	assert_ne(parent_node.rotation, initial_rotation, "Ротация должна измениться после вращения")

func test_movement_basic():
	# Тест 4: Базовое движение Area2D
	parent_node.position = Vector2.ZERO
	area_move_component.move(Vector2.UP)
	
	for i in range(5):
		area_move_component._process(0.1)
	
	assert_true(parent_node.position.y < 0, "Движение вверх должно уменьшать Y координату")
	assert_true(area_move_component.current_velocity.length() > 0, "Скорость должна быть больше 0")

func test_rotation_basic():
	# Тест 5: Базовое вращение Area2D
	var start_rotation = parent_node.rotation
	area_move_component.rotate_left()
	
	for i in range(3):
		area_move_component._process(0.1)
	
	assert_true(parent_node.rotation < start_rotation, "Вращение влево должно уменьшать угол")
	
	# Тест 6: Смена направления при вращении
	area_move_component.rotate_stop()
	area_move_component.move(Vector2.UP)
	var initial_direction = area_move_component.get_current_direction()
	
	area_move_component.rotate_right()
	area_move_component._process(0.1)
	
	assert_ne(area_move_component.get_current_direction(), initial_direction, "Направление должно измениться при вращении")

func test_smooth_look_at():
	# Тест 7: Плавный поворот Area2D к цели
	var target_pos = Vector2(200, 0)  # Справа от объекта
	parent_node.position = Vector2.ZERO
	parent_node.rotation = 0
	
	area_move_component.smooth_look_at(target_pos)
	
	# Симулируем несколько кадров
	for i in range(20):
		area_move_component._process(0.05)
	
	# Проверяем, что объект повернулся примерно в направлении цели
	var angle_to_target = (target_pos - parent_node.position).angle()
	var angle_diff = abs(wrapf(angle_to_target - parent_node.rotation, -PI, PI))
	
	assert_true(angle_diff < 0.1, "Объект должен быть повернут в направлении цели")
	assert_false(area_move_component.is_rotating_to, "is_rotating_to должно стать false после завершения")

func test_stop_movement():
	# Тест 8: Остановка движения Area2D
	area_move_component.move(Vector2.UP)
	
	# Двигаемся некоторое время
	for i in range(5):
		area_move_component._process(0.1)
	
	var moving_velocity = area_move_component.current_velocity.length()
	assert_true(moving_velocity > 0, "Скорость должна быть больше 0 при движении")
	
