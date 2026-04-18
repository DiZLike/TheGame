@tool
extends MovingPlatform
class_name HorizontalMovingPlatform

enum StartDirection { LEFT, RIGHT }

@export var start_direction: StartDirection = StartDirection.RIGHT:
	set(value):
		start_direction = value
		if not Engine.is_editor_hint():
			_calculate_path_parameters()
		queue_redraw()

@export var left_limit: float = -100.0:
	set(value):
		left_limit = value
		if Engine.is_editor_hint():
			queue_redraw()
		else:
			_calculate_path_parameters()

@export var right_limit: float = 100.0:
	set(value):
		right_limit = value
		if Engine.is_editor_hint():
			queue_redraw()
		else:
			_calculate_path_parameters()

var moving_to_right: bool
var path_length: float
var left_limit_global: float
var right_limit_global: float

func _draw() -> void:
	if Engine.is_editor_hint():
		# Рисуем вертикальные линии на границах (в локальных координатах)
		draw_line(
			Vector2(left_limit, -50), 
			Vector2(left_limit, 50), 
			Color.RED, 
			2
		)
		draw_line(
			Vector2(right_limit, -50), 
			Vector2(right_limit, 50), 
			Color.GREEN, 
			2
		)
		
		# Рисуем линию пути
		draw_line(
			Vector2(left_limit, 0), 
			Vector2(right_limit, 0), 
			Color.YELLOW, 
			1
		)

func _calculate_path_parameters() -> void:
	# В редакторе не вычисляем параметры движения
	if Engine.is_editor_hint():
		return
	
	# Конвертируем локальные лимиты в глобальные координаты
	left_limit_global = to_global(Vector2(left_limit, 0)).x
	right_limit_global = to_global(Vector2(right_limit, 0)).x
	
	path_length = abs(right_limit_global - left_limit_global)
	moving_to_right = start_direction == StartDirection.RIGHT
	
	# Вычисляем начальный прогресс на основе глобальной позиции
	if path_length > 0:
		var current_global_x = global_position.x
		path_progress = (current_global_x - left_limit_global) / path_length
		path_progress = clamp(path_progress, 0.0, 1.0)
		
		if not moving_to_right:
			path_progress = 1.0 - path_progress

func _get_direction_to_target() -> Vector2:
	var target_x = right_limit_global if moving_to_right else left_limit_global
	var direction = Vector2(target_x - global_position.x, 0)
	return direction.normalized() if direction.length() > 0 else Vector2.ZERO

func _get_distance_to_target() -> float:
	var target_x = right_limit_global if moving_to_right else left_limit_global
	return abs(target_x - global_position.x)

func _update_progress(delta: float) -> void:
	var step = current_speed * delta / path_length
	path_progress += step if moving_to_right else -step
	path_progress = clamp(path_progress, 0.0, 1.0)

func _reach_target() -> void:
	moving_to_right = !moving_to_right
