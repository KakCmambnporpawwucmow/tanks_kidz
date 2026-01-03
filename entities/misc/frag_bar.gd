extends Panel

class_name FragBar

@export var my_command_max:int = 10
@export var enemy_command_max:int = 10

signal send_game_done()

func output_info():
	$Label.text = "{0} | {1}".format([my_command_max, enemy_command_max])

func _ready() -> void:
	output_info()

func frag_count_changed(tank:Tank):
	match tank.get_player_command():
		Tank.EPlayers.MY:
			my_command_max -= 1
		Tank.EPlayers.ENEMY:
			enemy_command_max -= 1
	if my_command_max < 1 or enemy_command_max < 1:
		send_game_done.emit()
	output_info()
