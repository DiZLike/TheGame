# shoot_controller.gd
extends Node
class_name ShootController

var is_shooting: bool = false

const SHOOT_POS = {
	"jump": {
		Vector2(1,-1): Vector2(10,3),
		Vector2(-1,-1): Vector2(-10,3),
		Vector2(1,1): Vector2(10,22),
		Vector2(-1,1): Vector2(-10,22),
		Vector2(0,-1): Vector2(0,3),
		Vector2(0,1): Vector2(0,22)
	},
	"move": {
		Vector2(1,-1): Vector2(14,-12),
		Vector2(-1,-1): Vector2(-14,-12),
		Vector2(1,1): Vector2(14,9),
		Vector2(-1,1): Vector2(-14,9)
	}
}

@onready var player: CharacterBody2D = $".."
@onready var shoot_point: Marker2D = $"../ShootPoint"
@onready var animated_sprite: AnimatedSprite2D = $"../AnimatedSprite2D"
@onready var movement_controller: MovementController = $"../MovementController"

func try_shoot(input_dir: Vector2) -> bool:
	if is_shooting:
		return false
	
	is_shooting = true
	_update_shoot_point(input_dir)
	
	var dir = input_dir.normalized() if input_dir != Vector2.ZERO else (Vector2.RIGHT if not animated_sprite.flip_h else Vector2.LEFT)
	WeaponManager.try_shoot(player, shoot_point, dir)
	
	await get_tree().create_timer(0.05).timeout
	is_shooting = false
	return true

func _update_shoot_point(input_dir: Vector2) -> void:
	var flip = animated_sprite.flip_h
	var key = Vector2(sign(input_dir.x), sign(input_dir.y))
	
	if movement_controller.is_crouching:
		shoot_point.position = Vector2(15, 14) if not flip else Vector2(-15, 14)
	elif not movement_controller.is_jumping:
		shoot_point.position = SHOOT_POS["move"].get(key, Vector2(14 if not flip else -14, 1) if input_dir.y >= 0 else Vector2(2 if not flip else -2, -23))
	else:
		shoot_point.position = SHOOT_POS["jump"].get(key, Vector2(9 if not flip else -9, 11))
