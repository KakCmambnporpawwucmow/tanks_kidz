extends Node2D

class_name CommandProducer
const add_method_name = "add_receiver"

@export var _resivers:Array[Node2D]
var tankMoveCommand:MoveCommand = null
var tankRotateCommand:RotateCommand = null
var tankFireCommand:ShootCommand = null
var tankSwitchAmmoCommand:SwitchAmmoCommand = null
var rotateToCommand:RotateToCommand = null
var currentCommand:Command = null

func _ready() -> void:
	tankMoveCommand = MoveCommand.new()
	tankRotateCommand = RotateCommand.new()
	tankFireCommand = ShootCommand.new()
	tankSwitchAmmoCommand = SwitchAmmoCommand.new()
	rotateToCommand = RotateToCommand.new()
	
	for item in _resivers:
		if is_instance_valid(item):
			assert(item.has_method("proc_command"), "CommandProducer: all resivers must have method 'proc_command'")

func _input(event):
	currentCommand = null
	# Управление движением танка
	if event.is_action_pressed("move_forward"):
		currentCommand = tankMoveCommand.init(Vector2.RIGHT)
	if event.is_action_pressed("move_backward"):
		currentCommand = tankMoveCommand.init(Vector2.LEFT)
	if event.is_action_released("move_forward") || event.is_action_released("move_backward"):
		currentCommand = tankMoveCommand.init(Vector2.ZERO)
		
	# Управление поворотом
	if event.is_action_pressed("rotate_left"):
		currentCommand = tankRotateCommand.init(Tank.ERotate.LEFT)
	if event.is_action_pressed("rotate_right"):
		currentCommand = tankRotateCommand.init(Tank.ERotate.RIGHT)
	if event.is_action_released("rotate_left") || event.is_action_released("rotate_right"):
		currentCommand = tankRotateCommand.init(Tank.ERotate.STOP)
	
	# Управление стрельбой
	if event.is_action_pressed("fire"):
		currentCommand = tankFireCommand.init()
		
	# Управление переключением боеприпасов
	if event.is_action_pressed("ammo_ap"):
		currentCommand = tankSwitchAmmoCommand.init(WeaponSystem.ProjectileType.AP)
	elif event.is_action_pressed("ammo_he"):
		currentCommand = tankSwitchAmmoCommand.init(WeaponSystem.ProjectileType.HE)
	elif event.is_action_pressed("ammo_heat"):
		currentCommand = tankSwitchAmmoCommand.init(WeaponSystem.ProjectileType.HEAT)
	elif event.is_action_pressed("ammo_missile"):
		currentCommand = tankSwitchAmmoCommand.init(WeaponSystem.ProjectileType.MISSILE)

	if event is InputEventMouseMotion:
		currentCommand = rotateToCommand.init(get_global_mouse_position())
		
	var is_need_filtering:bool = false
	if currentCommand:
		for item in _resivers:
			if is_instance_valid(item) and item.has_method("proc_command"):
				item.proc_command(currentCommand)
			else:
				is_need_filtering = true

		if is_need_filtering:
			_resivers = _resivers.filter(func(item): return item != null)

func add_receiver(node:Node2D)->bool:
	if node.has_method("proc_command"):
		_resivers.append(node)
		return true
	return false
	
func get_receivers_count()->int:
	return _resivers.size()
	
func get_receiver(idx:int)->Node2D:
	return _resivers[idx] if not _resivers.is_empty() and _resivers.size() - 1 >= idx and idx > -1 else null 
