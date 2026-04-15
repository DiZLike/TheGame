extends BasePlatform
class_name MovingPlatform

# === ПАРАМЕТРЫ ДВИЖЕНИЯ ===
@export var max_speed: float = 75.0
@export var use_sine_speed: bool = true
@export var min_speed_multiplier: float = 0.3
@export var easing_curve: Curve

# === СОСТОЯНИЯ ===
var current_speed: float = 0.0
var path_progress: float = 0.0  # 0.0 - 1.0

func _setup_platform() -> void:
	_calculate_path_parameters()

# Виртуальные методы для наследников
func _calculate_path_parameters() -> void:
	pass

func _get_direction_to_target() -> Vector2:
	return Vector2.ZERO

func _get_distance_to_target() -> float:
	return 0.0

func _update_progress(delta: float) -> void:
	pass

func _get_speed_multiplier() -> float:
	if not use_sine_speed:
		return 1.0
	
	# Синусоидальная скорость: быстрее по краям, медленнее в центре
	var multiplier = abs(sin(path_progress * PI))
	return min_speed_multiplier + (1.0 - min_speed_multiplier) * multiplier

func _apply_easing_curve(value: float) -> float:
	if easing_curve:
		return easing_curve.sample(value)
	return value

func _physics_process(delta: float) -> void:
	if not is_active or is_disabled:
		return
	
	_update_progress(delta)
	
	var speed_multiplier = _get_speed_multiplier()
	current_speed = max_speed * speed_multiplier
	
	var direction = _get_direction_to_target()
	var distance_to_target = _get_distance_to_target()
	var move_distance = current_speed * delta
	
	if move_distance >= distance_to_target and distance_to_target > 0:
		# Достигли цели - телепортируемся и разворачиваемся
		global_position += direction * distance_to_target
		_reach_target()
		velocity = Vector2.ZERO
	else:
		velocity = direction * current_speed
		move_and_slide()

func _reach_target() -> void:
	# Переопределяется в наследниках
	pass
