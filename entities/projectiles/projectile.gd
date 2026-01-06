# projectile.gd
extends RigidBody2D
class_name Projectile

@export_group("Projectile Settings")
@export var initial_speed: float = 300.0
@export var min_speed:int = 100
@export var armor_penetration:int = 50
@export var to_statistics:bool = false

@onready var visible_notifier = $VisibleOnScreenNotifier2D

func activate(fire_position: Vector2, fire_direction: Vector2)->Vector2:
	global_position = fire_position
	global_rotation = fire_direction.angle()
	linear_velocity = fire_direction * initial_speed
	return linear_velocity
	
func on_death(_damage:int = 0):
	linear_velocity = Vector2.ZERO
	$view.visible = false
	if _damage > 0:
		$PenetrationMarker/Label.text = str($DamageComponent.get_current_damage())
		$AnimationPlayer.play("penetracion")
	else:
		$AnimationPlayer.play("ricoshet")

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	if to_statistics:
		PlayerState.get_ps().battle_miss += 1
	queue_free()

func _on_body_shape_entered(_body_rid: RID, body: Node, body_shape_index: int, _local_shape_index: int) -> void:
	var damage:int = 0
	if is_instance_valid(body) and body.has_method("get_health"):
		if body is Tank:
			var body_shape_owner_id = body.shape_find_owner(body_shape_index)
			if body_shape_owner_id != -1:
				var body_shape = body.shape_owner_get_owner(body_shape_owner_id).shape
				# пробили, толщина брони меньше или равна пробитию снаряда
				if body_shape is RectangleShape2D and armor_penetration >= min(body_shape.size.x, body_shape.size.y): 
					var enemy_health_com:HealthComponent = body.get_health()
					damage = $DamageComponent.execute(enemy_health_com)
					if to_statistics:
						if enemy_health_com.is_alive == false:
							PlayerState.get_ps().battle_frags += 1
						if damage > 0:
							PlayerState.get_ps().battle_damage += damage
							PlayerState.get_ps().battle_hit += 1
				else:
					if to_statistics:
						PlayerState.get_ps().battle_ricoche += 1
						
		# урон по препятствию если оно разрушаемое
		if body is Obstacle:
			damage = $DamageComponent.execute(body.get_health())
		if to_statistics:
			PlayerState.get_ps().battle_miss += 1
	on_death(damage)
	# деактивируем снаряд, иначе пока идёт анимация он сможет нанести урон другим объектам.
	$DamageComponent.done()
			
func get_damage()->int:
	return $DamageComponent.damage
