extends Path2D

class_name SmartPath2D

@export var move_speed: float = 120.0
@export var auto_follow_mouse: bool = false

@onready var path_follow = $mover_crosshair

func _ready():
	if auto_follow_mouse:
		set_process(true)

func _process(delta):
	if auto_follow_mouse:
		move_to_nearest_position(get_global_mouse_position())

func move_to_nearest_position(target_global_pos: Vector2):
	var nearest_progress = find_nearest_progress_optimized(target_global_pos)
	smooth_move_to_progress(nearest_progress)

func find_nearest_progress_optimized(target_global_pos: Vector2) -> float:
	var curve = self.curve
	if curve == null or curve.point_count == 0:
		return 0.0
	
	# Используем встроенную функцию baked points если доступна
	var baked_points = curve.get_baked_points()
	var best_progress = 0.0
	var min_distance = INF
	
	for i in range(baked_points.size()):
		var point_global = to_global(baked_points[i])
		var distance = point_global.distance_to(target_global_pos)
		
		if distance < min_distance:
			min_distance = distance
			best_progress = float(i) / baked_points.size() * curve.get_baked_length()
	
	return best_progress

func smooth_move_to_progress(target_progress: float):
	# Останавливаем предыдущие твины
	var tweens = get_tree().get_processed_tweens()
	for tween in tweens:
		if tween.has_method("kill"):
			tween.kill()
	
	var duration = abs(target_progress - path_follow.progress) / move_speed
	var tween = create_tween()
	tween.tween_property(path_follow, "progress", target_progress, duration)
	tween.set_ease(Tween.EASE_IN_OUT)
