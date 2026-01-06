extends Node

const _player_state_path:String = "user://player_state.tres"
var _player_state:PlayerData = null

signal send_change_data()

func _ready() -> void:
	if FileAccess.file_exists(_player_state_path):
		_player_state = ResourceLoader.load(_player_state_path, "", ResourceLoader.CACHE_MODE_IGNORE)
	else:
		_player_state = PlayerData.new()
		ResourceSaver.save(_player_state, _player_state_path)
	_player_state._ps = self
		
func _exit_tree() -> void:
	save_player_state()
		
func save_player_state():
	ResourceSaver.save(_player_state, _player_state_path)
	
func get_ps()->PlayerData:
	#send_change_data.emit()
	return _player_state
