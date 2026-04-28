extends MovingEnemy
class_name SchoolboyShooter

# ============================================
# ШКОЛЬНИК-СТРЕЛОК - ДВИЖУЩИЙСЯ ВРАГ С АТАКОЙ
# ============================================

# === НАСТРОЙКИ АТАКИ ===
@export_range(0, 10) var attack_interval: float = 2.5
@export_range(0, 10) var attack_delay: float = 0.4
@export_range(0, 10) var attacks_per_cycle: int = 1
@export var attack_on_first_appearance: bool = false

# === НАСТРОЙКИ ДВИЖЕНИЯ ===
@export var always_move_toward_player: bool = false
@export var change_direction_on_wall: bool = true

# === НАСТРОЙКИ ПУЛИ ===
@export var bullet_speed: float = 200.0
@export var bullet_scene: PackedScene
@export var shoot_straight: bool = true

# === КОМПОНЕНТЫ ===
@onready var shooting_point: Marker2D = $ShootingPoint  # Точка спавна пуль

# === СОСТОЯНИЯ ===
enum State { MOVING, ATTACKING }
var current_state: State = State.MOVING

var attack_timer: Timer
var move_timer: Timer
var _is_currently_attacking: bool = false
var _has_attacked_on_first_appearance: bool = false
var _stuck_counter: int = 0
var _last_position: Vector2

# === ВРЕМЯ ДВИЖЕНИЯ МЕЖДУ АТАКАМИ ===
@export var move_duration: float = 2.0

# === ДОПУСТИМАЯ ПОГРЕШНОСТЬ ДЛЯ НАПРАВЛЕНИЯ ===
const DIRECTION_THRESHOLD: float = 10.0


# ============================================
# НАСТРОЙКА
# ============================================

func _configure_stats() -> void:
	super._configure_stats()
	_attack_pattern = "single"
	if attacks_per_cycle > 1:
		_attack_pattern = "burst"
		burst_bonus = attacks_per_cycle * 10

func _ready() -> void:
	super._ready()
	
	_set_initial_direction()
	
	if not bullet_scene:
		bullet_scene = preload("res://scenes/bullets/enemy/enemy_bullet_default.tscn")
	
	_setup_timers()
	_last_position = global_position
	
	# Настройка точки спавна
	_setup_shooting_point()

func _setup_shooting_point() -> void:
	"""
	Настраивает точку спавна пуль.
	Если её нет - создает по умолчанию.
	"""
	if not shooting_point:
		# Создаем точку спавна по умолчанию
		shooting_point = Marker2D.new()
		shooting_point.name = "ShootingPoint"
		add_child(shooting_point)
		
		# Позиция по умолчанию: перед врагом
		if animated_sprite:
			var sprite_width = animated_sprite.sprite_frames.get_frame_texture("idle", 0).get_width() if animated_sprite.sprite_frames.has_animation("idle") else 32
			shooting_point.position = Vector2(-sprite_width / 2, 0)
		else:
			shooting_point.position = Vector2(-16, 0)

func _set_initial_direction() -> void:
	"""
	Устанавливает начальное направление движения в сторону игрока.
	"""
	if not is_player_valid():
		return
	
	var direction_to_player = _player.global_position.x - global_position.x
	
	if abs(direction_to_player) < DIRECTION_THRESHOLD:
		return
	
	if direction_to_player > 0:
		move_direction = Direction.RIGHT
	else:
		move_direction = Direction.LEFT
	
	_update_sprite_flip()
	_update_ground_check()
	_update_wall_check_position()
	_update_shooting_point_position()

func _setup_timers() -> void:
	attack_timer = Timer.new()
	attack_timer.wait_time = attack_interval
	attack_timer.one_shot = false
	attack_timer.autostart = false
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	add_child(attack_timer)
	
	move_timer = Timer.new()
	move_timer.wait_time = move_duration
	move_timer.one_shot = false
	move_timer.autostart = false
	move_timer.timeout.connect(_on_move_timer_timeout)
	add_child(move_timer)


# ============================================
# УПРАВЛЕНИЕ АКТИВАЦИЕЙ
# ============================================

func _on_activate() -> void:
	super._on_activate()
	
	if attack_on_first_appearance and not _has_attacked_on_first_appearance:
		_start_attacking()
	else:
		_start_moving()

func _on_deactivate() -> void:
	super._on_deactivate()
	_stop_all_timers()
	current_state = State.MOVING


# ============================================
# ФИЗИКА И ДВИЖЕНИЕ
# ============================================

func _physics_process(delta: float) -> void:
	if _is_exploding:
		return
	
	# Обновляем позицию точки спавна при каждом кадре (для зеркалирования)
	_update_shooting_point_position()
	
	_check_if_stuck()
	
	match current_state:
		State.MOVING:
			_process_moving(delta)
		State.ATTACKING:
			_process_attacking(delta)

func _process_moving(delta: float) -> void:
	if always_move_toward_player and is_player_valid():
		_update_direction_toward_player_safe()
	
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	velocity.x = direction_vector.x * move_speed
	
	if is_on_floor() and not _is_ground_ahead():
		velocity.y = jump_velocity
	
	if change_direction_on_wall and wall_ahead:
		_change_direction()
	
	move_and_slide()

