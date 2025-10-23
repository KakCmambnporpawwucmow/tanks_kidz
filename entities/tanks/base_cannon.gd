extends Node2D

class_name BaseCannon

var _loaded_shell:BaseShell = null

func load_shell(shell:BaseShell):
	var parent = shell.get_parent()
	if is_instance_valid(parent):
		parent.remove_child(shell)
	_loaded_shell = shell
	_loaded_shell.visible = true

func fire():
	if is_instance_valid(_loaded_shell):
		get_tree().current_scene.add_child(_loaded_shell)
		_loaded_shell.global_position = $mazzle_from.global_position
		_loaded_shell.visible = true
		_loaded_shell.fire_to($mazzle_to.global_position)
		_loaded_shell = null
