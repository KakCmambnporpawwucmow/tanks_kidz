# logger_threaded.gd
class_name LoggerThreaded extends RefCounted

enum Level { DEBUG, INFO, WARN, ERROR, FATAL }

# Основные настройки
static var log_level: Level = Level.DEBUG
static var max_buffer_size: int = 1000
static var flush_interval: float = 2.0  # секунды
static var log_to_console: bool = true
static var log_to_file: bool = true

# Потокобезопасные структуры
static var _write_thread: Thread
static var _log_queue_mutex: Mutex
static var _log_queue: Array[String]
static var _write_semaphore: Semaphore
static var _should_exit: bool = false
static var _is_initialized: bool = false
static var _main_thread_id: int = -1

# Настройки файла
static var _log_directory: String = "user://logs/"
static var _log_file_path: String = ""
static var _max_log_files: int = 10
static var _max_file_size: int = 10 * 1024 * 1024  # 10 MB

# Константы FileAccess
static var _FILE_READ: int = FileAccess.READ
static var _FILE_WRITE_READ: int = FileAccess.WRITE_READ
static var _FILE_WRITE: int = FileAccess.WRITE
static var _FILE_READ_WRITE: int = FileAccess.READ_WRITE

# Цвета для консоли
static var _colors: Dictionary = {
	Level.DEBUG: "cyan",
	Level.INFO: "white",
	Level.WARN: "yellow",
	Level.ERROR: "red",
	Level.FATAL: "darkred"
}

# Ссылка на узел для отложенной инициализации
static var _delayed_init_node: Node = null

# ==================== ПУБЛИЧНЫЙ API ====================

## Инициализация логгера (вызвать один раз при старте)
static func initialize(config: Dictionary = {}) -> bool:
	if _is_initialized:
		warn("Logger already initialized")
		return false
	
	# Сохраняем ID главного потока
	_main_thread_id = OS.get_thread_caller_id()
	
	# Применяем конфигурацию
	_apply_config(config)
	
	# Инициализируем синхронизацию
	_log_queue_mutex = Mutex.new()
	_write_semaphore = Semaphore.new()
	_log_queue = []
	
	# Создаем директорию для логов
	if not _ensure_log_directory():
		return false
	
	# Создаем новый файл лога
	if not _create_new_log_file():
		return false
	
	# Запускаем поток записи
	_write_thread = Thread.new()
	var error = _write_thread.start(_write_thread_func)
	if error != OK:
		push_error("Failed to start logging thread: %s" % error)
		return false
	
	_is_initialized = true
	info("Logger initialized successfully", {"config": config})
	return true

## Настроить логгер вручную с отложенной инициализацией
static func setup(config: Dictionary = {}) -> void:
	# Если уже инициализирован, игнорируем
	if _is_initialized:
		return
	
	# Создаем временный узел для отложенного вызова
	_delayed_init_node = Node.new()
	_delayed_init_node.set_name("LoggerDelayedInit")
	
	# Получаем корневой узел
	var root = Engine.get_main_loop()
	if root is SceneTree:
		root.root.add_child(_delayed_init_node)
		# Используем Callable без self
		var callable = Callable(LoggerThreaded, "_delayed_initialize")
		_delayed_init_node.call_deferred("call_thread_safe", callable.bind(config))

## Основные методы логирования
static func debug(message: String, context: Dictionary = {}) -> void:
	_log_internal(Level.DEBUG, message, context)

static func info(message: String, context: Dictionary = {}) -> void:
	_log_internal(Level.INFO, message, context)

static func warn(message: String, context: Dictionary = {}) -> void:
	_log_internal(Level.WARN, message, context)

static func error(message: String, context: Dictionary = {}) -> void:
	_log_internal(Level.ERROR, message, context)

static func fatal(message: String, context: Dictionary = {}) -> void:
	_log_internal(Level.FATAL, message, context)
	# Для фатальных ошибок делаем немедленную запись
	flush_immediate()