func _process_attacking(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	velocity.x = 0
	
	move_and_slide()

func _update_direction_toward_player_safe() -> void:
	"""
	Безопасное обновление направления к игроку с защитой от дерганья.
	"""
	if not is_player_valid():
		return
	
	var direction_to_player = _player.global_position.x - global_position.x
	
	if abs(direction_to_player) < DIRECTION_THRESHOLD:
		return
	
	var new_direction = Direction.RIGHT if direction_to_player > 0 else Direction.LEFT
	
	if new_direction != move_direction:
		move_direction = new_direction
		_update_sprite_flip()
		_update_ground_check()
		_update_wall_check_position()
		_update_shooting_point_position()  # Обновляем точку спавна

func _update_shooting_point_position() -> void:
	"""
	Обновляет позицию точки спавна в зависимости от отражения спрайта.
	Инвертирует X координату при отражении.
	"""
	if not shooting_point:
		return
	
	if not animated_sprite:
		return
	
	# Сохраняем абсолютное значение оригинальной позиции
	var original_x = abs(shooting_point.position.x)
	var original_y = shooting_point.position.y
	
	# Если спрайт отражен, инвертируем X координату
	if animated_sprite.flip_h:
		shooting_point.position = Vector2(original_x, original_y)
	else:
		shooting_point.position = Vector2(-original_x, original_y)

func _check_if_stuck() -> void:
	"""
	Проверяет, не застрял ли враг.
	"""
	var current_pos = global_position
	if current_pos.distance_to(_last_position) < 1.0:
		_stuck_counter += 1
	else:
		_stuck_counter = 0
	
	_last_position = current_pos
	
	if _stuck_counter > 60 and current_state == State.MOVING:
		if change_direction_on_wall:
			_change_direction()
		else:
			if is_on_floor():
				velocity.y = jump_velocity
		_stuck_counter = 0


# ============================================
# УПРАВЛЕНИЕ СОСТОЯНИЯМИ
# ============================================

func _start_moving() -> void:
	if _is_exploding:
		return
	
	current_state = State.MOVING
	move_timer.start()
	
	if animated_sprite:
		animated_sprite.play("move")

func _start_attacking() -> void:
	if _is_exploding or not is_player_valid():
		return
	
	current_state = State.ATTACKING
	_has_attacked_on_first_appearance = true
	_perform_attack()

func _stop_all_timers() -> void:
	if attack_timer:
		attack_timer.stop()
	if move_timer:
		move_timer.stop()

func _on_move_timer_timeout() -> void:
	if current_state == State.MOVING and not _is_exploding:
		_start_attacking()

func _on_attack_timer_timeout() -> void:
	if current_state == State.ATTACKING and not _is_exploding:
		if is_player_valid():
			_perform_attack()


# ============================================
# ВЫПОЛНЕНИЕ АТАКИ
# ============================================

func _perform_attack() -> void:
	if not is_player_valid() or _is_currently_attacking or _is_exploding:
		return
	
	_is_currently_attacking = true
	
	# Запоминаем направление стрельбы и состояние спрайта в начале серии
	var shoot_direction = _get_shoot_direction()
	var flip_state = animated_sprite.flip_h if animated_sprite else false
	
	if animated_sprite:
		animated_sprite.play("attack")
	
	for i in range(attacks_per_cycle):
		if current_state != State.ATTACKING or _is_exploding:
			break
		
		_execute_attack(shoot_direction, flip_state)
		
		if i < attacks_per_cycle - 1:
			await get_tree().create_timer(attack_delay).timeout
	
	if animated_sprite and not _is_exploding:
		await get_tree().create_timer(0.2).timeout
	
	_is_currently_attacking = false
	
	if current_state == State.ATTACKING and not _is_exploding:
		if attacks_per_cycle == 1:
			attack_timer.start()
		_start_moving()

func _get_shoot_direction() -> Vector2:
	"""
	Возвращает направление для стрельбы.
	"""
	if shoot_straight:
		# Стреляем строго в сторону, куда смотрит спрайт
		if animated_sprite and animated_sprite.flip_h:
			return Vector2.RIGHT
		else:
			return Vector2.LEFT
	else:
		# В сторону игрока
		return (_player.global_position - global_position).normalized()

func _execute_attack(shoot_direction: Vector2, flip_state: bool = false) -> void:
	"""
	Создает пулю из точки спавна ShootingPoint.
	"""
	if not bullet_scene or not is_player_valid():
		return
	
	var bullet = bullet_scene.instantiate()
	get_tree().root.add_child(bullet)
	
	# Используем глобальную позицию ShootingPoint
	var spawn_position = shooting_point.global_position if shooting_point else global_position
	bullet.global_position = spawn_position
	
	if bullet.has_method("set_shooter"):
		bullet.set_shooter(self)
	
	AudioManager.play_sfx(shot_sound, 0.2, 1, global_position)
	
	bullet.set("direction", shoot_direction)
	bullet.set("speed", bullet_speed)


# ============================================
# ПЕРЕОПРЕДЕЛЕНИЕ СМЕНЫ НАПРАВЛЕНИЯ
# ============================================

func _change_direction() -> void:
	"""
	Меняет направление движения с небольшой задержкой.
	"""
	if current_state == State.ATTACKING:
		return
	
	super._change_direction()
	
	# Обновляем точку спавна после смены направления
	_update_shooting_point_position()


# ============================================
# ОЧИСТКА ПЕРЕД ВЗРЫВОМ
# ============================================

func _before_explode() -> void:
	_stop_all_timers()
