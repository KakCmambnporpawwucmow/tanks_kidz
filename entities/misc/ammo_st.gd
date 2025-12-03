@tool

extends Panel
class_name AmmoState

@export var texture:Texture2D = null:
	set(value):
		texture = value
		$MarginContainer/VBoxContainer/view.texture = value

@export var title:String = "?":
	set(value):
		title = value
		$MarginContainer/VBoxContainer/HBoxContainer/title.text = tr(value)
		
@export var count:int = 0:
	set(value):
		count = value
		$MarginContainer/VBoxContainer/HBoxContainer/count.text = str(count)
		
@export var bold_state:bool = false:
	set(value):
		bold_state = value
		$bold.visible = bold_state
		
@export var ammo_type:WeaponSystem.ProjectileType = WeaponSystem.ProjectileType.AP

		
