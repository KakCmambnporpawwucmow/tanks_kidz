# projectile.gd
extends RigidBody2D
class_name Projectile

@export_group("Projectile Settings")
@export var initial_speed: float = 300.0
@export var damage:int = 100
@export var min_speed:int = 100
@export var armor_penetration:int = 50

@onready var visible_notifier = $VisibleOnScreenNotifier2D

func _ready():
	set_physics_process(false)
	
func activate(fire_position: Vector2, fire_direction: Vector2):
	global_position = fire_position
	global_rotation = fire_direction.angle()
	linear_velocity = fire_direction * initial_speed
	set_physics_process(true)

func on_death(_damage:int = 0):
	set_physics_process(false)
	linear_velocity = Vector2.ZERO
	$view.visible = false
	if _damage > 0:
		$PenetrationMarker/Label.text = str(damage)
		$AnimationPlayer.play("penetracion")
	else:
		queue_free()

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

func _on_body_entered(body: Node) -> void:
	if body is ArmorComponent:
		if body.check_penetration(armor_penetration, damage):
			on_death(damage)
		else:
			$AnimationPlayer.play("ricoshet")
