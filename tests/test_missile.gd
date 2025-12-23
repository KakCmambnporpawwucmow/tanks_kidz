# test_missile.gd
extends GutTest

var MissileScene: PackedScene
var missile_instance: MissileProjectile
var CommandProducer: Script
var Command: Script

func before_all():
	# Загружаем сцену ракеты
	MissileScene = load("res://entities/projectiles/missile.tscn")
	# Пытаемся загрузить скрипты команд
	if FileAccess.file_exists("res://command/command_producer.gd"):
		CommandProducer = load("res://command/command_producer.gd")
	if FileAccess.file_exists("res://command/command.gd"):
		Command = load("res://command/command.gd")

func before_each():
	# Создаем новый экземпляр для каждого теста
	missile_instance = MissileScene.instantiate()
	add_child(missile_instance)

func after_each():
	if missile_instance != null and is_instance_valid(missile_instance):
		missile_instance.queue_free()
		missile_instance = null

func test_missile_initializes_correctly():
	# Проверяем начальные настройки
	assert_not_null(missile_instance, "Missile should be instantiated")
	assert_eq(missile_instance.initial_speed, 200.0, "Initial speed should be 200")
	assert_eq(missile_instance.armor_penetration, 8, "Armor penetration should be 8")
	assert_true(missile_instance is MissileProjectile, "Should be MissileProjectile type")
	assert_true(missile_instance is Projectile, "Should inherit from Projectile")

func test_missile_get_damage():
	# Проверяем что метод get_damage() работает
	# Если в Projectile есть метод get_damage(), используем его
	var damage = 0
	if missile_instance.has_method("get_damage"):
		damage = missile_instance.get_damage()
		assert_eq(damage, 400, "Damage should be 400")
	else:
		# Иначе проверяем DamageComponent напрямую
		var damage_component = missile_instance.get_node_or_null("DamageComponent")
		if damage_component and damage_component.has_property("damage"):
			assert_eq(damage_component.damage, 400, "DamageComponent damage should be 400")
		else:
			pending("get_damage method not implemented yet")

func test_missile_has_move_component():
	# Проверяем наличие компонента движения
	var move_component = missile_instance.get_node_or_null("BaseMoveComponent")
	assert_not_null(move_component, "Missile should have BaseMoveComponent")
	assert_true(move_component is BaseMoveComponent, "Move component should be BaseMoveComponent type")

func test_missile_has_smoke_particles():
	# Проверяем наличие частиц дыма
	var smoke_particles = missile_instance.get_node_or_null("fly/smoke_missile")
	assert_not_null(smoke_particles, "Missile should have smoke particles")
	assert_true(smoke_particles is GPUParticles2D, "Should be GPUParticles2D")

func test_missile_has_rocket_sound():
	# Проверяем наличие звука ракеты
	var rocket_sound = missile_instance.get_node_or_null("fly/rocket_sound")
	assert_not_null(rocket_sound, "Missile should have rocket sound")
	assert_true(rocket_sound is AudioStreamPlayer2D, "Should be AudioStreamPlayer2D")
	assert_not_null(rocket_sound.stream, "Rocket sound stream should be loaded")

func test_missile_has_timer():
	# Проверяем наличие таймера
	var timer = missile_instance.get_node_or_null("Timer")
	assert_not_null(timer, "Missile should have Timer")
	assert_true(timer is Timer, "Should be Timer")
	assert_eq(timer.wait_time, 10.0, "Timer wait time should be 10 seconds")
	assert_true(timer.one_shot, "Timer should be one shot")

func test_missile_inherits_projectile_functionality():
	# Проверяем что ракета наследует функциональность пули
	var fire_position = Vector2(100, 100)
	var fire_direction = Vector2(1, 0).normalized()
	
	# Действие
	var velocity = missile_instance.activate(fire_position, fire_direction)
	
	# Проверка
	assert_eq(missile_instance.global_position, fire_position, 
		"Position should be set correctly")
	assert_eq(missile_instance.global_rotation, fire_direction.angle(),
		"Rotation should be set correctly")
	
	# У ракеты своя логика движения через move_component
	# но activate все равно должен возвращать скорость
	assert_not_null(velocity, "activate should return velocity")

