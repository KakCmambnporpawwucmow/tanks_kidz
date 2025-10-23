extends RigidBody2D
class_name BaseShell

@export var force:int = 200
@export var shell_name:String = "None"
@export var count_in_turret:int = 0

# выходя за пределы карты - подрываем заряд
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	die()
	
func fire_to(aim:Vector2):
	look_at(aim)
	# смещение от базового положения узла
	rotation += deg_to_rad(90)
	# Применяем импульс в направлении цели. aim - глобальная позиция
	apply_impulse((aim - global_position).normalized() * force)
	
# ВАЖНО! Все разрушаемые и наносящие урон объекты должны реализовывать методы die() и get_damage_component()
# так как унаследовать их от одного интерфейса нельзя, то нужно добавлять их ко всем объектам с уроном.
func die():
	queue_free()
	
func get_damage_component()->DamageComponent:
	return $DamageComponent

func _on_body_entered(body: Node) -> void:
	if body.has_method("get_damage_component"):
		# удар по нам
		var enemy_dc = body.get_damage_component()
		if is_instance_valid(enemy_dc):
			$DamageComponent.calculate_damage(enemy_dc)
			# мы наносим урон по врагу
			enemy_dc.calculate_damage($DamageComponent)
