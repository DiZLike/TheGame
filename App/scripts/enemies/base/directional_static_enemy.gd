extends StaticEnemy
class_name DirectionalStaticEnemy

# ============================================
# БАЗОВЫЙ КЛАСС ДЛЯ ВРАГОВ СТРЕЛЯЮЩИХ В ФИКСИРОВАННЫХ НАПРАВЛЕНИЯХ
# ============================================
# Для врагов которые стоят на месте (без гравитации) и стреляют
# в направлениях относительно своего спрайта.
# Всегда повернуты лицом к игроку.
# ============================================

# === НАСТРОЙКИ ===
@export var bullet_speed: float = 200.0
@export var bullet_scene: PackedScene

# === КОМПОНЕНТЫ (переопределяются в дочерних классах) ===
var shooting_points: Array[Marker2D] = []  # Массив точек спавна пуль

# === ВИРТУАЛЬНЫЕ МЕТОДЫ (переопределяются в дочерних классах) ===

func _get_shoot_directions() -> Array[Vector2]:
	"""
	Возвращает массив направлений для стрельбы.
	Должен быть переопределен в дочернем классе.
	
	Направления указываются ОТНОСИТЕЛЬНО БАЗОВОГО НАПРАВЛЕНИЯ (влево).
	Пример: [Vector2.LEFT, Vector2(-1, -1).normalized(), Vector2(-1, 1).normalized()]
	"""
	return [Vector2.LEFT]

func _get_animation_for_direction(direction_index: int) -> String:
	"""
	Возвращает имя анимации для указанного индекса направления.
	Должен быть переопределен в дочернем классе.
	"""
	return "attack"

func _choose_direction_index() -> int:
	"""
	Выбирает индекс направления для следующего выстрела.
	Может быть переопределен в дочернем классе.
	"""
	return 0

func _setup_shooting_points() -> void:
	"""
	Находит и сохраняет точки спавна пуль.
	Должен быть переопределен в дочернем классе.
	"""
	pass


# ============================================
# НАСТРОЙКА
# ============================================

func _ready() -> void:
	# Устанавливаем параметры ДО вызова родительского _ready()
	_movement_type = "rotate"     # Поворачивается к игроку
	super._ready()
	
	# Загружаем сцену пули если не задана
	if not bullet_scene:
		bullet_scene = preload("res://scenes/bullets/enemy/enemy_bullet_default.tscn")
	
	# Настраиваем точки спавна
	_setup_shooting_points()


# ============================================
# ФИЗИКА
# ============================================

func _physics_process(delta: float) -> void:
	"""
	Переопределяем чтобы убрать гравитацию.
	"""
	if _is_exploding:
		return
	
	# НЕТ ГРАВИТАЦИИ - враг висит в воздухе
	
	# Поворачиваем спрайт к игроку
	if is_player_valid():
		_face_player()
	
	# Обновляем позиции точек спавна при отзеркаливании
	_update_shooting_points_positions()
	
	move_and_slide()


# ============================================
# АТАКА
# ============================================

func _execute_attack() -> void:
	"""
	Выполняет одиночную атаку в выбранном направлении.
	"""
	if not bullet_scene or not is_player_valid():
		return
	
	# Выбираем направление для этого выстрела
	var direction_index = _choose_direction_index()
	
	# Проигрываем соответствующую анимацию
	var anim_name = _get_animation_for_direction(direction_index)
	_play_attack_animation(anim_name)
	
	# Ждем кадр чтобы анимация начала проигрываться
	await get_tree().process_frame
	
	# Создаем пулю
	var bullet = bullet_scene.instantiate()
	get_tree().root.add_child(bullet)
	
	# Позиция появления - используем соответствующую точку спавна
	var spawn_position = global_position
	if direction_index >= 0 and direction_index < shooting_points.size():
		var shooting_point = shooting_points[direction_index]
		if shooting_point:
			spawn_position = shooting_point.global_position
	
	bullet.global_position = spawn_position
	
	# Получаем все возможные направления и выбираем нужное
	var directions = _get_shoot_directions()
	if direction_index >= 0 and direction_index < directions.size():
		var relative_direction = directions[direction_index]
		var final_direction = _apply_sprite_flip_to_direction(relative_direction)
		
		# Устанавливаем параметры пули
		if bullet.has_method("set_shooter"):
			bullet.set_shooter(self)
		AudioManager.play_sfx(shot_sound, 1, 1, global_position)
		bullet.set("direction", final_direction)
		bullet.set("speed", bullet_speed)

func _play_attack_animation(anim_name: String) -> void:
	"""
	Проигрывает анимацию атаки если она существует.
	"""
	if not animated_sprite:
		return
	
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)
	elif animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("attack"):
		# Fallback на "attack" если указанная анимация не найдена
		animated_sprite.play("attack")

func _apply_sprite_flip_to_direction(relative_direction: Vector2) -> Vector2:
	"""
	Применяет отражение спрайта к относительному направлению.
	Относительные направления заданы для спрайта смотрящего ВЛЕВО.
	Если спрайт отзеркален (flip_h = true) - инвертируем X.
	"""
	if animated_sprite and animated_sprite.flip_h:
		return Vector2(-relative_direction.x, relative_direction.y)
	return relative_direction

func _update_shooting_points_positions() -> void:
	"""
	Обновляет позиции точек спавна при отзеркаливании спрайта.
	Должен быть переопределен в дочернем классе если нужна кастомная логика.
	"""
	if not animated_sprite:
		return
	
	# По умолчанию зеркалим X позицию для всех точек
	var is_flipped = animated_sprite.flip_h
	for point in shooting_points:
		if point and point.has_method("set_flipped"):
			point.set_flipped(is_flipped)


# ============================================
# ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
# ============================================

func _face_player() -> void:
	"""
	Поворачивает спрайт лицом к игроку.
	Спрайт изначально смотрит НАЛЕВО.
	"""
	if not animated_sprite or not is_player_valid():
		return
	
	var direction_to_player = (_player.global_position.x - global_position.x)
	# flip_h = true когда игрок справа (спрайт смотрит направо)
	animated_sprite.flip_h = direction_to_player > 0
