extends MovingPlatform
class_name VerticalMovingPlatform

enum StartDirection { UP, DOWN }

@export var start_direction: StartDirection = StartDirection.DOWN

@onready var top_limit: Node2D = $TopLimit
@onready var bottom_limit: Node2D = $BottomLimit

var moving_down: bool
var top_pos: Vector2
var bottom_pos: Vector2
var path_length: float

func _calculate_path_parameters() -> void:
	top_pos = top_limit.global_position
	bottom_pos = bottom_limit.global_position
	path_length = top_pos.distance_to(bottom_pos)
	moving_down = start_direction == StartDirection.DOWN
	
	if path_length > 0:
		var start_pos = top_pos if moving_down else bottom_pos
		path_progress = clamp(start_pos.distance_to(global_position) / path_length, 0.0, 1.0)
		if not moving_down:
			path_progress = 1.0 - path_progress

func _get_direction_to_target() -> Vector2:
	var end_pos = bottom_pos if moving_down else top_pos
	return (end_pos - global_position).normalized()

func _get_distance_to_target() -> float:
	var end_pos = bottom_pos if moving_down else top_pos
	return global_position.distance_to(end_pos)

func _update_progress(delta: float) -> void:
	var step = current_speed * delta / path_length
	path_progress += step if moving_down else -step
	path_progress = clamp(path_progress, 0.0, 1.0)

func _reach_target() -> void:
	moving_down = !moving_down
	path_progress = 0.0 if moving_down else 1.0
