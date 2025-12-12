# autoload/log.gd
extends Node
class_name Logs

var level:LoggerThreaded.Level = LoggerThreaded.Level.DEBUG
var max_buffer_size:int = 500
var flush_interval:float = 1.0
var log_to_console:bool = true
var log_to_file:bool =  true
var max_log_files:int = 7
var max_file_size:int = 5 * 1024 * 1024  # 5 MB

func _ready() -> void:
	# Конфигурация логгера
	var config = {
		"level": level,
		"max_buffer_size": max_buffer_size,
		"flush_interval": flush_interval,
		"log_to_console": log_to_console,
		"log_to_file": log_to_file,
		"max_log_files": max_log_files,
		"max_file_size": max_file_size
	}
	
	# Инициализируем логгер
	if LoggerThreaded.initialize(config):
		LoggerThreaded.info("Game started", {
			"version": ProjectSettings.get_setting("application/config/version", "1.0.0"),
			"engine": Engine.get_version_info().string
		})
	else:
		push_error("Failed to initialize logger")
		# Пробуем отложенную инициализацию
		LoggerThreaded.setup(config)

func _exit_tree() -> void:
	# Корректное завершение логгера
	LoggerThreaded.shutdown()

# Прокси-методы для удобства
static func debug(msg: String, ctx: Dictionary = {}) -> void:
	LoggerThreaded.debug(msg, ctx)

static func info(msg: String, ctx: Dictionary = {}) -> void:
	LoggerThreaded.info(msg, ctx)

static func warn(msg: String, ctx: Dictionary = {}) -> void:
	LoggerThreaded.warn(msg, ctx)

static func error(msg: String, ctx: Dictionary = {}) -> void:
	LoggerThreaded.error(msg, ctx)

static func fatal(msg: String, ctx: Dictionary = {}) -> void:
	LoggerThreaded.fatal(msg, ctx)

# Утилиты
static func flush() -> void:
	LoggerThreaded.flush_immediate()

static func stats() -> Dictionary:
	return LoggerThreaded.get_stats()

static func recent_logs(count: int = 20) -> Array[String]:
	return LoggerThreaded.get_recent_logs(count)
