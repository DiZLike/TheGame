extends DirectionalStaticEnemy
class_name LineShotEnemy

# ============================================
# ВРАГ СТРЕЛЯЮЩИЙ ТОЛЬКО ПРЯМО
# ============================================
# Стреляет только прямо в направлении игрока
# Неуязвим во время анимации idle
# Уязвим как только выходит из idle (начинает attack)
# Стреляет только когда игрок перед ним
# Начинает атаку сразу при появлении на экране
# Использует анимации: "idle", "attack", "attack_to_idle"
# ============================================

# === СОСТОЯНИЯ ===
var _is_vulnerable: bool = false           # Уязвим ли враг сейчас
var _shots_fired: int = 0                  # Сколько выстрелов уже сделано
var _is_animation_paused: bool = false     # Приостановлена ли анимация для стрельбы

# === ТОЧНОСТЬ ПРИЦЕЛИВАНИЯ ===
@export var vertical_tolerance: float = 30.0  # Допустимое отклонение по Y для выстрела

# === ТАЙМЕР ===
var shot_timer: Timer                         # Таймер для задержки между выстрелами


# ============================================
# НАСТРОЙКА
# ============================================

func _ready() -> void:
	# Устанавливаем параметры ДО вызова родительского _ready()
	_movement_type = "none"
	
	super._ready()
	
	# Изначально неуязвим (в idle)
	_is_vulnerable = false
	
	# Настраиваем таймеры
	_setup_attack_timer()
	_setup_shot_timer()
	
	# Подключаемся к сигналам анимации
	_connect_animation_signals()
	
	# Запускаем idle анимацию
	if animated_sprite and animated_sprite.sprite_frames.has_animation("idle"):
		animated_sprite.play("idle")
		_set_vulnerable(false)

func _setup_attack_timer() -> void:
	"""
	Создает и настраивает таймер для интервалов атаки.
	"""
	attack_timer = Timer.new()
	attack_timer.wait_time = attack_interval
	attack_timer.one_shot = false
	attack_timer.autostart = false
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	add_child(attack_timer)

func _setup_shot_timer() -> void:
	"""
	Создает и настраивает таймер для задержки между выстрелами.
	"""
	shot_timer = Timer.new()
	shot_timer.wait_time = attack_delay
	shot_timer.one_shot = false  # Циклический таймер для очереди выстрелов
	shot_timer.autostart = false
	shot_timer.timeout.connect(_on_shot_timer_timeout)
	add_child(shot_timer)


# ============================================
# ПЕРЕОПРЕДЕЛЕНИЕ МЕТОДОВ DirectionalStaticEnemy
# ============================================

func _setup_shooting_points() -> void:
	"""
	Находит и сохраняет точку спавна пуль.
	"""
	var shooting_point = $ShootingPoint
	if shooting_point:
		shooting_points = [shooting_point]

func _get_shoot_directions() -> Array[Vector2]:
	"""
	Возвращает только одно направление - прямо.
	"""
	return [Vector2.LEFT]

func _get_animation_for_direction(direction_index: int) -> String:
	"""
	Возвращает имя анимации - всегда "attack".
	"""
	return "attack"

func _choose_direction_index() -> int:
	"""
	Всегда выбирает прямое направление (индекс 0).
	"""
	return 0


# ============================================
# УПРАВЛЕНИЕ АКТИВАЦИЕЙ
# ============================================

func _on_activate() -> void:
	"""
	Вызывается когда враг появляется на экране.
	Запускает атаку согласно настройкам.
	"""
	_is_active = true
	
	# Запускаем таймер атаки
	if attack_timer:
		attack_timer.start()
	
	# Если нужно атаковать сразу при появлении
	if attack_on_first_appearance and not _has_attacked_on_first_appearance:
		# Небольшая задержка перед первой атакой
		await get_tree().create_timer(0.1).timeout
		_check_and_attack()
		_has_attacked_on_first_appearance = true

func _on_deactivate() -> void:
	"""
	Вызывается когда враг покидает экран.
	Останавливает атаку.
	"""
	
	_is_active = false
	_is_currently_attacking = false
	_is_animation_paused = false
	
	# Останавливаем таймеры
	if attack_timer:
		attack_timer.stop()
	if shot_timer:
		shot_timer.stop()
	
	# Снимаем анимацию с паузы если нужно
	if animated_sprite and animated_sprite.speed_scale == 0:
		animated_sprite.speed_scale = 1.0
	
	# Возвращаемся к idle анимации
	if not _is_exploding and animated_sprite:
		if animated_sprite.sprite_frames.has_animation("idle"):
			animated_sprite.play("idle")
		_set_vulnerable(false)


# ============================================
# АНИМАЦИИ И УЯЗВИМОСТЬ
# ============================================

