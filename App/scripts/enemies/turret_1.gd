extends StaticEnemy

# ============================================
# ТУРЕЛЬ - СТАТИЧНЫЙ ВРАГ
# ============================================

@export var rotation_speed: float = 1.0
@export var bullet_speed: float = 175.0
@export var aim_threshold_degrees: float = 10.0  # Допустимая погрешность в градусах

@onready var turret_node: Node2D = $Turret
@onready var shooting_point: Marker2D = $Turret/ShootingPoint

var bullet_scene: PackedScene = preload("res://scenes/bullets/enemy/enemy_bullet_default.tscn")

func _ready() -> void:
	# Устанавливаем спрайт ДО super._ready()
	animated_sprite = $Turret/TurretSprite

	# Устанавливаем параметры для расчёта score
	_attack_pattern = "burst"     # Серия из 2 выстрелов
	_movement_type = "rotate"     # Поворачивается, но стоит на месте

	super._ready()

	# Остальные параметры
	rotation_speed = 1.0
	bullet_speed = 175.0

func _physics_process(delta: float) -> void:
	if _is_exploding:
		return

	# Плавный поворот к игроку
	if is_player_valid() and turret_node:
		_rotate_towards_player(delta)

	move_and_slide()

func _rotate_towards_player(delta: float) -> void:
	if not turret_node or not is_player_valid():
		return

	# Направление от врага к игроку
	var direction_to_player = (_player.global_position - global_position).normalized()

	# Целевой угол с учетом того, что спрайт смотрит вверх
	var target_angle = direction_to_player.angle() + PI/2

	# Плавно интерполируем текущий угол к целевому
	turret_node.rotation = lerp_angle(turret_node.rotation, target_angle, rotation_speed * delta)

func _execute_attack() -> void:
	if not bullet_scene or not is_player_valid():
		return

	# Проверяем, направлена ли турель на игрока
	if not _is_aimed_at_player():
		return  # Не стреляем, если турель не нацелена

	var bullet = bullet_scene.instantiate()
	get_tree().root.add_child(bullet)

	# Позиция появления - используем ShootingPoint
	bullet.global_position = shooting_point.global_position if shooting_point else global_position

	# Направление к игроку
	var direction = (_player.global_position - global_position).normalized()
	AudioManager.play_sfx(shot_sound, 1, 1, global_position)
	
	# Устанавливаем параметры пули
	if bullet.has_method("set_shooter"):
		bullet.set_shooter(self)

	bullet.set("direction", direction)
	bullet.set("speed", bullet_speed)

func _is_aimed_at_player() -> bool:
	"""Проверяет, направлена ли турель на игрока с допустимой погрешностью"""
	if not turret_node or not is_player_valid():
		return false

	# Направление, куда смотрит турель (учитываем, что спрайт повёрнут вверх)
	var turret_direction = Vector2.UP.rotated(turret_node.rotation)
	
	# Направление к игроку
	var direction_to_player = (_player.global_position - global_position).normalized()
	
	# Угол между направлениями в радианах
	var angle_difference = turret_direction.angle_to(direction_to_player)
	
	# Сравниваем с допустимым порогом (конвертируем градусы в радианы)
	return abs(angle_difference) <= deg_to_rad(aim_threshold_degrees)