## Принудительная запись всех ждущих логов
static func flush_immediate() -> void:
	if not _is_initialized:
		return
	
	_write_semaphore.post()  # Будим поток
	
	# Даем потоку время на запись
	OS.delay_usec(50000)  # 50ms

## Остановка логгера (вызвать при выходе)
static func shutdown() -> void:
	if not _is_initialized:
		return
	
	info("Shutting down logger...")
	_should_exit = true
	_write_semaphore.post()  # Будим поток для выхода
	
	if _write_thread.is_started():
		_write_thread.wait_to_finish()
	
	_cleanup_old_logs()
	
	# Очищаем временный узел
	if _delayed_init_node and is_instance_valid(_delayed_init_node):
		_delayed_init_node.queue_free()
		_delayed_init_node = null
	
	_is_initialized = false
	print("Logger shut down successfully")

## Получить путь к текущему файлу лога
static func get_current_log_path() -> String:
	return ProjectSettings.globalize_path(_log_file_path)

## Проверить, инициализирован ли логгер
static func is_initialized() -> bool:
	return _is_initialized

# ==================== ВНУТРЕННИЕ МЕТОДЫ ====================

static func _delayed_initialize(config: Dictionary) -> void:
	# Удаляем временный узел
	if _delayed_init_node and is_instance_valid(_delayed_init_node):
		_delayed_init_node.queue_free()
		_delayed_init_node = null
	
	# Инициализируем логгер
	if not initialize(config):
		push_error("Failed to initialize logger in delayed mode")

static func _apply_config(config: Dictionary) -> void:
	log_level = config.get("level", log_level)
	max_buffer_size = config.get("max_buffer_size", max_buffer_size)
	flush_interval = config.get("flush_interval", flush_interval)
	log_to_console = config.get("log_to_console", log_to_console)
	log_to_file = config.get("log_to_file", log_to_file)
	_max_log_files = config.get("max_log_files", _max_log_files)
	_max_file_size = config.get("max_file_size", _max_file_size)

static func _ensure_log_directory() -> bool:
	var dir = DirAccess.open("user://")
	if not dir:
		push_error("Cannot open user:// directory")
		return false
	
	if not dir.dir_exists(_log_directory):
		var error = dir.make_dir_recursive(_log_directory)
		if error != OK:
			push_error("Failed to create log directory: %s" % error)
			return false
	
	return true

static func _create_new_log_file() -> bool:
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-").replace(" ", "_")
	_log_file_path = "%slog_%s.log" % [_log_directory, timestamp]
	
	# Создаем пустой файл
	var file = FileAccess.open(_log_file_path, _FILE_WRITE)
	if file:
		file.store_string("")  # Создаем пустой файл
		file.close()
		debug("Created new log file", {"path": _log_file_path})
		return true
	else:
		var error = FileAccess.get_open_error()
		push_error("Failed to create log file: %s (error: %s)" % [_log_file_path, error])
		return false

static func _log_internal(level: Level, message: String, context: Dictionary) -> void:
	if not _is_initialized or level < log_level:
		return
	
	var timestamp = Time.get_time_string_from_system()
	var level_str = Level.keys()[level].to_lower()
	
	# Получаем ID текущего потока
	var current_thread_id = OS.get_thread_caller_id()
	var thread_info = "main" if current_thread_id == _main_thread_id else "thread:%s" % current_thread_id
	
	# Формируем запись лога
	var log_entry = {
		"timestamp": timestamp,
		"level": level_str,
		"message": message,
		"context": context,
		"thread": thread_info
	}
	
	# Форматированная строка для вывода
	var formatted = _format_log_entry(log_entry)
	
	# Вывод в консоль (в основном потоке)
	if log_to_console:
		_print_to_console(formatted, level)
	
	# Добавление в очередь для записи в файл
	if log_to_file:
		_add_to_write_queue(formatted)
		
		# Проверка размера файла и ротация при необходимости
		_check_file_size()

