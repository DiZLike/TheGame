extends DirectionalStaticEnemy
class_name Trident

# ============================================
# ВРАГ С ТРЕМЯ НАПРАВЛЕНИЯМИ СТРЕЛЬБЫ
# ============================================
# Стреляет прямо, вверх-диагональ и вниз-диагональ
# Выбирает направление в зависимости от позиции игрока
# Использует анимации: "line", "up", "down"
# ============================================

# === НАСТРОЙКИ УГЛОВ ===
@export var up_angle_threshold: float = 30.0      # Угол для верхнего выстрела (игрок ВЫШЕ)
@export var down_angle_threshold: float = 30.0    # Угол для нижнего выстрела (игрок НИЖЕ)

# === КОМПОНЕНТЫ ===
@onready var shooting_point_line: Marker2D = $ShootingPoints/ShootingPointLine
@onready var shooting_point_up: Marker2D = $ShootingPoints/ShootingPointUp
@onready var shooting_point_down: Marker2D = $ShootingPoints/ShootingPointDown


# ============================================
# НАСТРОЙКА
# ============================================

func _ready() -> void:
	# Устанавливаем параметры ДО вызова родительского _ready()
	_attack_pattern = "single"
	
	# Пороги углов для выбора направления (оба положительные)
	up_angle_threshold = 30.0
	down_angle_threshold = 30.0
	
	super._ready()


# ============================================
# ПЕРЕОПРЕДЕЛЕНИЕ МЕТОДОВ DirectionalStaticEnemy
# ============================================

func _setup_shooting_points() -> void:
	"""
	Находит и сохраняет точки спавна пуль.
	"""
	shooting_points = [
		shooting_point_line,
		shooting_point_up,
		shooting_point_down
	]

func _get_shoot_directions() -> Array[Vector2]:
	"""
	Возвращает три направления: прямо, вверх-диагональ, вниз-диагональ.
	Все направления заданы для спрайта смотрящего ВЛЕВО.
	При flip_h = true (смотрит вправо) X инвертируется автоматически.
	"""
	return [
		Vector2.LEFT,                                   # Прямо
		Vector2(-1, -1).normalized(),                   # Вверх-влево
		Vector2(-1, 1).normalized()                     # Вниз-влево
	]

func _get_animation_for_direction(direction_index: int) -> String:
	"""
	Возвращает имя анимации в зависимости от направления.
	"""
	match direction_index:
		0: return "line"
		1: return "up"
		2: return "down"
		_: return "line"

func _choose_direction_index() -> int:
	"""
	Выбирает направление выстрела в зависимости от позиции игрока.
	"""
	if not is_player_valid():
		return 0  # По умолчанию прямо
	
	# Направление к игроку
	var to_player = _player.global_position - global_position
	
	# Проверяем, с какой стороны игрок относительно врага
	var player_is_on_right = to_player.x > 0
	var is_facing_right = animated_sprite and animated_sprite.flip_h
	
	# Если игрок за спиной - не атакуем
	if (is_facing_right and not player_is_on_right) or (not is_facing_right and player_is_on_right):
		return 0
	
	# Вычисляем вертикальное смещение
	var vertical_diff = to_player.y  # Отрицательное = игрок ВЫШЕ, положительное = игрок НИЖЕ
	var horizontal_diff = abs(to_player.x)
	
	# Вычисляем абсолютный угол (всегда положительный)
	var abs_angle = abs(rad_to_deg(atan2(vertical_diff, horizontal_diff)))
	
	# Определяем, игрок выше или ниже
	var player_is_above = vertical_diff < 0  # В Godot Y растет вниз, поэтому отрицательный Y = выше
	
	# Выбираем направление
	if player_is_above and abs_angle >= up_angle_threshold:
		return 1  # UP - игрок значительно выше
	elif not player_is_above and abs_angle >= down_angle_threshold:
		return 2  # DOWN - игрок значительно ниже
	else:
		return 0  # LINE - игрок примерно на одном уровне

func _update_shooting_points_positions() -> void:
	"""
	Обновляет позиции точек спавна при отзеркаливании спрайта.
	Зеркалим X координату для всех точек.
	"""
	if not animated_sprite:
		return
	
	var is_flipped = animated_sprite.flip_h
	
	# Для каждой точки инвертируем X если спрайт отзеркален
	for point in shooting_points:
		if point:
			var pos = point.position
			if is_flipped:
				point.position.x = abs(pos.x)  # Делаем положительным X
			else:
				point.position.x = -abs(pos.x)  # Делаем отрицательным X