func _connect_animation_signals() -> void:
	"""
	Подключается к сигналам анимации для отслеживания кадров.
	"""
	if not animated_sprite:
		return
	
	# Подключаемся к сигналу окончания анимации
	if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
		animated_sprite.animation_finished.connect(_on_animation_finished)
	
	# Подключаемся к сигналу смены кадра
	if not animated_sprite.frame_changed.is_connected(_on_frame_changed):
		animated_sprite.frame_changed.connect(_on_frame_changed)

func _on_frame_changed() -> void:
	"""
	Вызывается при смене кадра анимации.
	"""
	if not animated_sprite or not _is_active or _is_exploding:
		return
	
	var current_animation = animated_sprite.animation
	var current_frame = animated_sprite.frame
	
	# Если это анимация attack и мы дошли до второго кадра (индекс 1)
	if current_animation == "attack" and current_frame == 1 and not _is_animation_paused:
		# Приостанавливаем анимацию
		animated_sprite.speed_scale = 0.0
		_is_animation_paused = true
		
		# Начинаем стрельбу
		_start_shooting_sequence()

func _start_shooting_sequence() -> void:
	"""
	Начинает последовательность выстрелов.
	"""
	
	# Сбрасываем счетчик выстрелов
	_shots_fired = 0
	
	# Делаем первый выстрел сразу
	_fire_shot()
	
	# Запускаем таймер для остальных выстрелов (если их больше 1)
	if attacks_per_cycle > 1:
		shot_timer.start()

func _fire_shot() -> void:
	"""
	Выполняет одиночный выстрел.
	"""
	if _is_exploding or not _is_active:
		return
	
	# Проверяем, что игрок все еще в зоне поражения
	if not is_player_in_hit_zone():
		_abort_shooting_sequence()
		return
	
	print("LineShotEnemy: Firing shot ", _shots_fired + 1, " of ", attacks_per_cycle)
	
	# Выполняем выстрел
	_execute_attack()
	
	_shots_fired += 1
	
	# Проверяем, все ли выстрелы сделаны
	if _shots_fired >= attacks_per_cycle:
		_finish_shooting_sequence()

func _on_shot_timer_timeout() -> void:
	"""
	Вызывается по таймеру для следующего выстрела в серии.
	"""
	if _is_exploding or not _is_active:
		return
	
	# Делаем выстрел
	_fire_shot()

func _finish_shooting_sequence() -> void:
	"""
	Завершает последовательность выстрелов и возобновляет анимацию.
	"""
	
	# Останавливаем таймер выстрелов
	if shot_timer:
		shot_timer.stop()
	
	# Возобновляем анимацию
	_is_animation_paused = false
	if animated_sprite:
		# Возобновляем анимацию
		animated_sprite.speed_scale = 1.0

func _abort_shooting_sequence() -> void:
	"""
	Прерывает последовательность выстрелов (игрок вышел из зоны).
	"""
	
	# Останавливаем таймер
	if shot_timer:
		shot_timer.stop()
	
	# Сбрасываем счетчик и флаг атаки
	_shots_fired = 0
	_is_currently_attacking = false
	
	# Сбрасываем флаг паузы
	_is_animation_paused = false
	
	# Снимаем анимацию с паузы, если она была на паузе
	if animated_sprite and animated_sprite.speed_scale == 0.0:
		animated_sprite.speed_scale = 1.0
	
	# Анимация продолжит играть и вызовет _on_animation_finished,
	# где мы проверим _is_currently_attacking == false и перейдём в idle

func _on_animation_finished() -> void:
	"""
	Вызывается когда анимация заканчивается.
	"""
	if not animated_sprite:
		return
	
	var finished_animation = animated_sprite.animation
	
	# Если закончилась анимация attack
	if finished_animation == "attack":
		# Если атака была прервана - переходим в idle
		if not _is_currently_attacking:
			if animated_sprite.sprite_frames.has_animation("attack_to_idle"):
				animated_sprite.play("attack_to_idle")
			else:
				_return_to_idle()
			return
		
		# ПРОВЕРЯЕМ: завершена ли стрельба?
		if _shots_fired < attacks_per_cycle:
			# Стрельба ещё не завершена! Не даем анимации закончиться
			
			# Зацикливаем анимацию на втором кадре, пока не завершится стрельба
			if animated_sprite.sprite_frames.has_animation("attack"):
				animated_sprite.play("attack")
				animated_sprite.frame = 1
				animated_sprite.speed_scale = 0.0
				_is_animation_paused = true
			return
		
		# Если стрельба завершена - переходим к idle
		if animated_sprite.sprite_frames.has_animation("attack_to_idle"):
			animated_sprite.play("attack_to_idle")
		else:
			# Если нет переходной анимации, сразу в idle
			_return_to_idle()
	
	# Если закончилась переходная анимация attack_to_idle
	elif finished_animation == "attack_to_idle":
		_return_to_idle()