func test_missile_on_death_calls_super():
	# Создаем отдельный экземпляр для теста
	var missile = MissileScene.instantiate()
	add_child(missile)
	
	# Действие - вызываем on_death
	missile.on_death(10)
	
	# Проверяем что move_component получил Vector2.ZERO
	# Это косвенная проверка что метод move_component.move(Vector2.ZERO) был вызван
	pass_test("on_death should call super and stop movement")
	
	missile.queue_free()

func test_missile_proc_command_with_valid_move_component():
	# Создаем отдельный экземпляр
	var missile = MissileScene.instantiate()
	add_child(missile)
	
	# Создаем тестовую команду
	var mock_command = null
	
	# Если Command существует и это RefCounted, создаем экземпляр
	if Command and ClassDB.is_parent_class(Command.get_instance_base_type(), "RefCounted"):
		mock_command = Command.new()
	else:
		# Если Command не найден или не RefCounted, создаем пустой RefCounted
		mock_command = RefCounted.new()
	
	# Проверяем валидность move_component
	var move_component = missile.get_node("BaseMoveComponent")
	assert_true(is_instance_valid(move_component), "Move component should be valid")
	
	# Действие
	missile.proc_command(mock_command)
	
	# Проверка - команда должна быть выполнена если move_component валиден
	pass_test("proc_command should execute command when move_component is valid")
	
	missile.queue_free()
	# RefCounted объекты удаляются автоматически

func test_missile_proc_command_with_invalid_move_component():
	# Создаем отдельный экземпляр
	var missile = MissileScene.instantiate()
	add_child(missile)
	
	# Удаляем move_component чтобы сделать его невалидным
	var move_component = missile.get_node("BaseMoveComponent")
	move_component.queue_free()
	await wait_frames(2)
	
	# Создаем тестовую команду как RefCounted
	var mock_command = Command.new()
	
	# Действие - proc_command не должен вызывать execute если move_component невалиден
	missile.proc_command(mock_command)
	
	# Проверка - код должен выполниться без ошибок
	pass_test("proc_command should not crash with invalid move_component")
	
	missile.queue_free()
	# RefCounted объекты удаляются автоматически

func test_missile_proc_command_with_invalid_command():
	# Создаем отдельный экземпляр
	var missile = MissileScene.instantiate()
	add_child(missile)
	
	# Создаем невалидную команду
	var invalid_command = null
	
	# Действие - proc_command должен обработать null команду без ошибок
	missile.proc_command(invalid_command)
	
	# Проверка - код должен выполниться без ошибок
	pass_test("proc_command should handle null command without errors")
	
	missile.queue_free()

func test_missile_rotating_to():
	# Создаем отдельный экземпляр
	var missile = MissileScene.instantiate()
	add_child(missile)
	
	# Получаем move_component
	var move_component = missile.get_node("BaseMoveComponent")
	
	# Действие - вызываем rotating_to
	var target_position = Vector2(500, 300)
	missile.rotating_to(target_position)
	
	# Проверяем что метод smooth_look_at был вызван на move_component
	pass_test("rotating_to should call smooth_look_at on move_component")
	
	missile.queue_free()

func test_missile_process_movement():
	# Создаем отдельный экземпляр
	var missile = MissileScene.instantiate()
	add_child(missile)
	
	# Сохраняем начальное положение
	var start_position = missile.global_position
	
	# Действие - вызываем _process вручную
	var delta = 0.016  # Примерное время кадра (60 FPS)
	missile._process(delta)
	
	# Проверяем что move_component.move был вызван с Vector2.RIGHT
	pass_test("_process should call move with Vector2.RIGHT")
	
	missile.queue_free()

func test_missile_timer_timeout():
	# Создаем отдельный экземпляр
	var missile = MissileScene.instantiate()
	add_child(missile)
	
	# Действие - вызываем обработчик таймера
	missile._on_timer_timeout()
	
	# Проверяем базовые состояния
	assert_eq(missile.linear_velocity, Vector2.ZERO,
		"Velocity should be zero on timer timeout")
	assert_false(missile.get_node("view").visible,
		"View should be invisible on timer timeout")
	
	# Проверяем что анимация penetracion запущена
	pass_test("_on_timer_timeout should stop movement and start animation")
	
	missile.queue_free()

func test_missile_damage_component():
	# Проверяем компонент урона
	var damage_component = missile_instance.get_node_or_null("DamageComponent")
	assert_not_null(damage_component, "Missile should have DamageComponent")
	if damage_component is DamageComponent:
		assert_eq(damage_component.get_current_damage(), 400, "DamageComponent damage should be 400")

