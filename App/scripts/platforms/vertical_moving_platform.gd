@tool
extends MovingPlatform
class_name VerticalMovingPlatform

enum StartDirection { UP, DOWN }

@export var start_direction: StartDirection = StartDirection.DOWN:
	set(value):
		start_direction = value
		if not Engine.is_editor_hint():
			_calculate_path_parameters()
		queue_redraw()

@export var top_limit: float = -100.0:
	set(value):
		top_limit = value
		if Engine.is_editor_hint():
			queue_redraw()
		else:
			_calculate_path_parameters()

@export var bottom_limit: float = 100.0:
	set(value):
		bottom_limit = value
		if Engine.is_editor_hint():
			queue_redraw()
		else:
			_calculate_path_parameters()

var moving_down: bool
var path_length: float
var top_limit_global: float
var bottom_limit_global: float

func _draw() -> void:
	if Engine.is_editor_hint():
		# Рисуем горизонтальные линии на границах (в локальных координатах)
		draw_line(
			Vector2(-50, top_limit), 
			Vector2(50, top_limit), 
			Color.RED, 
			2
		)
		draw_line(
			Vector2(-50, bottom_limit), 
			Vector2(50, bottom_limit), 
			Color.GREEN, 
			2
		)
		
		# Рисуем линию пути
		draw_line(
			Vector2(0, top_limit), 
			Vector2(0, bottom_limit), 
			Color.YELLOW, 
			1
		)

func _calculate_path_parameters() -> void:
	# В редакторе не вычисляем параметры движения
	if Engine.is_editor_hint():
		return
	
	# Конвертируем локальные лимиты в глобальные координаты
	top_limit_global = to_global(Vector2(0, top_limit)).y
	bottom_limit_global = to_global(Vector2(0, bottom_limit)).y
	
	path_length = abs(bottom_limit_global - top_limit_global)
	moving_down = start_direction == StartDirection.DOWN
	
	# Вычисляем начальный прогресс на основе глобальной позиции
	if path_length > 0:
		var current_global_y = global_position.y
		path_progress = (current_global_y - top_limit_global) / path_length
		path_progress = clamp(path_progress, 0.0, 1.0)
		
		if not moving_down:
			path_progress = 1.0 - path_progress

func _get_direction_to_target() -> Vector2:
	var target_y = bottom_limit_global if moving_down else top_limit_global
	var direction = Vector2(0, target_y - global_position.y)
	return direction.normalized() if direction.length() > 0 else Vector2.ZERO

func _get_distance_to_target() -> float:
	var target_y = bottom_limit_global if moving_down else top_limit_global
	return abs(target_y - global_position.y)

func _update_progress(delta: float) -> void:
	var step = current_speed * delta / path_length
	path_progress += step if moving_down else -step
	path_progress = clamp(path_progress, 0.0, 1.0)

func _reach_target() -> void:
	moving_down = !moving_down
