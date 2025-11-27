extends Line2D

@export var trail_texture: Texture2D
@export var max_points: int = 20
@export var point_spacing: float = 10.0  # Расстояние между точками
@export var fade_timer: float = 0.1  # Как часто удалять точки
@export var trail_width: float = 8.0  # Ширина следа
@export var tank:Tank = null

var last_point_position: Vector2
var timer: float = 0.0

func _ready():
	assert(tank != null, "Tank must be assigned")
	# Настройки линии
	width = trail_width
	if trail_texture:
		texture = trail_texture
		texture_mode = Line2D.LINE_TEXTURE_TILE
	
	# Градиент прозрачности
	var gradient = Gradient.new()
	gradient.colors = [Color(1, 1, 1, 1), Color(1, 1, 1, 0)]  # От непрозрачного к прозрачному
	gradient = gradient

func _process(delta):
	# Добавляем точки при движении
	add_trail_points()
	
	# Удаляем старые точки по таймеру
	timer += delta
	if timer >= fade_timer:
		remove_old_points()
		timer = 0.0

func add_trail_points():
	if not is_instance_valid(tank):
		queue_free()
		return
	var current_pos = tank.global_position
	
	# Добавляем точку если уехали достаточно далеко или это первая точка
	if points.is_empty() or last_point_position.distance_to(current_pos) >= point_spacing:
		# Преобразуем глобальную позицию в локальную относительно родителя
		add_point(current_pos)
		last_point_position = current_pos
		
		# Ограничиваем количество точек
		if points.size() > max_points:
			remove_point(0)

func remove_old_points():
	# Постепенно удаляем точки с конца
	if points.size() > 1:
		remove_point(0)

# Функция для полной очистки следа
func clear_trail():
	clear_points()
