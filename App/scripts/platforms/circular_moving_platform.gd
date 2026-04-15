extends MovingPlatform
class_name CircularMovingPlatform

enum StartDirection { CLOCKWISE, COUNTER_CLOCKWISE }

@export var start_direction: StartDirection = StartDirection.CLOCKWISE

@onready var top_limit: Node2D = $TopLimit
@onready var bottom_limit: Node2D = $BottomLimit
@onready var left_limit: Node2D = $LeftLimit
@onready var right_limit: Node2D = $RightLimit

var center_position: Vector2
var radius_x: float
var radius_y: float
var current_angle: float
var clockwise: bool

func _calculate_path_parameters() -> void:
	calculate_ellipse_from_limits()
	
	var relative_pos = global_position - center_position
	current_angle = atan2(
		relative_pos.y / max(radius_y, 0.001),
		relative_pos.x / max(radius_x, 0.001)
	)
	
	clockwise = start_direction == StartDirection.CLOCKWISE
	
	# Вычисляем прогресс (0-1) для синусоидальной скорости
	path_progress = fmod(current_angle, TAU) / TAU

func calculate_ellipse_from_limits() -> void:
	var top_pos = top_limit.global_position
	var bottom_pos = bottom_limit.global_position
	var left_pos = left_limit.global_position
	var right_pos = right_limit.global_position
	
	center_position = Vector2(
		(left_pos.x + right_pos.x) / 2.0,
		(top_pos.y + bottom_pos.y) / 2.0
	)
	
	radius_x = abs(right_pos.x - left_pos.x) / 2.0
	radius_y = abs(bottom_pos.y - top_pos.y) / 2.0

func _get_direction_to_target() -> Vector2:
	var target_position = _get_target_position()
	return (target_position - global_position).normalized()

func _get_distance_to_target() -> float:
	var target_position = _get_target_position()
	return global_position.distance_to(target_position)

func _get_target_position() -> Vector2:
	return center_position + Vector2(
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
