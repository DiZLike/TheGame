extends BulletBase
class_name BulletRocket

var explosion_radius: float = 50.0
var _has_exploded: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	bullet_type = "rocket"
	speed = 200.0
	damage = 3
	super()
	# Принудительно обновляем поворот после инициализации
	_update_visual_rotation()

func _update_visual_rotation() -> void:
	if animated_sprite:
		animated_sprite.rotation = direction.angle()

@warning_ignore("unused_parameter")
func _on_hit_enemy(enemy: Node2D) -> void:
	call_deferred("_explode")

@warning_ignore("unused_parameter")
func _on_other_collision(body: Node2D) -> void:
	call_deferred("_explode")

func _explode() -> void:
	if _has_exploded:
		return
	
	_has_exploded = true
	
	if animated_sprite:
		animated_sprite.visible = false
	
	var explosion_scene = preload("res://scenes/effects/explosion_01.tscn")
	var explosion = explosion_scene.instantiate() as Explosion
	
	explosion.global_position = global_position
	explosion.damage = damage
	explosion.explosion_radius = explosion_radius
	explosion.shooter = shooter
	
	get_tree().current_scene.add_child(explosion)
	_queue_free()
