extends Node2D

@export var tank_ps:PackedScene = null
@export var spawn_count:int = 1
@export var command_producer:CommandProducer = null
@export var ammo_stat:AmmoStatistic = null
@export var limit_top:int = 0
@export var limit_bottom:int = 0
@export var limit_right:int = 0
@export var limit_left:int = 0


func _ready() -> void:
	spawn()
	
func _on_child_exiting_tree(node: Node) -> void:
	Logi.info("Spawn: remove tank {0} from layer".format([node.name]))
	$Timer.start()

func spawn():
	if tank_ps != null and spawn_count > 0:
		var new_tank = tank_ps.instantiate() as Tank
		add_child(new_tank)
		if ammo_stat != null:
			ammo_stat.set_game_object(new_tank)
		if command_producer != null:
			command_producer.add_receiver(new_tank)
		spawn_count -= 1
		var camera = Camera2D.new()
		camera.limit_top = limit_top
		camera.limit_bottom = limit_bottom
		camera.limit_right = limit_right
		camera.limit_left = limit_left
		new_tank.add_child(camera)
		camera.enabled = true
		Logi.info("Spawn: add tank {0}, spawn count {1}".format([new_tank.name, spawn_count]))


func _on_timer_timeout() -> void:
	spawn()
