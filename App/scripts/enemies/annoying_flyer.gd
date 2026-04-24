# annoying_flyer.gd
extends BaseEnemy
class_name AnnoyingFlyer

# ============================================
# НАДОЕДАЮЩИЙ ЛЕТАЮЩИЙ ВРАГ
# ============================================
# Следует за игроком, хаотично перемещается рядом.
# Специально избегает прямого контакта с игроком.
# Не атакует, просто мешает и отвлекает.
# ============================================

# === НАСТРОЙКИ ДВИЖЕНИЯ ===
@export var follow_speed: float = 150.0           # Скорость следования за игроком
@export var wander_speed: float = 200.0           # Скорость хаотичного движения
@export var min_distance: float = 80.0            # Минимальная дистанция до игрока
@export var max_distance: float = 200.0           # Максимальная дистанция до игрока
@export var preferred_distance: float = 120.0     # Предпочтительная дистанция

# === НАСТРОЙКИ ХАОТИЧНОГО ДВИЖЕНИЯ ===
@export var wander_strength: float = 100.0        # Сила случайного блуждания
@export var wander_change_interval: float = 0.5   # Интервал смены направления блуждания
@export var avoidance_strength: float = 300.0     # Сила избегания игрока

# === НАСТРОЙКИ ЗОНЫ ===
@export var vertical_offset_range: Vector2 = Vector2(-80, 80)  # Диапазон смещения по Y
@export var horizontal_offset_range: Vector2 = Vector2(-100, 100)  # Диапазон смещения по X

# === КОМПОНЕНТЫ ===
@onready var detection_area: Area2D = $DetectionArea
@onready var avoidance_area: Area2D = $AvoidanceArea

# === ВНУТРЕННИЕ ПЕРЕМЕННЫЕ ===
var _current_wander_direction: Vector2 = Vector2.RIGHT
var _wander_timer: float = 0.0
var _target_offset: Vector2 = Vector2.ZERO
var _offset_change_timer: float = 0.0
var _offset_change_interval: float = 2.0
var _velocity: Vector2 = Vector2.ZERO
var _is_initialized: bool = false

# === ЗВУКИ ===
var buzz_sound: AudioStream = null  # Жужжание (можно добавить позже)
var _buzz_timer: float = 0.0
var _buzz_interval: float = 3.0


# ============================================
# НАСТРОЙКА
# ============================================

func _ready() -> void:
	# Устанавливаем параметры ДО вызова родительского _ready()
	_attack_pattern = "none"
	_movement_type = "fly"
	explosion_force = 30.0
	
	super._ready()
	
	# Настройка зон обнаружения
	_setup_areas()
	
	# Запускаем idle анимацию если есть
	if animated_sprite and animated_sprite.sprite_frames.has_animation("idle"):
		animated_sprite.play("idle")
	
	_is_initialized = true
	
	# Генерируем начальную цель смещения
	_generate_new_offset()


func _setup_areas() -> void:
	"""
	Настройка областей обнаружения и избегания.
	"""
	# Создаем область избегания если её нет
	if not avoidance_area:
		avoidance_area = Area2D.new()
		avoidance_area.name = "AvoidanceArea"
		add_child(avoidance_area)
		
		var avoid_shape = CollisionShape2D.new()
		var circle = CircleShape2D.new()
		circle.radius = min_distance
		avoid_shape.shape = circle
		avoidance_area.add_child(avoid_shape)


# ============================================
# ФИЗИКА И ДВИЖЕНИЕ
# ============================================

func _physics_process(delta: float) -> void:
	if _is_exploding or not _is_active:
		return
	
	if not is_player_valid():
		# Если игрок потерян, просто дрейфуем
		_apply_drift(delta)
	else:
		# Основное поведение: следование за игроком с хаотичным блужданием
		_update_movement(delta)
	
	# Применяем движение
	global_position += _velocity * delta
	
	# Обновляем визуальные эффекты
	_update_visuals(delta)
	
	# Обновляем звук жужжания
	_update_buzz_sound(delta)


func _update_movement(delta: float) -> void:
	"""
	Основная логика движения: следование + хаотичное блуждание.
	"""
	var target_velocity = Vector2.ZERO
	
	# 1. Движение к целевой позиции (игрок + смещение)
	var target_position = _player.global_position + _target_offset
	var to_target = target_position - global_position
	var distance_to_target = to_target.length()
	
	if distance_to_target > 10:
		# Нормализуем и применяем скорость следования
		var follow_velocity = to_target.normalized() * follow_speed
		target_velocity += follow_velocity
	
	# 2. Избегание слишком близкого контакта с игроком
	var to_player = _player.global_position - global_position
	var distance_to_player = to_player.length()
	
	if distance_to_player < min_distance:
		# Отталкиваемся от игрока, если слишком близко
		var avoid_velocity = -to_player.normalized() * avoidance_strength * (1 - distance_to_player / min_distance)
		target_velocity += avoid_velocity
	
	# 3. Хаотичное блуждание
	_update_wander(delta)
	target_velocity += _current_wander_direction * wander_strength
	
	# 4. Обновляем целевое смещение с течением времени
	_update_target_offset(delta)
	
	# 5. Плавно интерполируем к целевой скорости
	_velocity = _velocity.lerp(target_velocity, 0.1)
	
	# 6. Ограничиваем максимальную скорость
	var current_speed = _velocity.length()
	if current_speed > wander_speed:
		_velocity = _velocity.normalized() * wander_speed


