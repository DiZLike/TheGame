extends CharacterBody2D

const GRAVITY: float = 700.0
const FRICTION: float = 0.98  # Замедление со временем

@export var lifetime: float = 3.0  # Время жизни огня

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _is_alive: bool = true

func _ready() -> void:
	# Запускаем анимацию
	if animated_sprite:
		animated_sprite.play("idle")
	
	# Автоматическое удаление через время
	await get_tree().create_timer(lifetime).timeout
	if _is_alive:
		queue_free()

func _physics_process(delta: float) -> void:
	if not _is_alive:
		return
	
	# Применяем гравитацию
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	# Замедление (сопротивление воздуха)
	velocity.x *= FRICTION
	
	move_and_slide()

func apply_force(force: Vector2) -> void:
	velocity = force
