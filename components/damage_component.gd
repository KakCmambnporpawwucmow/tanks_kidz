# Механика нанесения урона. Применяется к другому компоненту, результат передаётся родителю.

extends Node
class_name DamageComponent

# сопротивляемость урону, проще говоря твёрдость. Делитель наносимого урона от врага.
@export var resistance:float = 1
@export var damage:float = 1
@export var hitpoints:float = 1

const end_parent_method = "die"

func calculate_damage(dc:DamageComponent):
	if is_instance_valid(dc):
		# враг наносит урон по нам
		hitpoints -= dc.damage / resistance
		# мы умерли
		if hitpoints < 1:
			var parent = get_parent() as Node2D
			if is_instance_valid(parent) and parent.has_method(end_parent_method):
				parent.call_deferred(end_parent_method)
