# movement_controller.gd
extends Node
class_name MovementController

# Сигналы
signal jumped
signal landed
signal crouch_started
signal crouch_ended

# Константы
const SPEED: float = 100.0
const GRAVITY: float = 700.0
const JUMP_VELOCITY: float = -325.0

# Состояния
var is_jumping: bool = false
var is_crouching: bool = false
var can_move: bool = true

# Настройки коллайдера
var default_collider_pos: Vector2
var default_collider_scale: Vector2
const CROUCH_COLLIDER = {"pos": Vector2(0, 16), "scale": Vector2(1.7, 0.35)}
const JUMP_COLLIDER = {"pos": Vector2(0, 14), "scale": Vector2(0, 0.5)}

# Ссылки на узлы игрока
@onready var player: CharacterBody2D = $".."
@onready var collision_shape: CollisionShape2D = $"../CollisionShape2D"
@onready var damage_collision: CollisionShape2D = $"../Detector/CollisionShape2D"

func _ready():
	default_collider_pos = collision_shape.position
	default_collider_scale = collision_shape.scale

func apply_gravity(delta: float) -> void:
	if not player.is_on_floor(): 
		player.velocity.y += GRAVITY * delta

func handle_horizontal_movement(dir_x: float) -> void:
	if not can_move: 
		player.velocity.x = move_toward(player.velocity.x, 0, SPEED)
		return
	
	if not is_crouching and dir_x != 0:
		player.velocity.x = dir_x * SPEED
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, SPEED)

func handle_crouch(dir_x: float, crouch_pressed: bool) -> void:
	if crouch_pressed and dir_x == 0 and player.is_on_floor() and not is_jumping:
		if not is_crouching: 
			_set_collider(CROUCH_COLLIDER["pos"], CROUCH_COLLIDER["scale"])
			is_crouching = true
			crouch_started.emit()
	elif is_crouching:
		_reset_collider()
		is_crouching = false
		crouch_ended.emit()

func handle_jump(jump_pressed: bool) -> void:
	if not can_move:
		return
	if jump_pressed and player.is_on_floor() and not is_crouching:
		player.velocity.y = JUMP_VELOCITY
		is_jumping = true
		jumped.emit()

func reset_jump_on_landing() -> void:
	if player.is_on_floor() and is_jumping:
		is_jumping = false
		landed.emit()

func _set_collider(pos: Vector2, scl: Vector2) -> void:
	if scl.x: 
		collision_shape.scale.x = scl.x
		damage_collision.scale.x = scl.x
	if scl.y: 
		collision_shape.scale.y = scl.y
		damage_collision.scale.y = scl.y
	if pos.x: 
		collision_shape.position.x = pos.x
		damage_collision.position.x = pos.x
	if pos.y: 
		collision_shape.position.y = pos.y
		damage_collision.position.y = pos.y

func _reset_collider() -> void:
	collision_shape.position = default_collider_pos
	collision_shape.scale = default_collider_scale
	damage_collision.position = default_collider_pos
	damage_collision.scale = default_collider_scale

func is_on_ground() -> bool:
	return player.is_on_floor()
