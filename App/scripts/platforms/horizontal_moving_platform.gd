extends MovingPlatform
class_name HorizontalMovingPlatform

enum StartDirection { LEFT, RIGHT }

@export var start_direction: StartDirection = StartDirection.RIGHT

@onready var left_limit: Node2D = $LeftLimit
@onready var right_limit: Node2D = $RightLimit

var moving_to_right: bool
var left_pos: Vector2
var right_pos: Vector2
var path_length: float

func _calculate_path_parameters() -> void:
	left_pos = left_limit.global_position
	right_pos = right_limit.global_position
	path_length = left_pos.distance_to(right_pos)
	moving_to_right = start_direction == StartDirection.RIGHT
	
	# Вычисляем начальный прогресс
	if path_length > 0:
		var start_pos = left_pos if moving_to_right else right_pos
		path_progress = clamp(start_pos.distance_to(global_position) / path_length, 0.0, 1.0)
		if not moving_to_right:
			path_progress = 1.0 - path_progress

func _get_direction_to_target() -> Vector2:
	var end_pos = right_pos if moving_to_right else left_pos
	return (end_pos - global_position).normalized()

func _get_distance_to_target() -> float:
	var end_pos = right_pos if moving_to_right else left_pos
	return global_position.distance_to(end_pos)

func _update_progress(delta: float) -> void:
	var step = current_speed * delta / path_length
	path_progress += step if moving_to_right else -step
	path_progress = clamp(path_progress, 0.0, 1.0)

func _reach_target() -> void:
	moving_to_right = !moving_to_right
	path_progress = 0.0 if moving_to_right else 1.0