static func _format_log_entry(entry: Dictionary) -> String:
	var parts = [
		"[%s]" % entry.timestamp,
		"[%s]" % entry.level.to_upper(),
		entry.message
	]
	
	if not entry.context.is_empty():
		# Преобразуем контекст в читаемую строку
		var context_parts = []
		for key in entry.context:
			context_parts.append("%s=%s" % [key, str(entry.context[key])])
		parts.append("{%s}" % ", ".join(context_parts))
	
	parts.append("[%s]" % entry.thread)
	
	return " ".join(parts)

static func _print_to_console(message: String, level: Level) -> void:
	var color = _colors.get(level, "white")
	print_rich("[color=%s]%s[/color]" % [color, message])

static func _add_to_write_queue(message: String) -> void:
	_log_queue_mutex.lock()
	
	_log_queue.append(message)
	
	# Если буфер переполнен, удаляем самые старые записи (кроме ошибок)
	if _log_queue.size() > max_buffer_size:
		var removed = 0
		var i = 0
		while i < _log_queue.size() and removed < 100:  # Удаляем пачками по 100
			if not ("[ERROR]" in _log_queue[i] or "[FATAL]" in _log_queue[i]):
				_log_queue.remove_at(i)
				removed += 1
			else:
				i += 1
	
	_log_queue_mutex.unlock()
	
	# Сигнализируем потоку записи, если буфер достаточно большой
	if _log_queue.size() >= max_buffer_size / 2:
		_write_semaphore.post()

static func _check_file_size() -> void:
	if not FileAccess.file_exists(_log_file_path):
		return
	
	var file = FileAccess.open(_log_file_path, _FILE_READ)
	if file:
		var file_size = file.get_length()
		file.close()
		
		if file_size > _max_file_size:
			info("Log file size exceeded", {
				"current_size": file_size,
				"max_size": _max_file_size,
				"path": _log_file_path
			})
			_create_new_log_file()
			_cleanup_old_logs()

static func _cleanup_old_logs() -> void:
	var dir = DirAccess.open(_log_directory)
	if not dir:
		return
	
	var error = dir.list_dir_begin()
	if error != OK:
		push_error("Failed to list log directory: %s" % error)
		return
	
	var files: Array[String] = []
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.begins_with("log_") and file_name.ends_with(".log"):
			files.append(file_name)
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	if files.size() <= _max_log_files:
		return
	
	# Сортируем по дате (самые новые первыми)
	files.sort_custom(func(a, b): return a > b)
	
	# Удаляем старые файлы
	for i in range(_max_log_files, files.size()):
		var full_path = "%s%s" % [_log_directory, files[i]]
		error = dir.remove(full_path)
		if error == OK:
			debug("Removed old log file", {"file": files[i]})
		else:
			warn("Failed to remove log file", {"file": files[i], "error": error})

# ==================== ФУНКЦИЯ ПОТОКА ЗАПИСИ ====================

static func _write_thread_func() -> void:
	var last_flush_time = Time.get_ticks_msec()
	
	while not _should_exit:
		# Ждем сигнала или таймаута
		if _write_semaphore.try_wait():
			# Получили сигнал - пишем немедленно
			_write_batch()
			last_flush_time = Time.get_ticks_msec()
		else:
			# Таймаут - проверяем время
			var current_time = Time.get_ticks_msec()
			if current_time - last_flush_time > flush_interval * 1000:
				_write_batch()
				last_flush_time = current_time
			else:
				# Короткая пауза чтобы не нагружать CPU
				OS.delay_usec(10000)  # 10ms
	
	# При выходе записываем все оставшиеся логи
	_write_batch()
	debug("Log writer thread finished")

