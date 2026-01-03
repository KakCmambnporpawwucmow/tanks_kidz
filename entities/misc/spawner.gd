extends Node2D

class_name Spawner

@export_group("Tank")
@export var tank_ps:PackedScene = null
@export var spawn_count:int = 1
@export var player_command:Tank.EPlayers = Tank.EPlayers.ENEMY
@export_group("Tank manual")
@export var command_producer:CommandProducer = null
@export var ammo_stat:AmmoStatistic = null
@export var health_bar_stat:HealthBar = null
@export_group("Tank camera")
@export var limit_top:int = 0
@export var limit_bottom:int = 0
@export var limit_right:int = 0
@export var limit_left:int = 0


func _ready() -> void:
	spawn()
	
func _on_child_exiting_tree(node: Node) -> void:
	Logi.info("Spawn: remove tank {0} from layer".format([node.name]))
	if spawn_count > 0 and $Timer.is_inside_tree():
		$Timer.start()

func spawn():
	if tank_ps != null and spawn_count > 0:
		var new_tank = tank_ps.instantiate() as Tank
		new_tank.set_player_command(player_command)
		add_child(new_tank)
		# инициализируем танк под управлением игрока с источником команд от UI и барами статы.
		if ammo_stat != null:
			ammo_stat.set_game_object(new_tank)
		if health_bar_stat != null:
			health_bar_stat.set_game_object(new_tank)	
		if command_producer != null:
			command_producer.add_receiver(new_tank)
			var camera = Camera2D.new()
			camera.limit_top = limit_top
			camera.limit_bottom = limit_bottom
			camera.limit_right = limit_right
			camera.limit_left = limit_left
			new_tank.add_child(camera)
			camera.enabled = true
		spawn_count -= 1
		
		Logi.info("Spawn: add tank {0}, spawn count {1}".format([new_tank.name, spawn_count]))


func _on_timer_timeout() -> void:
	spawn()
