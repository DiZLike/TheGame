extends Area2D
class_name Explosion

# Параметры
var damage: int = 3
var explosion_radius: float = 50.0
var shooter: Node2D = null
var excluded_target: Node2D = null

@onready var _original_radius: float = 12.0
@onready var animation: AnimatedSprite2D = $ExplosionAnimation
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

@onready var sound: AudioStream = preload("res://data/audio/sounds/explosions/rocket_explosion.ogg")

func _ready() -> void:
	AudioManager.play_sfx(sound, 1, 1.0, global_position)
	# Настройка радиуса
	if collision_shape and collision_shape.shape is CircleShape2D:
		_original_radius = (collision_shape.shape as CircleShape2D).radius
	
	var target_scale = explosion_radius / _original_radius
	scale = Vector2(target_scale, target_scale)
	
	if animation:
		animation.play("explode")

func _on_body_entered(body: Node2D) -> void:
	# Исключаем исключённую цель
	if body == shooter or body == excluded_target or not body.is_in_group("enemy"):
		return
	
	if body.has_method("on_hit"):
		body.on_hit(damage, "explosion")

func _on_animation_finished() -> void:
	queue_free()
