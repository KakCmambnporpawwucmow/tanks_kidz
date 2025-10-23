extends Node2D
	
@export var rotation_speed:float = 2

@onready var cannon:BaseCannon = $BaseCannon
@onready var mover:MoveComponent = $MoveComponent

var _current_shell:BaseShell = null

func _ready() -> void:
	mover.rotation_speed = rotation_speed
	_current_shell = $shell_bb
	load_shell()

func _input(event):
	if event is InputEventMouseMotion:
		mover.smooth_look_at(get_global_mouse_position())
	if event is InputEventMouseButton and event.is_pressed():
		fire()
		load_shell()
		
func load_shell():
	if is_instance_valid(_current_shell) \
	and is_instance_valid(cannon) \
	and _current_shell.count_in_turret > 0:
		var new_shell = _current_shell.duplicate()
		new_shell.sleeping = false
		cannon.load_shell(new_shell)
		
func fire():
	if is_instance_valid(_current_shell) \
	and is_instance_valid(cannon) \
	and _current_shell.count_in_turret > 0:
		$blast_animation.play("blast")
		cannon.fire()
		_current_shell.count_in_turret -= 1