func _update_wander(delta: float) -> void:
	"""
	Обновляет направление хаотичного блуждания.
	"""
	_wander_timer += delta
	
	if _wander_timer >= wander_change_interval:
		_wander_timer = 0.0
		_generate_new_wander_direction()


func _generate_new_wander_direction() -> void:
	"""
	Генерирует новое случайное направление для блуждания.
	"""
	var random = RandomNumberGenerator.new()
	random.randomize()
	
	# Случайное направление с большей вероятностью горизонтального движения
	var angle = random.randf_range(0, TAU)
	
	# Добавляем небольшое предпочтение к позиции рядом с игроком
	_current_wander_direction = Vector2(cos(angle), sin(angle))
	
	# Если игрок существует, добавляем компоненту к игроку
	if is_player_valid():
		var to_player = (_player.global_position - global_position).normalized()
		_current_wander_direction = (_current_wander_direction + to_player * 0.3).normalized()


func _update_target_offset(delta: float) -> void:
	"""
	Обновляет смещение относительно игрока.
	"""
	_offset_change_timer += delta
	
	if _offset_change_timer >= _offset_change_interval:
		_offset_change_timer = 0.0
		_generate_new_offset()


func _generate_new_offset() -> void:
	"""
	Генерирует новое случайное смещение относительно игрока.
	"""
	var random = RandomNumberGenerator.new()
	random.randomize()
	
	var offset_x = random.randf_range(horizontal_offset_range.x, horizontal_offset_range.y)
	var offset_y = random.randf_range(vertical_offset_range.x, vertical_offset_range.y)
	
	# Корректируем дистанцию до предпочтительной
	var offset = Vector2(offset_x, offset_y)
	var current_distance = offset.length()
	
	if current_distance > 0:
		offset = offset.normalized() * random.randf_range(min_distance, max_distance)
	
	_target_offset = offset


func _apply_drift(delta: float) -> void:
	"""
	Простое дрейфующее движение когда игрок не найден.
	"""
	_update_wander(delta)
	_velocity = _velocity.lerp(_current_wander_direction * wander_speed * 0.5, 0.05)


# ============================================
# ВИЗУАЛЬНЫЕ ЭФФЕКТЫ
# ============================================

func _update_visuals(delta: float) -> void:
	"""
	Обновляет спрайт и анимацию.
	"""
	if not animated_sprite:
		return
	
	# Поворачиваем спрайт в направлении движения
	if _velocity.length() > 10:
		animated_sprite.flip_h = _velocity.x > 0
	
	# Анимация полета
	if animated_sprite.sprite_frames.has_animation("fly"):
		if animated_sprite.animation != "fly":
			animated_sprite.play("fly")
	
	# Легкое покачивание для эффекта "надоедливости"
	var bob_offset = sin(Time.get_ticks_msec() * 0.005) * 3
	var sway_offset = cos(Time.get_ticks_msec() * 0.003) * 2
	
	if animated_sprite:
		animated_sprite.offset = Vector2(sway_offset, bob_offset)
	
	# Мерцание когда очень близко к игроку (предупреждение)
	if is_player_valid():
		var distance = global_position.distance_to(_player.global_position)
		if distance < min_distance * 1.5:
			animated_sprite.modulate.a = 0.7 + sin(Time.get_ticks_msec() * 0.02) * 0.3


# ============================================
# ЗВУКИ
# ============================================

func _update_buzz_sound(delta: float) -> void:
	"""
	Обновляет звук жужжания (если настроен).
	"""
	if not buzz_sound:
		return
	
	_buzz_timer += delta
	if _buzz_timer >= _buzz_interval:
		_buzz_timer = 0.0
		AudioManager.play_sfx(buzz_sound, 1, 1, global_position)


# ============================================
# УПРАВЛЕНИЕ АКТИВАЦИЕЙ
# ============================================

func _on_activate() -> void:
	"""
	Вызывается когда враг появляется на экране.
	"""
	super._on_activate()
	_generate_new_offset()
	_generate_new_wander_direction()


func _on_deactivate() -> void:
	"""
	Вызывается когда враг покидает экран.
	"""
	super._on_deactivate()
	_velocity = Vector2.ZERO


# ============================================
# ПЕРЕОПРЕДЕЛЕНИЕ МЕТОДОВ
# ============================================

func is_player_valid() -> bool:
	"""
	Расширенная проверка существования игрока.
	"""
	return super.is_player_valid() and _player != null

func _face_player() -> void:
	"""
	Смотрит в сторону игрока.
	"""
	if not animated_sprite or not is_player_valid():
		return
	
	var direction_to_player = (_player.global_position.x - global_position.x)
	animated_sprite.flip_h = direction_to_player > 0


func _before_explode() -> void:
	"""
	Подготовка к взрыву.
	"""
	_velocity = Vector2.ZERO
	super._before_explode()