func _return_to_idle() -> void:
	"""
	Возвращает врага в состояние idle.
	"""
	
	_shots_fired = 0
	_is_currently_attacking = false
	_is_animation_paused = false
	_set_vulnerable(false)
	
	# Останавливаем таймер выстрелов на всякий случай
	if shot_timer:
		shot_timer.stop()
	
	# Убеждаемся что speed_scale нормальный
	if animated_sprite:
		animated_sprite.speed_scale = 1.0
	
	# Возвращаемся в idle
	if animated_sprite and animated_sprite.sprite_frames.has_animation("idle"):
		animated_sprite.play("idle")

func _set_vulnerable(vulnerable: bool) -> void:
	"""
	Устанавливает состояние уязвимости.
	"""
	_is_vulnerable = vulnerable
	
	# Визуальное отображение уязвимости
	if animated_sprite:
		if _is_vulnerable:
			animated_sprite.modulate = Color.WHITE
		else:
			# Полупрозрачный когда неуязвим
			animated_sprite.modulate = Color(1, 1, 1, 0.7)


# ============================================
# ЦИКЛ АТАКИ
# ============================================

func _check_and_attack() -> void:
	"""
	Проверяет, находится ли игрок в зоне поражения.
	Если да - начинает атаку.
	"""
	if _is_exploding or not _is_active:
		return
	
	# Проверяем, находится ли игрок в зоне поражения
	if is_player_in_hit_zone():
		_perform_attack_cycle()

func _perform_attack_cycle() -> void:
	"""
	Выполняет полный цикл атаки.
	"""
	if _is_exploding or not _is_active:
		return
	
	if _is_currently_attacking:
		return
	
	_is_currently_attacking = true
	
	# Как только выходим из idle - становимся уязвимыми
	_set_vulnerable(true)
	
	# Сбрасываем флаг паузы анимации
	_is_animation_paused = false
	
	# Убеждаемся что speed_scale нормальный перед запуском анимации
	if animated_sprite:
		animated_sprite.speed_scale = 1.0
	
	# Запускаем анимацию attack
	if animated_sprite and animated_sprite.sprite_frames.has_animation("attack"):
		animated_sprite.play("attack")

func is_player_in_hit_zone() -> bool:
	"""
	Проверяет, находится ли игрок в зоне поражения.
	Должен быть перед врагом И на уровне точки спавна пули.
	"""
	if not is_player_valid():
		return false
	
	# Проверяем, что игрок перед врагом
	if not is_player_in_front():
		return false
	
	# Проверяем Y-координату
	if not is_player_on_shooting_line():
		return false
	
	return true

func is_player_in_front() -> bool:
	"""
	Проверяет, находится ли игрок перед врагом (в направлении взгляда).
	"""
	if not is_player_valid():
		return false
	
	var to_player = _player.global_position.x - global_position.x
	var is_facing_right = animated_sprite and animated_sprite.flip_h
	
	# Игрок перед врагом если:
	# - враг смотрит вправо И игрок справа (to_player > 0)
	# - враг смотрит влево И игрок слева (to_player < 0)
	return (is_facing_right and to_player > 0) or (not is_facing_right and to_player < 0)

func is_player_on_shooting_line() -> bool:
	"""
	Проверяет, находится ли игрок на уровне точки спавна пули (по Y).
	"""
	if not is_player_valid():
		return false
	
	# Получаем Y-координату точки спавна пули
	var shooting_y = global_position.y
	
	if shooting_points.size() > 0 and shooting_points[0]:
		shooting_y = shooting_points[0].global_position.y
	
	var player_y = _player.global_position.y
	
	# Проверяем, находится ли игрок в допустимом диапазоне по Y
	return abs(player_y - shooting_y) <= vertical_tolerance

func _on_attack_timer_timeout() -> void:
	"""
	Вызывается по таймеру для выполнения атаки.
	"""
	if _is_active and not _is_exploding and not _is_currently_attacking:
		_check_and_attack()


# ============================================
# ПЕРЕОПРЕДЕЛЕНИЕ УРОНА
# ============================================

func on_hit(damage: int, bullet_type: String) -> void:
	"""
	Обработка получения урона.
	Игнорирует урон если враг неуязвим.
	"""
	if not _is_vulnerable:
		return
	# Если уязвим - получаем урон как обычно
	super.on_hit(damage, bullet_type)

# ============================================
# ПЕРЕОПРЕДЕЛЕНИЕ ПОВОРОТА К ИГРОКУ
# ============================================

func _face_player() -> void:
	"""
	Поворачивает спрайт лицом к игроку.
	"""
	super._face_player()

func _before_explode() -> void:
	"""
	Останавливает атаку перед взрывом.
	"""
	_is_active = false
	_is_currently_attacking = false
	_is_animation_paused = false
	
	if attack_timer:
		attack_timer.stop()
	if shot_timer:
		shot_timer.stop()
	
	# Снимаем анимацию с паузы если она была на паузе
	if animated_sprite and animated_sprite.speed_scale == 0.0:
		animated_sprite.speed_scale = 1.0

func get_is_vulnerable():
	return _is_vulnerable
