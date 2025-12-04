# projectile.gd
extends RigidBody2D
class_name Projectile

@export_group("Projectile Settings")
@export var initial_speed: float = 300.0
@export var min_speed:int = 100
@export var armor_penetration:int = 50

@onready var visible_notifier = $VisibleOnScreenNotifier2D

func activate(fire_position: Vector2, fire_direction: Vector2):
	global_position = fire_position
	global_rotation = fire_direction.angle()
	linear_velocity = fire_direction * initial_speed
	
func on_death(_damage:int = 0):
	linear_velocity = Vector2.ZERO
	$view.visible = false
	if _damage > 0:
		$PenetrationMarker/Label.text = str($DamageComponent.get_current_damage())
		$AnimationPlayer.play("penetracion")
	elif _damage == -1:
		$AnimationPlayer.play("false_explose")
	else:
		queue_free()

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

func _on_body_shape_entered(body_rid: RID, body: Node, body_shape_index: int, local_shape_index: int) -> void:
	if body is Tank:
		var body_shape_owner_id = body.shape_find_owner(body_shape_index)
		if body_shape_owner_id != -1:
			var body_shape = body.shape_owner_get_owner(body_shape_owner_id).shape
			# пробили
			if body_shape is RectangleShape2D and armor_penetration >= min(body_shape.size.x, body_shape.size.y): 
				var damage = $DamageComponent.execute(body.health_component)
				on_death(damage)
			# не пробили
			else:
				$AnimationPlayer.play("ricoshet")
		# попали в танк
		$DamageComponent.done()
	elif body is Obstacle:
		var health = body.get_health()
		if health != null:
			var damage = $DamageComponent.execute(health)
			on_death(damage)