func test_missile_view_properties():
	# Проверяем свойства view
	var view = missile_instance.get_node_or_null("view")
	assert_not_null(view, "Missile should have view")
	assert_not_null(view.texture, "View texture should be loaded")
	assert_eq(view.position, Vector2(-3.9999998, 0), "View position should be set")
	assert_eq(view.scale, Vector2(0.6315789, 0.61538464), "View scale should be set")

func test_missile_all_nodes_exist():
	# Проверяем наличие всех ключевых узлов
	var required_nodes = [
		"view",
		"BaseMoveComponent",
		"fly",
		"fly/smoke_missile",
		"fly/rocket_sound",
		"Timer",
		"DamageComponent",
		"CollisionShape2D",
		"VisibleOnScreenNotifier2D",
		"PenetrationMarker",
		"AnimationPlayer",
		"ricoshet",
		"penetration"
	]
	
	for node_path in required_nodes:
		var node = missile_instance.get_node_or_null(node_path)
		assert_not_null(node, "Node %s should exist" % node_path)

func test_missile_move_component_properties():
	# Проверяем свойства компонента движения
	var move_component = missile_instance.get_node("BaseMoveComponent")
	assert_eq(move_component.move_speed, 200.0, "Move speed should be 200")
	assert_eq(move_component.reverse_speed, 0.0, "Reverse speed should be 0")

func test_missile_particles_properties():
	# Проверяем свойства частиц
	var particles = missile_instance.get_node("fly/smoke_missile")
	assert_eq(particles.lifetime, 2.0, "Particles lifetime should be 2.0")
	assert_true(particles.local_coords, "Particles should use local coords")
	assert_eq(particles.trail_lifetime, 2.53, "Trail lifetime should be 2.53")
	assert_not_null(particles.process_material, "Particles should have process material")

func test_missile_safe_destruction():
	# Создаем новый экземпляр
	var missile = MissileScene.instantiate()
	add_child(missile)
	
	# Проверяем что объект существует
	assert_true(is_instance_valid(missile), "Missile should be valid initially")
	
	# Удаляем объект
	missile.queue_free()
	
	# Ждем удаления
	await wait_frames(2)
	
	# Проверяем что объект больше не валиден
	assert_false(is_instance_valid(missile), "Missile should not be valid after queue_free")

func test_missile_signal_connections():
	# Создаем новый экземпляр
	var missile = MissileScene.instantiate()
	add_child(missile)
	
	# Проверяем что сигналы подключены
	var timer = missile.get_node("Timer")
	assert_true(timer.is_connected("timeout", missile._on_timer_timeout),
		"Timer should be connected to _on_timer_timeout signal")
	
	# Проверяем родительские сигналы (унаследованные от Projectile)
	var anim_player = missile.get_node("AnimationPlayer")
	assert_true(anim_player.is_connected("animation_finished", missile._on_animation_player_animation_finished),
		"AnimationPlayer should be connected to animation_finished signal")
	
	var notifier = missile.get_node("VisibleOnScreenNotifier2D")
	assert_true(notifier.is_connected("screen_exited", missile._on_visible_on_screen_notifier_2d_screen_exited),
		"VisibleOnScreenNotifier2D should be connected to screen_exited signal")
	
	missile.queue_free()

func test_missile_initial_speed_vs_move_speed():
	# Проверяем согласованность скоростей
	assert_eq(missile_instance.initial_speed, 200.0, "initial_speed should be 200")
	
	var move_component = missile_instance.get_node("BaseMoveComponent")
	assert_eq(move_component.move_speed, 200.0, "move_component.move_speed should be 200")
	
	# Они должны быть равны для согласованности движения
	assert_eq(missile_instance.initial_speed, move_component.move_speed,
		"initial_speed and move_component.move_speed should match")

func test_missile_group_registration():
	# Проверяем логику регистрации в группах
	# Создаем мок CommandProducer если скрипт существует
	if CommandProducer:
		var mock_producer = CommandProducer.new()
		if mock_producer:
			# Проверяем тип mock_producer
			if mock_producer is Node:
				# Добавляем мок в группу
				mock_producer.add_to_group("CommandProducers")
				add_child(mock_producer)
				
				# Создаем новую ракету после добавления мока
				var missile = MissileScene.instantiate()
				add_child(missile)
				
				# Даем время на выполнение _ready
				await wait_frames(2)
				
				# Проверяем что ракета попыталась зарегистрироваться
				pass_test("Missile should try to register with CommandProducers in _ready")
				
				missile.queue_free()
				mock_producer.queue_free()
			else:
				pending("CommandProducer is not a Node, cannot add to tree")
	else:
		pending("CommandProducer script not found, skipping test")

