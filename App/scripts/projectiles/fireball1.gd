extends BaseEnemyProjectile

# ============================================
# ФАЕРБОЛ (ОГНЕННЫЙ ШАР)
# ============================================
# Летит по дуге, подвержен гравитации.
# ============================================

# === ФИЗИЧЕСКИЕ КОНСТАНТЫ ===
const GRAVITY: float = 700.0
const FRICTION: float = 0.98

# === СПЕЦИФИЧНЫЕ НАСТРОЙКИ ===
@export var affected_by_gravity: bool = true   # Подвержен ли гравитации
@export var affected_by_friction: bool = true  # Подвержен ли трению
@export var burn_duration: float = 2.0         # Длительность горения
@export var burn_damage: int = 5               # Урон от горения за тик

# === ВНУТРЕННИЕ ПЕРЕМЕННЫЕ ===
var _velocity: Vector2 = Vector2.ZERO          # Текущая скорость
var _physics_timer: Timer = null               # Таймер для физики


# ============================================
# ИНИЦИАЛИЗАЦИЯ
# ============================================

func _ready() -> void:
	super._ready()
	
	# Устанавливаем значения по умолчанию
	speed = 0.0  # Не используем speed, своя физика
	damage = 20
	bullet_type = "fire"
	life_time = 3.0
	auto_delete_on_exit = true
	can_hit_shooter = false
	can_hit_player = true
	can_hit_enemies = false

func _initialize() -> void:
	"""
	Дополнительная инициализация фаербола.
	"""
	pass


# ============================================
# ФИЗИКА И ДВИЖЕНИЕ
# ============================================

func _move(delta: float) -> void:
	"""
	Переопределяем движение для использования физики.
	Фаербол движется по физическим законам с гравитацией.
	"""
	# Базовое движение не используется
	# Вместо этого используется apply_force() и _physics_timer
	pass

func apply_force(force: Vector2) -> void:
	"""
	Применяет силу броска к фаерболу.
	Вызывается врагом при создании.
	"""
	_velocity = force
	_start_physics()

func _start_physics() -> void:
	"""
	Запускает физическую симуляцию движения.
	"""
	if _physics_timer:
		return
	
	_physics_timer = Timer.new()
	_physics_timer.wait_time = 0.016  # ~60 FPS
	_physics_timer.timeout.connect(_on_physics_tick)
	add_child(_physics_timer)
	_physics_timer.start()

func _on_physics_tick() -> void:
	"""
	Обновляет позицию фаербола с учетом физики.
	"""
	if _is_queued_for_deletion:
		return
	
	# Обновляем позицию
	global_position += _velocity * 0.016
	
	# Применяем гравитацию
	if affected_by_gravity:
		_velocity.y += GRAVITY * 0.016
	
	# Применяем трение
	if affected_by_friction:
		_velocity.x *= FRICTION
	
	# Обновляем направление для визуальных эффектов
	if _velocity.length() > 0:
		direction = _velocity.normalized()


# ============================================
# ВИЗУАЛЬНЫЕ ЭФФЕКТЫ
# ============================================

func _update_visuals(delta: float) -> void:
	"""
	Обновляет анимацию и поворот фаербола.
	"""
	if not animated_sprite:
		return
	
	# Анимация движения
	if _velocity.length() > 10:
		if animated_sprite.sprite_frames.has_animation("move"):
			animated_sprite.play("move")
	else:
		if animated_sprite.sprite_frames.has_animation("idle"):
			animated_sprite.play("idle")
	
	# Поворот в сторону движения
	if _velocity.x != 0:
		animated_sprite.flip_h = _velocity.x > 0
