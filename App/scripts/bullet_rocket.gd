extends Area2D
class_name BulletRocket

var direction: Vector2 = Vector2.RIGHT
var shooter: Node2D = null
var speed: float = 200.0
var damage: int = 3
var explosion_radius: float = 50.0

var _has_exploded: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	if _has_exploded:
		return
	
	global_position += direction * speed * delta
	if animated_sprite:
		animated_sprite.rotation = direction.angle()

func _on_body_entered(body: Node2D) -> void:
	if _has_exploded:
		return
	
	if body == shooter:
		return
	
	if body.is_in_group("enemy") and body.has_method("on_hit"):
		body.on_hit(damage, "rocket")
	
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
	explosion.damage = damage  # Просто передаём число
	explosion.explosion_radius = explosion_radius
	explosion.shooter = shooter
	
	get_tree().current_scene.add_child(explosion)
	WeaponManager.remove_bullet()
	queue_free()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	WeaponManager.remove_bullet()
	queue_free()
