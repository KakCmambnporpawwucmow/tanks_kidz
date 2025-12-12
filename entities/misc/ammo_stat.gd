extends HBoxContainer
class_name AmmoStatistic

@export var game_object:Node2D = null
var _weapon_system:WeaponSystem = null

func _ready() -> void:
	if game_object != null:
		if game_object.has_method("get_weapon_system"):
			_weapon_system =  game_object.get_weapon_system()
		if _weapon_system == null:
			Logi.fatal("AmmoStatistic {0}: _weapon_system must be assigned.".format([name]))
		assert(_weapon_system != null, "AmmoStat: weapon_system must be assigned")
		if not _weapon_system.send_update.is_connected(update):
			_weapon_system.send_update.connect(update)
		update()
	
func set_game_object(_game_object:Node2D):
	game_object = _game_object
	if game_object == null:
		Logi.fatal("AmmoStatistic {0}: game_object must be assigned.".format([name]))
	assert(game_object != null, "AmmoStat: game_object must be assigned")
	if game_object.has_method("get_weapon_system"):
		_weapon_system =  game_object.get_weapon_system()
	if _weapon_system == null:
		Logi.fatal("AmmoStatistic {0}: _weapon_system must be assigned.".format([name]))
	assert(_weapon_system != null, "AmmoStat: weapon_system must be assigned")
	if not _weapon_system.send_update.is_connected(update):
		_weapon_system.send_update.connect(update)
	update()
	
func update():
	var current_ammo_type = _weapon_system.get_current_ammo_type()
	for child in get_children():
		if child is AmmoState:
			child.bold_state = child.ammo_type ==  current_ammo_type
			child.count = _weapon_system.get_proj_count(child.ammo_type)
			
func get_weapon_system()->WeaponSystem:
	return _weapon_system
			
