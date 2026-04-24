@tool
extends StaticEnemy
class_name SpitterEnemy

# ============================================
# БАЗОВЫЙ КЛАСС ДЛЯ ВРАГОВ-ПЛЕВАКОВ
# ============================================
# Для врагов, подбрасывающих снаряды вверх со случайной силой.
# Снаряды создают пиксельный взрыв при касании с землёй.
# ============================================

# === НАСТРОЙКИ СНАРЯДОВ ===
@export var projectile_scene: PackedScene          # Сцена снаряда (переопределить в дочернем)
@export var projectile_gravity: float = 500.0:      # Гравитация снаряда
	set(value):
		projectile_gravity = value
		queue_redraw()

# === ДИАПАЗОН СИЛЫ БРОСКА ===
@export var min_throw_force: float = 150.0:         # Минимальная вертикальная скорость
	set(value):
		min_throw_force = value
		queue_redraw()

@export var max_throw_force: float = 250.0:         # Максимальная вертикальная скорость
	set(value):
		max_throw_force = value
		queue_redraw()

# === БОКОВОЙ РАЗБРОС ===
@export var horizontal_spread: float = 50.0:        # Максимальное отклонение по X (+/-)
	set(value):
		horizontal_spread = value
		queue_redraw()

# === КОЛИЧЕСТВО КАПЕЛЬ ЗА АТАКУ ===
@export var min_drops_per_attack: int = 2:          # Минимальное количество капель
	set(value):
		min_drops_per_attack = value
		queue_redraw()

@export var max_drops_per_attack: int = 4:          # Максимальное количество капель
	set(value):
		max_drops_per_attack = value
		queue_redraw()


# ============================================
# НАСТРОЙКА
# ============================================

func _ready() -> void:
	_attack_pattern = "spread"
	super._ready()


# ============================================
# ВИЗУАЛИЗАЦИЯ В РЕДАКТОРЕ (БАЗОВАЯ)
# ============================================

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	
	# Точка спавна по умолчанию (в локальных координатах)
	var spawn_pos = _get_spawn_position() - global_position
	
	# Рисуем точку спавна
	draw_circle(spawn_pos, 5, Color.RED)

	
	# Вызываем дочернюю визуализацию
	_draw_editor_visualization()


# ============================================
# ВИРТУАЛЬНЫЙ МЕТОД ДЛЯ ДОЧЕРНЕЙ ВИЗУАЛИЗАЦИИ
# ============================================

func _draw_editor_visualization() -> void:
	"""
	Переопределите в дочерних классах для добавления специфичной визуализации.
	"""
	pass


# ============================================
# АТАКА
# ============================================

func _execute_attack() -> void:
	"""
	Подбрасывает случайное количество снарядов вверх.
	"""
	if not is_player_valid() or not projectile_scene:
		return
	
	var spawn_pos = _get_spawn_position()
	var drops_count = _get_random_drops_count()
	
	for i in range(drops_count):
		var throw_velocity = _get_random_throw_velocity()
		_create_projectile(throw_velocity, spawn_pos)
	
	AudioManager.play_sfx(shot_sound, 0.2, 1, global_position)

func _get_random_drops_count() -> int:
	"""
	Генерирует случайное количество капель для атаки.
	"""
	var random = RandomNumberGenerator.new()
	random.randomize()
	return random.randi_range(min_drops_per_attack, max_drops_per_attack)


func _get_random_throw_velocity() -> Vector2:
	"""
	Генерирует случайную скорость для подброса снаряда.
	"""
	var random = RandomNumberGenerator.new()
	random.randomize()
	
	var vertical = -random.randf_range(min_throw_force, max_throw_force)
	var horizontal = random.randf_range(-horizontal_spread, horizontal_spread)
	
	return Vector2(horizontal, vertical)


func _get_spawn_position() -> Vector2:
	"""
	Возвращает позицию спавна снаряда.
	"""
	return global_position


func _create_projectile(velocity: Vector2, spawn_position: Vector2) -> void:
	"""
	Создаёт и настраивает снаряд.
	"""
	var projectile = projectile_scene.instantiate()
	get_tree().root.add_child(projectile)
	
	projectile.global_position = spawn_position
	
	if projectile.has_method("set_velocity"):
		projectile.set_velocity(velocity)
	if projectile.has_method("set_gravity"):
		projectile.set_gravity(projectile_gravity)
	if projectile.has_method("set_explosion_force"):
		projectile.set_explosion_force(explosion_force)
	if projectile.has_method("set_shooter"):
		projectile.set_shooter(self)


# ============================================
# ФИЗИКА
# ============================================

func _physics_process(delta: float) -> void:
	if _is_exploding:
		return
	
	if is_player_valid():
		_face_player()
	
	move_and_slide()
