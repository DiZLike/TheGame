@tool
extends MovingPlatform
class_name CircularMovingPlatform

enum StartDirection { CLOCKWISE, COUNTER_CLOCKWISE }

@export var start_direction: StartDirection = StartDirection.CLOCKWISE:
	set(value):
		start_direction = value
		if not Engine.is_editor_hint():
			_calculate_path_parameters()
		queue_redraw()

@export var center_offset: Vector2 = Vector2.ZERO:
	set(value):
		center_offset = value
		if Engine.is_editor_hint():
			queue_redraw()
		else:
			_calculate_path_parameters()

@export_range(0, 200) var radius_x: float = 100.0:
	set(value):
		radius_x = value
		if Engine.is_editor_hint():
			queue_redraw()
		else:
			_calculate_path_parameters()

@export_range(0, 200) var radius_y: float = 100.0:
	set(value):
		radius_y = value
		if Engine.is_editor_hint():
			queue_redraw()
		else:
			_calculate_path_parameters()

var center_position_global: Vector2
var current_angle: float
var clockwise: bool

func _draw() -> void:
	if Engine.is_editor_hint():
		# Рисуем эллипс пути (в локальных координатах)
		var points = PackedVector2Array()
		var segments = 64
		
		for i in range(segments + 1):
			var angle = TAU * i / segments
			var point = center_offset + Vector2(cos(angle) * radius_x, sin(angle) * radius_y)
			points.append(point)
		
		# Рисуем контур эллипса
		for i in range(segments):
			draw_line(points[i], points[i + 1], Color.YELLOW, 1)
		
		# Рисуем крестик в центре (в локальных координатах)
		draw_line(center_offset + Vector2(-10, 0), center_offset + Vector2(10, 0), Color.RED, 2)
		draw_line(center_offset + Vector2(0, -10), center_offset + Vector2(0, 10), Color.RED, 2)

func _calculate_path_parameters() -> void:
	# В редакторе не вычисляем параметры движения
	if Engine.is_editor_hint():
		return
	
	# Конвертируем локальный центр в глобальные координаты
	center_position_global = to_global(center_offset)
	
	var relative_pos = global_position - center_position_global
	current_angle = atan2(
		relative_pos.y / max(radius_y, 0.001),
		relative_pos.x / max(radius_x, 0.001)
	)
	
	clockwise = start_direction == StartDirection.CLOCKWISE
	
	# Вычисляем прогресс (0-1) для синусоидальной скорости
	path_progress = fmod(current_angle, TAU) / TAU

func _get_direction_to_target() -> Vector2:
	var target_position = _get_target_position()
	var direction = target_position - global_position
	return direction.normalized() if direction.length() > 0 else Vector2.ZERO

func _get_distance_to_target() -> float:
	var target_position = _get_target_position()
	return global_position.distance_to(target_position)

func _get_target_position() -> Vector2:
	return center_position_global + Vector2(
		cos(current_angle) * radius_x,
		sin(current_angle) * radius_y
	)

func _update_progress(delta: float) -> void:
	var avg_radius = (radius_x + radius_y) / 2.0
	var angular_speed = current_speed / avg_radius
	var angle_delta = angular_speed * delta
	
	if not clockwise:
		angle_delta = -angle_delta
	
	current_angle += angle_delta
	current_angle = fmod(current_angle, TAU)
	
	path_progress = fmod(current_angle, TAU) / TAU

func _reach_target() -> void:
	# Для кругового движения не требуется разворот
	pass
