@tool

extends Panel
class_name AmmoState

@export var texture:Texture2D = null:
	set(value):
		texture = value
		if has_node("MarginContainer/VBoxContainer/view"):
			$MarginContainer/VBoxContainer/view.texture = value

@export var title:String = "?":
	set(value):
		title = value
		if has_node("MarginContainer/VBoxContainer/HBoxContainer/title"):
			$MarginContainer/VBoxContainer/HBoxContainer/title.text = tr(value)
		
@export var count:int = 0:
	set(value):
		count = value
		if has_node("MarginContainer/VBoxContainer/HBoxContainer/count"):
			$MarginContainer/VBoxContainer/HBoxContainer/count.text = str(count)
		
@export var bold_state:bool = false:
	set(value):
		bold_state = value
		if has_node("bold"):
			$bold.visible = bold_state
		
@export var ammo_type:WeaponSystem.ProjectileType = WeaponSystem.ProjectileType.AP

func _on_view_ready() -> void:
	$MarginContainer/VBoxContainer/view.texture = texture

func _on_title_ready() -> void:
	$MarginContainer/VBoxContainer/HBoxContainer/title.text = tr(title)

func _on_count_ready() -> void:
	$MarginContainer/VBoxContainer/HBoxContainer/count.text = str(count)

func _on_bold_ready() -> void:
	$bold.visible = bold_state
