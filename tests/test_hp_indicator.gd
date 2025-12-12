# test_hp_indicator.gd
extends GutTest

var hp_indicator: HPIndicator
var mock_health_component: HealthComponent
var hp_indicator_s:PackedScene = preload("res://entities/misc/hp_indicator.tscn")

func before_each():
	# Создаем mock HealthComponent
	mock_health_component = HealthComponent.new()
	mock_health_component.max_health = 100
	mock_health_component.auto_destroy_on_death = false
	
	# Создаем HPIndicator
	hp_indicator = hp_indicator_s.instantiate()
	hp_indicator.health_component = mock_health_component
	
	add_child(hp_indicator)
	add_child(mock_health_component)

func after_each():
	if hp_indicator:
		hp_indicator.queue_free()
	if mock_health_component:
		mock_health_component.queue_free()

func test_hp_indicator_initialization():
	# Тест 1: Проверка инициализации
	assert_not_null(hp_indicator, "HPIndicator должен создаваться")
	assert_is(hp_indicator, TextureProgressBar, "Должен быть TextureProgressBar")
	assert_is(hp_indicator, HPIndicator, "Должен быть HPIndicator")
	
	# Тест 2: Должен иметь дочерний Label
	var count_label = hp_indicator.find_child("count") as Label
	assert_not_null(count_label, "Должен содержать Label 'count'")

func test_ready_method():
	# Тест 3: Проверка метода _ready
	hp_indicator._ready()
	
	assert_eq(hp_indicator.max_value, 100, "max_value должно быть равно max_health")
	assert_eq(hp_indicator.value, 100, "value должно быть равно текущему здоровью")
	
	# Проверяем, что сигнал подключен
	assert_true(mock_health_component.health_changed.is_connected(hp_indicator.change_hp),
		"Сигнал health_changed должен быть подключен к change_hp")

func test_change_hp_method():
	# Тест 4: Изменение здоровья (урон)
	hp_indicator._ready()
	
	# Устанавливаем начальное значение
	hp_indicator.value = 100
	hp_indicator.visible = true
	
	var result = hp_indicator.change_hp(75)
	assert_true(result, "change_hp должен вернуть true при ненулевом здоровье")
	assert_true(hp_indicator.visible, "Должен стать видимым (через tween)")
	
	# Проверяем текст в Label
	var count_label = hp_indicator.find_child("count") as Label
	assert_eq(count_label.text, "75", "Label должен отображать новое значение здоровья")
	
	# Тест 5: Проверка анимации (tween)
	# Проверяем, что tween был создан
	assert_true(hp_indicator._tween != null, "Должен создаться Tween для анимации")
	
	# Ждем завершения анимации
	await wait_seconds(1.2)
	
	assert_false(hp_indicator.visible, "После анимации должен стать невидимым (callback)")

func test_change_hp_zero_health():
	# Тест 6: Изменение здоровья при нулевом значении
	hp_indicator._ready()
	hp_indicator.value = 0
	
	var result = hp_indicator.change_hp(50)
	assert_false(result, "change_hp должен вернуть false при value = 0")
	
	# Тест 7: Полное истощение здоровья
	mock_health_component.take_damage(100)  # Здоровье станет 0
	await wait_frames(2)
	
	# Должен обработать сигнал health_changed
	assert_true(mock_health_component.get_current_health() == 0, "Здоровье должно быть 0")

func test_callback_method():
	# Тест 7: Проверка метода callback
	hp_indicator.visible = true
	hp_indicator.callback()
	
	assert_false(hp_indicator.visible, "callback должен скрывать индикатор")

func test_with_different_health_values():
	# Тест 8: Разные значения здоровья
	hp_indicator._ready()
	
	# Полное здоровье
	hp_indicator.change_hp(100)
	assert_eq(hp_indicator.text, "100", "Должен отображать 100")
	
	# Половина здоровья
	hp_indicator.change_hp(50)
	assert_eq(hp_indicator.text, "50", "Должен отображать 50")
	
	# Критическое здоровье
	hp_indicator.change_hp(10)
	assert_eq(hp_indicator.text, "10", "Должен отображать 10")
	
	# Нулевое здоровье
	hp_indicator.value = 0
	hp_indicator.change_hp(0)
	# Метод должен вернуть false, но текст все равно обновится
	assert_eq(hp_indicator.text, "0", "Должен отображать 0")

func test_hp_indicator_visibility():
	# Тест 9: Видимость индикатора
	hp_indicator._ready()
	
	# Начальное состояние
	assert_false(hp_indicator.visible, "Изначально должен быть невидимым")
	
	# При изменении здоровья
	hp_indicator.change_hp(80)
	assert_true(hp_indicator.visible, "Должен стать видимым при изменении здоровья")
	
	# После анимации
	await wait_seconds(1.2)
	assert_false(hp_indicator.visible, "Должен скрыться после анимации")
