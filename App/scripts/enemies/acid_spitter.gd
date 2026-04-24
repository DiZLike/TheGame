@tool
extends SpitterEnemy
class_name AcidSpitter

# ============================================
# ВРАГ - ПЛЕВАТЕЛЬ КИСЛОТОЙ
# ============================================
# Подбрасывает случайное количество капель кислоты вверх.
# Капли летят по дуге и взрываются при касании с землёй.
# ============================================

# === НАСТРОЙКИ ТОЧКИ СПАВНА ===
@export var spawn_offset: Vector2 = Vector2(0, -15):
	set(value):
		spawn_offset = value
		queue_redraw()


# ============================================
# НАСТРОЙКА
# ============================================

func _ready() -> void:
	if not projectile_scene:
		projectile_scene = preload("res://scenes/bullets/enemy/acid_drop.tscn")
	
	super._ready()
	
	if animated_sprite and animated_sprite.sprite_frames.has_animation("idle"):
		animated_sprite.play("idle")


# ============================================
# ВИЗУАЛИЗАЦИЯ В РЕДАКТОРЕ (РАСШИРЕННАЯ)
# ============================================

func _draw_editor_visualization() -> void:
	"""
	Переопределяем метод базового класса для специфичной визуализации кислотного плевателя.
	"""
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


# ============================================
# АНИМАЦИИ
# ============================================

func _face_player() -> void:
	if not animated_sprite or not is_player_valid():
		return
	
	var direction_to_player = _player.global_position.x - global_position.x
	animated_sprite.flip_h = direction_to_player > 0
