# auto_test_runner.gd
extends GutMain

func _ready():
	# Находим все папки с тестами
	scan_for_test_directories()
	
	# Запускаем тесты
	test_scripts()
	
	# Выходим после завершения
	await get_tree().create_timer(0.5).timeout
	get_tree().quit()

func scan_for_test_directories():
	# Рекурсивно ищем папки с тестами
	var directories_to_check = ["res://tests/"]
	
	for dir_path in directories_to_check:
		if DirAccess.dir_exists_absolute(dir_path):
			add_directory(dir_path, "test_")
