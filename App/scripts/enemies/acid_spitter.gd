@tool
extends SpitterEnemy
class_name AcidSpitter

# ============================================
# ВРАГ - ПЛЕВАТЕЛЬ КИСЛОТОЙ
# ============================================
# Подбрасывает случайное количество капель кислоты вверх.
# Капли летят по дуге и взрываются при касании с землёй.
# Атака работает всегда, независимо от нахождения на экране
# ============================================

# === НАСТРОЙКИ ТОЧКИ СПАВНА ===
@export var spawn_offset: Vector2 = Vector2(0, -15):
	set(value):
		spawn_offset = value
		queue_redraw()
# === НАСТРОЙКИ СИНХРОНИЗАЦИИ ===
@export var start_delay: float = 0.0             # Задержка перед первой атакой (для синхронизации)

# === СОСТОЯНИЯ ===
var _started: bool = false                       # Был ли запущен цикл атак


# ============================================
# НАСТРОЙКА
# ============================================

func _ready() -> void:
	shot_sound = preload("res://data/audio/sounds/enemy/acid.wav")
	super._ready()
	
	# Не запускаем атаки в редакторе
	if Engine.is_editor_hint():
		return
	
	if animated_sprite and animated_sprite.sprite_frames.has_animation("idle"):
		animated_sprite.play("idle")
	
	_initialize_always_active()


# ============================================
# ЗАПУСК АТАКИ (ВСЕГДА, С ЗАДЕРЖКОЙ)
# ============================================

func _initialize_always_active() -> void:
	"""
	Запускает атаку всегда, независимо от экрана.
	Использует start_delay для синхронизации нескольких плевателей.
	"""
	if _started or Engine.is_editor_hint():
		return
	
	_started = true
	_is_active = true
	
	# Ждём задержку перед запуском
	if start_delay > 0:
		await get_tree().create_timer(start_delay).timeout
	
	# Запускаем атаку, если ещё не умираем
	if not _is_exploding:
		_start_attacking()


# ============================================
# ПЕРЕОПРЕДЕЛЯЕМ АКТИВАЦИЮ (НЕ ОСТАНАВЛИВАЕМ АТАКУ)
# ============================================

func _on_activate() -> void:
	"""
	Вызывается когда враг появляется на экране.
	Не влияет на атаку — она уже работает.
	"""
	_is_active = true
	if animated_sprite and not _is_exploding:
		animated_sprite.visible = true

func _on_deactivate() -> void:
	"""
	Вызывается когда враг покидает экран.
	Атака продолжается, но можно скрыть визуал для оптимизации.
	"""
	_is_active = false
	# Опционально: скрываем спрайт для экономии
	# if animated_sprite:
	# 	animated_sprite.visible = false


# ============================================
# ВИЗУАЛИЗАЦИЯ В РЕДАКТОРЕ (РАСШИРЕННАЯ)
# ============================================

func _draw_editor_visualization() -> void:
	"""
	Переопределяем метод базового класса для специфичной визуализации кислотного плевателя.
	"""
	if not Engine.is_editor_hint():
		return
	
	var spawn_pos = spawn_offset
	
	# Рисуем точку спавна (поверх базовой)
	draw_circle(spawn_pos, 4, Color.ORANGE)
	
	# Вертикальные линии границ горизонтального разброса
	var left_bound = spawn_pos + Vector2(-horizontal_spread, 0)
	var right_bound = spawn_pos + Vector2(horizontal_spread, 0)
	
	# Линии вверх от границ (показывают зону разброса)
	draw_line(left_bound, left_bound + Vector2(0, -40), Color(1, 0.5, 0, 0.3), 1)
	draw_line(right_bound, right_bound + Vector2(0, -40), Color(1, 0.5, 0, 0.3), 1)
	
	# Горизонтальная линия между границами разброса
	draw_line(left_bound + Vector2(0, -40), right_bound + Vector2(0, -40), Color(1, 0.5, 0, 0.2), 1)
	
	# Траектория для минимальной силы броска
	_draw_trajectory(spawn_pos, 0, min_throw_force, Color(1, 0.8, 0, 0.4))
	
	# Траектория для максимальной силы броска
	_draw_trajectory(spawn_pos, 0, max_throw_force, Color(1, 0.5, 0, 0.4))
	
	# Траектории с максимальным боковым отклонением
	_draw_trajectory(spawn_pos, horizontal_spread, max_throw_force, Color(1, 0.5, 0, 0.2))
	_draw_trajectory(spawn_pos, -horizontal_spread, max_throw_force, Color(1, 0.5, 0, 0.2))


func _draw_trajectory(start_pos: Vector2, horizontal_offset: float, initial_speed: float, color: Color) -> void:
	"""
	Рисует траекторию снаряда с учётом гравитации
	"""
	var points = []
	var steps = 20
	var time_step = 0.05
	var gravity = projectile_gravity
	
	var start_x = start_pos.x + horizontal_offset
	
	for i in range(steps + 1):
		var t = i * time_step
		var x = start_x
		var y = start_pos.y - initial_speed * t + 0.5 * gravity * t * t
		points.append(Vector2(x, y))
		
		# Останавливаемся, если снаряд начал падать ниже точки спавна
		if y > start_pos.y:
			break
	
	for i in range(points.size() - 1):
		draw_line(points[i], points[i + 1], color, 1)


# ============================================
# СПАВН
# ============================================

func _get_spawn_position() -> Vector2:
	return global_position + spawn_offset