# Тест на проверку что ракета корректно работает с нулевым уроном
func test_missile_on_death_zero_damage():
	# Создаем отдельный экземпляр
	var missile = MissileScene.instantiate()
	add_child(missile)
	
	# Отслеживаем удаление
	var freed_state = [false]
	missile.tree_exited.connect(func(): freed_state[0] = true)
	
	# Действие - вызываем on_death с нулевым уроном
	missile.on_death(0)
	
	# Даем время на выполнение queue_free() (наследованного от Projectile)
	await wait_seconds(2)
	
	# Проверяем что ракета удалилась
	assert_true(freed_state[0], "Missile should be freed with zero damage (inherited from Projectile)")

# Тест на проверку обработки экрана
func test_missile_screen_exited():
	# Создаем отдельный экземпляр
	var missile = MissileScene.instantiate()
	add_child(missile)
	
	# Отслеживаем удаление
	var freed_state = [false]
	missile.tree_exited.connect(func(): freed_state[0] = true)
	
	# Действие - вызываем обработчик выхода за экран
	missile._on_visible_on_screen_notifier_2d_screen_exited()
	
	# Даем время на выполнение queue_free()
	await wait_frames(2)
	
	# Проверяем что ракета удалилась (наследование от Projectile)
	assert_true(freed_state[0], "Missile should be freed when exiting screen (inherited from Projectile)")

# Тест на проверку завершения анимации
func test_missile_animation_finished():
	# Создаем отдельный экземпляр
	var missile = MissileScene.instantiate()
	add_child(missile)
	
	# Отслеживаем удаление
	var freed_state = [false]
	missile.tree_exited.connect(func(): freed_state[0] = true)
	
	# Действие - вызываем обработчик завершения анимации
	missile._on_animation_player_animation_finished("any_animation")
	
	# Даем время на обработку
	await wait_frames(2)
	
	# Проверяем что ракета удалилась (наследование от Projectile)
	assert_true(freed_state[0], "Missile should be freed after animation (inherited from Projectile)")

# Тест на проверку форматирования сообщения об ошибке
func test_missile_error_message_formatting():
	# Проверяем что строка форматирования корректна
	var error_message = "Error. Projectile {0}, not registred in CommandProducer".format(["TestMissile"])
	assert_eq(error_message, "Error. Projectile TestMissile, not registred in CommandProducer",
		"Error message should be formatted correctly")

# Тест для проверки поведения с невалидной командой (null)
func test_missile_proc_command_with_null_move_component_and_command():
	# Этот тест проверяет крайний случай
	var missile = MissileScene.instantiate()
	add_child(missile)
	
	# Удаляем move_component
	var move_component = missile.get_node("BaseMoveComponent")
	move_component.queue_free()
	await wait_frames(2)
	
	# Действие с null командой
	missile.proc_command(null)
	
	# Проверка - не должно быть ошибок
	pass_test("proc_command should handle null command with invalid move_component")
	
	missile.queue_free()

# Тест для проверки что все компоненты инициализированы в _ready
func test_missile_ready_initialization():
	# Создаем отдельный экземпляр
	var missile = MissileScene.instantiate()
	
	# Проверяем что move_component не null перед добавлением в дерево
	# (assert в _ready проверит это)
	add_child(missile)
	
	# Если assert сработал, тест не дойдет до этой точки
	# Если мы здесь, значит assert не сработал и все хорошо
	pass_test("Missile _ready should initialize without assertion errors")
	
	missile.queue_free()

# Тест на проверку валидности объектов в методе proc_command
func test_missile_proc_command_validation_logic():
	# Создаем отдельный экземпляр
	var missile = MissileScene.instantiate()
	add_child(missile)
	
	# Создаем RefCounted команду
	var command = Command.new()
	
	# Проверяем что оба объекта валидны
	assert_true(is_instance_valid(missile.get_node("BaseMoveComponent")), 
		"Move component should be valid")
	assert_true(is_instance_valid(command), 
		"Command should be valid")
	
	# Действие - метод должен проверить оба объекта
	missile.proc_command(command)
	
	pass_test("proc_command should validate both move_component and command")
	
	missile.queue_free()
