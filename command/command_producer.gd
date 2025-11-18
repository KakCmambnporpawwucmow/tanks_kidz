extends Node2D

class_name CommandProducer

@export var tank:Tank
var tankMoveCommand:TankMoveCommand = null
var tankRotateCommand:TankRotateCommand = null
var tankFireCommand:TankShootCommand = null
var tankSwitchAmmoCommand:TankSwitchAmmoCommand = null
var currentCommand:Command = null

func _ready() -> void:
	tankMoveCommand = TankMoveCommand.new()
	tankRotateCommand = TankRotateCommand.new()
	tankFireCommand = TankShootCommand.new()
	tankSwitchAmmoCommand = TankSwitchAmmoCommand.new()

func _input(event):
	currentCommand = null
	# Управление движением танка
	if event.is_action_pressed("move_forward"):
		currentCommand = tankMoveCommand.init(Vector2.RIGHT)
	if event.is_action_pressed("move_backward"):
		currentCommand = tankMoveCommand.init(Vector2.LEFT)
	if event.is_action_released("move_forward") || event.is_action_released("move_backward"):
		currentCommand = tankMoveCommand.init(Vector2.ZERO)
	
	if event.is_action_pressed("rotate_left"):
		currentCommand = tankRotateCommand.init(Tank.ERotate.LEFT)
	if event.is_action_pressed("rotate_right"):
		currentCommand = tankRotateCommand.init(Tank.ERotate.RIGHT)
	if event.is_action_released("rotate_left") || event.is_action_released("rotate_right"):
		currentCommand = tankRotateCommand.init(Tank.ERotate.STOP)
	
	
	# Управление стрельбой и боеприпасами
	if event.is_action_pressed("fire"):
		currentCommand = tankFireCommand
	
	if event.is_action_pressed("ammo_ap"):
		currentCommand = tankSwitchAmmoCommand.init(WeaponSystem.ProjectileType.AP)
	elif event.is_action_pressed("ammo_he"):
		currentCommand = tankSwitchAmmoCommand.init(WeaponSystem.ProjectileType.HE)
	elif event.is_action_pressed("ammo_heat"):
		currentCommand = tankSwitchAmmoCommand.init(WeaponSystem.ProjectileType.HEAT)
	elif event.is_action_pressed("ammo_missile"):
		currentCommand = tankSwitchAmmoCommand.init(WeaponSystem.ProjectileType.MISSILE)
		
	if currentCommand:
		tank.proc_command(currentCommand)