static func _write_batch() -> void:
	# Забираем данные из основной очереди
	_log_queue_mutex.lock()
	if _log_queue.is_empty():
		_log_queue_mutex.unlock()
		return
	
	var to_write = _log_queue.duplicate()
	_log_queue.clear()
	_log_queue_mutex.unlock()
	
	if to_write.is_empty():
		return
	
	# Пишем в файл (используем WRITE_READ для append-режима)
	var file = FileAccess.open(_log_file_path, _FILE_WRITE_READ)
	if file:
		# Перемещаемся в конец файла для добавления
		file.seek_end()
		for entry in to_write:
			file.store_line(entry)
		file.close()
		
		# Отладочная информация (только при необходимости)
		if to_write.size() > 10:
			debug("Written batch of log entries", {"count": to_write.size()})
	else:
		# Если не удалось открыть файл, пытаемся создать новый
		var error = FileAccess.get_open_error()
		push_error("Failed to open log file", {
			"path": _log_file_path,
			"error": error,
			"batch_size": to_write.size()
		})
		
		# Пробуем создать директорию и файл заново
		_ensure_log_directory()
		_create_new_log_file()
		
		# Возвращаем логи в очередь для следующей попытки
		_log_queue_mutex.lock()
		_log_queue = to_write + _log_queue
		_log_queue_mutex.unlock()

# ==================== УТИЛИТЫ ДЛЯ ОТЛАДКИ ====================

## Получить статистику логгера
static func get_stats() -> Dictionary:
	var queue_size = 0
	if _log_queue_mutex:
		_log_queue_mutex.lock()
		queue_size = _log_queue.size()
		_log_queue_mutex.unlock()
	
	var file_size = 0
	if FileAccess.file_exists(_log_file_path):
		var file = FileAccess.open(_log_file_path, _FILE_READ)
		if file:
			file_size = file.get_length()
			file.close()
	
	return {
		"initialized": _is_initialized,
		"queue_size": queue_size,
		"max_buffer_size": max_buffer_size,
		"log_file": _log_file_path,
		"file_size": file_size,
		"file_size_mb": "%.2f MB" % (file_size / (1024.0 * 1024.0)),
		"thread_running": _write_thread != null and _write_thread.is_started(),
		"should_exit": _should_exit,
		"log_level": Level.keys()[log_level] if _is_initialized else "NOT_INIT"
	}

## Очистить очередь логов (для отладки)
static func clear_queue() -> void:
	if _log_queue_mutex:
		_log_queue_mutex.lock()
		_log_queue.clear()
		_log_queue_mutex.unlock()
		info("Log queue cleared")

## Прочитать последние N строк из лог-файла
static func get_recent_logs(count: int = 50) -> Array[String]:
	if not FileAccess.file_exists(_log_file_path):
		return []
	
	var file = FileAccess.open(_log_file_path, _FILE_READ)
	if not file:
		return []
	
	var lines: Array[String] = []
	var total_lines = 0
	
	# Считаем общее количество строк
	file.seek(0)
	while not file.eof_reached():
		var line = file.get_line()
		if line and not line.is_empty():
			total_lines += 1
	
	file.seek(0)
	
	# Пропускаем первые (total_lines - count) строк
	var skip_count = max(0, total_lines - count)
	var skipped = 0
	while skipped < skip_count and not file.eof_reached():
		var line = file.get_line()
		if line and not line.is_empty():
			skipped += 1
	
	# Читаем оставшиеся строки
	while not file.eof_reached():
		var line = file.get_line()
		if line and not line.is_empty():
			lines.append(line)
	
	file.close()
	return lines

## Проверить состояние логгера
static func health_check() -> bool:
	if not _is_initialized:
		return false
	
	if not DirAccess.dir_exists_absolute("user://logs/"):
		return false
	
	if not FileAccess.file_exists(_log_file_path):
		return false
	
	return true

## Установить уровень логирования в runtime
static func set_level(level: Level) -> void:
	if not _is_initialized:
		return
	
	var old_level = log_level
	log_level = level
	info("Log level changed", {"from": Level.keys()[old_level], "to": Level.keys()[level]})
