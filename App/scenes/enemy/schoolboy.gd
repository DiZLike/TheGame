extends CharacterBody2D

const SPEED: float = 100.0
const GRAVITY: float = 700.0
const JUMP_VELOCITY: float = -175.0

enum Direction { LEFT, RIGHT }

@export var move_direction: Direction = Direction.RIGHT
@export var explosion_force: float = 50.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var ground_check: RayCast2D = $GroundCheck
@onready var wall_check_area: Area2D = $WallCheckArea
@onready var visible_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

var health = 1

# Предзагружаем сцену взрыва
var pixel_explosion_scene: PackedScene = preload("res://scenes/effects/pixel_explosion.tscn")

var direction_vector: Vector2:
	get:
		return Vector2.RIGHT if move_direction == Direction.RIGHT else Vector2.LEFT
		
var wall_ahead: bool = false
var _is_exploding: bool = false
var _is_remove_canceled = true

func _ready() -> void:
	_setup_ground_check()
	_setup_wall_check()
	_setup_sprite()

func _setup_ground_check() -> void:
	if ground_check:
		ground_check.target_position = Vector2(direction_vector.x * 20, 30)
		ground_check.enabled = true

func _setup_wall_check() -> void:
	if wall_check_area:
		wall_check_area.body_entered.connect(_on_wall_check_area_body_entered)
		wall_check_area.body_exited.connect(_on_wall_check_area_body_exited)
		_update_wall_check_position()

func _setup_sprite() -> void:
	if animated_sprite:
		animated_sprite.play("move")
		animated_sprite.flip_h = (move_direction == Direction.RIGHT)

func _physics_process(delta: float) -> void:
	if _is_exploding:
		return
		
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	velocity.x = direction_vector.x * SPEED
	
	if is_on_floor() and not _is_ground_ahead():
		velocity.y = JUMP_VELOCITY
	
	if wall_ahead:
		change_direction()
	
	move_and_slide()

func on_hit(damage: int, bullet: String) -> void:
	health -= damage
	if health > 0:
		return
	if _is_exploding:
		return
	
	# Устанавливаем силу взрыва в зависимости от типа пули
	match bullet:
		"rocket":
			explosion_force = 800
		"homing":
			explosion_force = 500
	
	_is_exploding = true
	call_deferred("_explode")

func _explode() -> void:
	# Создаем сцену взрыва
	var explosion = pixel_explosion_scene.instantiate()
	get_tree().root.add_child(explosion)
	
	# Запускаем взрыв от текущего спрайта
	explosion.explode_from_animated_sprite(animated_sprite, global_position, explosion_force)
	
	# Скрываем оригинального персонажа
	visible = false
	collision_shape.disabled = true
	animated_sprite.visible = false
	
	# Удаляем персонажа после небольшой задержки
	await get_tree().create_timer(0.5).timeout
	queue_free()

func _on_screen_exited() -> void:
	_is_remove_canceled = false
	await get_tree().create_timer(10).timeout
	if not _is_remove_canceled:
		queue_free()
	
func _on_screen_entered() -> void:
	_is_remove_canceled = true

func _is_ground_ahead() -> bool:
	if not ground_check:
		return true
	
	ground_check.target_position = Vector2(direction_vector.x * 20, 30)
	ground_check.force_raycast_update()
	return ground_check.is_colliding()

func _update_wall_check_position() -> void:
	if not wall_check_area:
		return
	wall_check_area.position = Vector2(5 if move_direction == Direction.RIGHT else -5, 0)

func _on_wall_check_area_body_entered(body: Node2D) -> void:
	wall_ahead = true

func _on_wall_check_area_body_exited(body: Node2D) -> void:
	wall_ahead = false

func set_move_direction(dir: String) -> void:
	move_direction = Direction.LEFT if dir == "left" else Direction.RIGHT
	_update_sprite_flip()
	_update_ground_check()
	_update_wall_check_position()

func change_direction() -> void:
	move_direction = Direction.LEFT if move_direction == Direction.RIGHT else Direction.RIGHT
	_update_sprite_flip()
	_update_ground_check()
	_update_wall_check_position()
	await get_tree().create_timer(0.1).timeout

func _update_sprite_flip() -> void:
	if animated_sprite:
		animated_sprite.flip_h = (move_direction == Direction.RIGHT)

func _update_ground_check() -> void:
	if ground_check:
		ground_check.target_position = Vector2(direction_vector.x * 20, 30)
