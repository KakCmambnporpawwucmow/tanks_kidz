# armor_component.gd
class_name ArmorComponent
extends StaticBody2D

@export_group("Armor Properties")
@export var thickness: float = 50.0  # Толщина брони

@export_group("Dependencies")
@export var health_component: HealthComponent = null

func _ready():
	# Обязательно должен быть назначен HealthComponent
	assert(health_component != null, "ArmorComponent: HealthComponent must be assigned in editor or code")

func check_penetration(armor_penetration:int, damage:int) -> bool:
	if armor_penetration >= thickness:
		health_component.take_damage(damage)
		return true
	return false
