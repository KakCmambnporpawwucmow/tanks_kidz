extends Node2D

class_name AICrew

@export var _nav_points_container:String = "nav_points"
@export var _ammunition_points_container:String = "amm_points"
@export var _enable:bool = true
@export var _nav_component:CharNavigationMoveComponent = null
@export var _turret:Turret = null

@onready var _parent:Tank = get_parent()
var _enemys:Array[Node2D]
var _nav_points:Array[Node2D]
var _current_enemy:Node2D
var _amm_points:Array[Node2D]


func _ready() -> void:
	assert(_nav_component != null, "AICrew: CharNavigationMoveComponent must be assigned")
	assert(_turret != null, "AICrew: _turret must be assigned")
	for cont in get_tree().get_nodes_in_group(_nav_points_container):
		_nav_points.append_array(cont.get_children())
	for cont in get_tree().get_nodes_in_group(_ammunition_points_container):
		_amm_points.append_array(cont.get_children())
	Logi.info("AICrew: tank {0}, initialized".format([_parent.name]))
	_nav_component.send_moving_state.connect(on_move_finish)
	if _enable:
		next_waypoint()
	$RayCast2D.add_exception(_parent)
	_turret.send_ready_to_fire.connect(on_rotate_done)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Tank and _parent.get_player_command() != body.get_player_command():
		_enemys.append(body)

func _on_area_2d_body_exited(body: Node2D) -> void:
	_enemys.erase(body)
	if body == _current_enemy:
		_current_enemy = null
	
func next_waypoint()->bool:
	if is_instance_valid(_parent) and _enable and not _nav_points.is_empty():
		var waypoint = _nav_points.pick_random()
		Logi.debug("AICrew: go to waypoint {0}, total count {1}".format([waypoint.name, _nav_points.size()]))
		if not _nav_component.move(waypoint.global_position):
			Logi.error("AICrew: waypoint {0}, not reacheble".format([waypoint.name, _nav_points.size()]))
			return false
		return true
	return false
	
func set_enable(is_enable:bool):
		_enable = is_enable
		if _enable == false:
			_nav_component.stop()
		
func on_move_finish(is_moving:bool):
	if is_moving == false:
		next_waypoint()
		
func get_enable()->bool:
	return _enable
	
func _process(_delta: float) -> void:
	if not _enemys.is_empty() and _enable:
		rotate_to_enemy()

func rotate_to_enemy():
	if not is_instance_valid(_current_enemy):
		_current_enemy = _enemys.pick_random()
	$RayCast2D.target_position = to_local(_current_enemy.global_position)
	var collade_with = $RayCast2D.get_collider()
	if collade_with == _current_enemy:
		_parent.rotating_to(_current_enemy.global_position)
	else:
		_current_enemy = null
			
func on_rotate_done():
	if is_instance_valid(_current_enemy):
		_parent.fire()

func ammo_empty():
	if is_instance_valid(_parent) and _enable and not _amm_points.is_empty():
		var waypoint = _amm_points.pick_random()
		Logi.debug("AICrew: go to waypoint {0}, total count {1}".format([waypoint.name, _amm_points.size()]))
		if not _nav_component.move(waypoint.global_position):
			Logi.error("AICrew: waypoint {0}, not reacheble".format([waypoint.name, _amm_points.size()]))
			return false
		return true
	return false
