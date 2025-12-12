# test_ammo_state.gd
extends GutTest

var ammo_state: AmmoState
var test_texture: Texture2D

func before_each():
	# Создаем тестовую текстуру
	test_texture = ImageTexture.create_from_image(Image.create(16, 16, false, Image.FORMAT_RGBA8))
	
	# Создаем сцену AmmoState
	var ammo_state_scene = load("res://entities/misc/ammo_st.tscn")
	assert_not_null(ammo_state_scene, "Сцена ammo_st должна загружаться")
	
	ammo_state = ammo_state_scene.instantiate()
	add_child(ammo_state)

func after_each():
	if ammo_state:
		ammo_state.queue_free()

func test_ammo_state_initialization():
	# Тест 1: Проверка инициализации
	assert_not_null(ammo_state, "AmmoState должен создаваться")
	assert_is(ammo_state, Panel, "Должен быть Panel")
	assert_is(ammo_state, AmmoState, "Должен быть AmmoState")
	
	# Тест 2: Проверка дочерних узлов
	assert_not_null(ammo_state.find_child("MarginContainer"), "Должен содержать MarginContainer")
	assert_not_null(ammo_state.find_child("view"), "Должен содержать TextureRect (view)")
	assert_not_null(ammo_state.find_child("title"), "Должен содержать Label (title)")
	assert_not_null(ammo_state.find_child("count"), "Должен содержать Label (count)")
	assert_not_null(ammo_state.find_child("bold"), "Должен содержать ReferenceRect (bold)")

func test_texture_property():
	# Тест 3: Установка текстуры
	ammo_state.texture = test_texture
	
	# Получаем TextureRect
	var view = ammo_state.find_child("view") as TextureRect
	assert_not_null(view, "Должен найти TextureRect 'view'")
	assert_eq(view.texture, test_texture, "Текстура должна быть установлена в TextureRect")

func test_title_property():
	# Тест 4: Установка заголовка
	ammo_state.title = "AP_SHELL"
	
	var title_label = ammo_state.find_child("title") as Label
	assert_not_null(title_label, "Должен найти Label 'title'")
	assert_eq(title_label.text, "AP_SHELL", "Заголовок должен быть установлен")
	
	# Тест 5: Изменение заголовка
	ammo_state.title = "HE_SHELL"
	assert_eq(title_label.text, "HE_SHELL", "Заголовок должен обновиться")

func test_count_property():
	# Тест 6: Установка количества
	ammo_state.count = 25
	
	var count_label = ammo_state.find_child("count") as Label
	assert_not_null(count_label, "Должен найти Label 'count'")
	assert_eq(count_label.text, "25", "Количество должно быть установлено")
	
	# Тест 7: Изменение количества
	ammo_state.count = 10
	assert_eq(count_label.text, "10", "Количество должно обновиться")
	
	# Тест 8: Нулевое количество
	ammo_state.count = 0
	assert_eq(count_label.text, "0", "Должен поддерживать нулевое количество")

func test_bold_state_property():
	# Тест 9: Выделенное состояние
	ammo_state.bold_state = true
	
	var bold_rect = ammo_state.find_child("bold") as ReferenceRect
	assert_not_null(bold_rect, "Должен найти ReferenceRect 'bold'")
	assert_true(bold_rect.visible, "ReferenceRect должен стать видимым при bold_state = true")
	
	# Тест 10: Снятие выделения
	ammo_state.bold_state = false
	assert_false(bold_rect.visible, "ReferenceRect должен стать невидимым при bold_state = false")

func test_ammo_type_property():
	# Тест 11: Тип боеприпасов
	# Создаем enum для теста (имитация WeaponSystem.ProjectileType)
	const ProjectileType = {
		"AP": 0,
		"HE": 1,
		"HEAT": 2,
		"MISSILE": 3
	}
	
	ammo_state.ammo_type = ProjectileType.HE
	assert_eq(ammo_state.ammo_type, ProjectileType.HE, "ammo_type должен быть установлен")
	
	ammo_state.ammo_type = ProjectileType.MISSILE
	assert_eq(ammo_state.ammo_type, ProjectileType.MISSILE, "ammo_type должен обновиться")

func test_all_properties_together():
	# Тест 12: Комплексная проверка всех свойств
	const ProjectileType = {"AP": 0, "HE": 1}
	
	ammo_state.texture = test_texture
	ammo_state.title = "HEAT_SHELL"
	ammo_state.count = 42
	ammo_state.bold_state = true
	ammo_state.ammo_type = ProjectileType.HE
	
	# Проверяем все установленные значения
	var view = ammo_state.find_child("view") as TextureRect
	var title_label = ammo_state.find_child("title") as Label
	var count_label = ammo_state.find_child("count") as Label
	var bold_rect = ammo_state.find_child("bold") as ReferenceRect
	
	assert_eq(view.texture, test_texture, "Текстура должна сохраниться")
	assert_eq(title_label.text, "HEAT_SHELL", "Заголовок должен сохраниться")
	assert_eq(count_label.text, "42", "Количество должно сохраниться")
	assert_true(bold_rect.visible, "Выделение должно быть видимым")
	assert_eq(ammo_state.ammo_type, ProjectileType.HE, "Тип боеприпасов должен сохраниться")

func test_tool_mode():
	# Тест 13: Проверка режима @tool
	# Хотя напрямую проверить сложно, мы можем убедиться, что класс определен
	assert_true(ammo_state is AmmoState, "Класс AmmoState должен быть определен")
	assert_true(ammo_state.is_class("Panel"), "Должен наследоваться от Panel")
