extends CharacterBody2D
# ============================================
# НАСТРОЙКИ (видны в редакторе)
# ============================================
@export var bounce_force: float = -150.0           # Сила отскока от земли

# ============================================
# КОМПОНЕНТЫ
# ============================================
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

# ============================================
# ФИЗИКА
# ============================================
var grav: float = 700.0  # Та же гравитация, что у игрока
var _picked: bool = false

# ============================================
# ИНИЦИАЛИЗАЦИЯ
# ============================================
func _ready() -> void:
	# Включаем физику
	set_physics_process(true)

# ============================================
# ФИЗИКА (CharacterBody2D)
# ============================================
func _physics_process(delta: float) -> void:
	# Применяем гравитацию
	velocity.y += grav * delta
	
	# Двигаем с автоматическим обнаружением столкновений
	move_and_slide()
	
	# Проверяем отскок от земли
	if is_on_floor() and bounce_force < 0:
		velocity.y = bounce_force
		bounce_force *= 0.7
		if bounce_force < -50:
			velocity.x = randf_range(-50, 50)
		else:
			bounce_force = 0
			velocity.x = 0
		move_and_slide()

# ============================================
# ПОДБОР ПРЕДМЕТА
# ============================================
func _on_body_entered(body: Node2D) -> void:
	# Только игрок подбирает
	if not body.is_in_group("player"):
		return
	
	# Защита от двойного подбора
	if _picked:
		return
	
	_picked = true
	
	GameManager.add_lives(1)
	
	# Эффект подбора
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(0, 0), 0.1)
	
	await tween.finished
	queue_free()
