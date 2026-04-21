extends BulletBase
class_name BulletHoming

var flight_time: float = 3.0
var homing_strength: float = 0.05
var search_radius: float = 250.0
var spawn_deviation: float = 10.0
var explosion_radius: float = 15.0

var _has_exploded: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	bullet_type = "homing"
	life_time = flight_time
	auto_delete_on_exit = false  # Самоуничтожится по таймеру
	
	_apply_spawn_deviation()
	super()
	
func _on_life_timeout() -> void:
	_explode()

func _update_visual_rotation() -> void:
	if animated_sprite:
		animated_sprite.rotation = direction.angle()

func _apply_spawn_deviation() -> void:
	var deviation_angle = deg_to_rad(randf_range(-spawn_deviation, spawn_deviation))
	direction = direction.rotated(deviation_angle).normalized()

@warning_ignore("unused_parameter")
func _on_physics_process(delta: float) -> void:
	var target = _find_nearest_enemy()
	
	if target:
		var to_target = (target.global_position - global_position).normalized()
		direction = direction.lerp(to_target, homing_strength).normalized()

func _find_nearest_enemy() -> Node2D:
	var nearest = null
	var nearest_dist = search_radius
	
	for enemy in get_tree().get_nodes_in_group("enemy"):
		var dist = global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	
	return nearest

@warning_ignore("unused_parameter")
func _on_hit_enemy(enemy: Node2D) -> void:
	call_deferred("_explode")

@warning_ignore("unused_parameter")
func _on_other_collision(body: Node2D) -> void:
	if body.is_in_group("terrain") or body.is_in_group("terrain_deadly"):
		return
	call_deferred("_explode")

func _explode() -> void:
	if _has_exploded:
		return
	
	_has_exploded = true
	
	var explosion_scene = preload("res://scenes/effects/explosion_01.tscn")
	var explosion = explosion_scene.instantiate() as Explosion
	
	explosion.global_position = global_position
	explosion.damage = damage
	explosion.explosion_radius = explosion_radius
	explosion.shooter = shooter
	
	get_tree().current_scene.add_child(explosion)
	_queue_free()
