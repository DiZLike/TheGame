# animation_controller.gd
extends Node
class_name AnimationController

@onready var player: CharacterBody2D = $".."
@onready var animated_sprite: AnimatedSprite2D = $"../AnimatedSprite2D"
@onready var movement_controller: MovementController = $"../MovementController"
@onready var shoot_controller: ShootController = $"../ShootController"

func update_animation(dir_x: float, dir_y: float) -> void:
	var can_move = movement_controller.can_move
	
	# Добавить проверку can_move в самом начале
	if not can_move:
		# При блокировке управления оставляем текущую анимацию
		# или устанавливаем idle
		if not animated_sprite.animation.begins_with("idle"):
			animated_sprite.play("idle")
		return
	
	if movement_controller.is_crouching:
		animated_sprite.play("down")
		return
	
	if movement_controller.is_on_ground():
		movement_controller._reset_collider()
		
		if dir_y > 0 and dir_x == 0:
			animated_sprite.play("up")
		elif dir_y > 0 and dir_x != 0:
			animated_sprite.play("shootUp")
		elif dir_y < 0 and dir_x != 0:
			animated_sprite.play("shootDown")
		elif shoot_controller.is_shooting:
			animated_sprite.play("shootLine" if dir_x != 0 and dir_y == 0 else "shoot")
		else:
			animated_sprite.play("move" if dir_x != 0 else "idle")
	else:
		if movement_controller.is_jumping:
			animated_sprite.play("jump")
			movement_controller._set_collider(MovementController.JUMP_COLLIDER["pos"], MovementController.JUMP_COLLIDER["scale"])
		else:
			animated_sprite.play("fall")
			movement_controller._reset_collider()

func set_flip_h(flip: bool) -> void:
	animated_sprite.flip_h = flip

func get_flip_h() -> bool:
	return animated_sprite.flip_h
