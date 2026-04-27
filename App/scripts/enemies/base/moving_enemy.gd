extends BaseEnemy
class_name MovingEnemy

# ============================================
# БАЗОВЫЙ КЛАСС ДЛЯ ДВИЖУЩИХСЯ ВРАГОВ
# ============================================
# Для врагов которые ходят по платформам:
# - schoolboy
# ============================================

# === ФИЗИЧЕСКИЕ КОНСТАНТЫ ===
const GRAVITY: float = 700.0

# === НАСТРОЙКИ ДВИЖЕНИЯ ===
@export var move_speed: float = 100.0        # Скорость движения
@export var jump_velocity: float = -175.0    # Сила прыжка

# === НАПРАВЛЕНИЕ ДВИЖЕНИЯ ===
enum Direction { LEFT, RIGHT, UP, DOWN }
@export var move_direction: Direction = Direction.RIGHT

# === КОМПОНЕНТЫ ===
@onready var ground_check: RayCast2D = $GroundCheck
@onready var wall_check_area: Area2D = $WallCheckArea

# === ВЫЧИСЛЯЕМЫЕ СВОЙСТВА ===
var direction_vector: Vector2:
	get:
		return Vector2.RIGHT if move_direction == Direction.RIGHT else Vector2.LEFT

# === СОСТОЯНИЯ ===
var wall_ahead: bool = false                 # Есть ли стена впереди


# ============================================
# НАСТРОЙКА
# ============================================

func _setup_components() -> void:
	"""
	Настройка компонентов движущегося врага.
	"""
	super._setup_components()
	_setup_ground_check()
	_setup_wall_check()
	_setup_sprite()

func _setup_ground_check() -> void:
	"""
	Настраивает проверку земли впереди.
	"""
	if ground_check:
		ground_check.target_position = Vector2(direction_vector.x * 20, 30)
		ground_check.enabled = true

func _setup_wall_check() -> void:
	"""
	Настраивает проверку стены впереди.
	"""
	if wall_check_area:
		wall_check_area.body_entered.connect(_on_wall_check_area_body_entered)
		wall_check_area.body_exited.connect(_on_wall_check_area_body_exited)
		_update_wall_check_position()

func _setup_sprite() -> void:
	"""
	Настраивает спрайт и анимацию.
	"""
	if animated_sprite:
		animated_sprite.play("move")
		animated_sprite.flip_h = (move_direction == Direction.RIGHT)


# ============================================
# ФИЗИКА И ДВИЖЕНИЕ
# ============================================

func _physics_process(delta: float) -> void:
	"""
	Обрабатывает физику и движение врага.
	"""
	if _is_exploding:
		return
	
	# Применяем гравитацию
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	# Двигаемся в текущем направлении
	velocity.x = direction_vector.x * move_speed
	
	# Прыгаем если впереди обрыв
	if is_on_floor() and not _is_ground_ahead():
		velocity.y = jump_velocity
	
	# Меняем направление если впереди стена
	if wall_ahead:
		_change_direction()
	
	move_and_slide()

func _on_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("terrain_deadly"):
		on_hit(999, "terrain_deadly")

# ============================================
# ПРОВЕРКИ ОКРУЖЕНИЯ
# ============================================

func _is_ground_ahead() -> bool:
	"""
	Проверяет есть ли земля впереди.
	Возвращает false если впереди обрыв.
	"""
	if not ground_check:
		return true
	
	ground_check.target_position = Vector2(direction_vector.x * 20, 30)
	ground_check.force_raycast_update()
	return ground_check.is_colliding()

func _on_wall_check_area_body_entered(body: Node2D) -> void:
	"""
	Вызывается когда область проверки стены касается препятствия.
	"""
	wall_ahead = true

func _on_wall_check_area_body_exited(body: Node2D) -> void:
	"""
	Вызывается когда область проверки стены перестает касаться препятствия.
	"""
	wall_ahead = false


# ============================================
# УПРАВЛЕНИЕ НАПРАВЛЕНИЕМ
# ============================================

func _change_direction() -> void:
	"""
	Меняет направление движения на противоположное.
	"""
	move_direction = Direction.LEFT if move_direction == Direction.RIGHT else Direction.RIGHT
	_update_sprite_flip()
	_update_ground_check()
	_update_wall_check_position()
	
	# Небольшая задержка чтобы не менять направление каждый кадр
	await get_tree().create_timer(0.1).timeout

func _update_sprite_flip() -> void:
	"""
	Обновляет отражение спрайта в зависимости от направления.
	"""
	if animated_sprite:
		animated_sprite.flip_h = (move_direction == Direction.RIGHT)

func _update_ground_check() -> void:
	"""
	Обновляет позицию проверки земли.
	"""
	if ground_check:
		ground_check.target_position = Vector2(direction_vector.x * 20, 30)

func _update_wall_check_position() -> void:
	"""
	Обновляет позицию области проверки стены.
	"""
	if not wall_check_area:
		return
	wall_check_area.position = Vector2(5 if move_direction == Direction.RIGHT else -5, 0)


# ============================================
# ПУБЛИЧНЫЕ МЕТОДЫ
# ============================================

func set_move_direction(dir: String) -> void:
	"""
	Устанавливает направление движения.
	
	Параметры:
	- dir: "left" или "right"
	"""
	move_direction = Direction.LEFT if dir == "left" else Direction.RIGHT
	_update_sprite_flip()
	_update_ground_check()
	_update_wall_check_position()
