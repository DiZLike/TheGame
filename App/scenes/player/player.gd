extends CharacterBody2D

# Сигналы
signal player_respawned(new_position: Vector2)

# Константы настроек игрока
const SPEED: float = 100.0
const GRAVITY: float = 700.0
const JUMP_VELOCITY: float = -325.0  # Начальная скорость прыжка (отрицательная = вверх)
const RESPAWN_DELAY: float = 1.5     # Задержка перед возрождением (сек)
const INVINCIBILITY_DURATION: float = 2.0  # Длительность неуязвимости после возрождения
const BLINK_INTERVAL: float = 0.1    # Интервал мигания при неуязвимости

# Ссылки на узлы
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D          # Анимации персонажа
@onready var collision_shape: CollisionShape2D = $CollisionShape2D          # Основной коллайдер
@onready var damage_collision: CollisionShape2D = $DamageDetector/CollisionShape2D  # Коллайдер для получения урона
@onready var shoot_point: Marker2D = $ShootPoint                            # Точка вылета пули

# Флаги состояния персонажа
var is_jumping: bool = false        # Находится ли в прыжке
var is_crouching: bool = false      # Приседает ли
var is_shooting: bool = false       # Выполняет ли выстрел
var can_move: bool = true           # Может ли двигаться
var is_invincible: bool = false     # Режим неуязвимости
var is_respawning: bool = false     # Идёт процесс возрождения
var blink_tween: Tween = null       # Анимация мигания (для отмены)
var shield_effect: Node2D = null    # Визуальный эффект щита
var original_modulate: Color        # Исходный цвет спрайта (для восстановления)

# Настройки коллайдера в разных позах
@onready var default_collider_pos: Vector2 = collision_shape.position      # Стандартная позиция коллайдера
@onready var default_collider_scale: Vector2 = collision_shape.scale       # Стандартный размер коллайдера
const CROUCH_COLLIDER = {"pos": Vector2(0, 16), "scale": Vector2(1.7, 0.35)}  # При приседании (ниже и шире)
const JUMP_COLLIDER = {"pos": Vector2(0, 14), "scale": Vector2(0, 0.5)}        # В прыжке

# Позиции точки выстрела в зависимости от направления и состояния
const SHOOT_POS = {
	"jump": {   # В прыжке
		Vector2(1,-1): Vector2(10,3),   # вправо-вверх
		Vector2(-1,-1): Vector2(-10,3), # влево-вверх
		Vector2(1,1): Vector2(10,22),   # вправо-вниз
		Vector2(-1,1): Vector2(-10,22), # влево-вниз
		Vector2(0,-1): Vector2(0,3),    # строго вверх
		Vector2(0,1): Vector2(0,22)     # строго вниз
	},
	"move": {   # При движении по земле
		Vector2(1,-1): Vector2(14,-12),  # вправо-вверх
		Vector2(-1,-1): Vector2(-14,-12),# влево-вверх
		Vector2(1,1): Vector2(14,9),    # вправо-вниз
		Vector2(-1,1): Vector2(-14,9)   # влево-вниз
	}
}

# Ресурсы и эффекты
var pixel_explosion_scene: PackedScene = preload("res://scenes/effects/pixel_explosion.tscn")  # Сцена взрыва пикселями
var explosion_force: float = 200.0   # Сила разброса пикселей при взрыве

func _ready():
	# Сохраняем исходный цвет спрайта для последующего восстановления
	original_modulate = modulate

func _physics_process(delta: float) -> void:
	# Если идёт возрождение - не обрабатываем физику
	if is_respawning: return
	
	_apply_gravity(delta)   # Применяем гравитацию
	_handle_input()         # Обрабатываем ввод с клавиатуры
	_update_animation()     # Обновляем анимацию в зависимости от состояния
	move_and_slide()        # Выполняем движение с учётом коллизий
	_reset_jump_flag()      # Сбрасываем флаг прыжка, если стоим на земле

func _apply_gravity(delta: float) -> void:
	# Если не на полу - ускоряемся вниз
	if not is_on_floor(): 
		velocity.y += GRAVITY * delta

func _handle_input() -> void:
	# Если управление заблокировано - останавливаем движение по горизонтали
	if not can_move: 
		velocity.x = move_toward(velocity.x, 0, SPEED)
		return
	
	# Считываем направления
	var dir_x = Input.get_axis("move_left", "move_right")
	
	# --- Приседание (только на земле, не в прыжке, без горизонтального движения) ---
	var crouch = Input.is_action_pressed("move_down") and dir_x == 0
	if crouch and is_on_floor() and not is_jumping:
		if not is_crouching: 
			_set_collider(CROUCH_COLLIDER["pos"], CROUCH_COLLIDER["scale"])
			is_crouching = true
	elif is_crouching:
		_reset_collider()
		is_crouching = false
	
	# --- Прыжок ---
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_crouching:
		velocity.y = JUMP_VELOCITY
		is_jumping = true
	
	# --- Горизонтальное движение ---
	if not is_crouching and dir_x != 0:
		velocity.x = dir_x * SPEED
		animated_sprite.flip_h = dir_x < 0  # Разворачиваем спрайт в сторону движения
	else:
		# Плавная остановка
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	# --- Стрельба ---
	if Input.is_action_pressed("shoot") and not is_shooting:
		is_shooting = true
		
		# Получаем направление ввода с учётом всех осей
		var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if is_crouching: 
			input_dir.y = 0  # В приседе нельзя стрелять вверх/вниз
		
		# Нормализуем направление, если есть ввод, иначе стреляем по умолчанию
		var dir = input_dir.normalized() if input_dir != Vector2.ZERO else (Vector2.RIGHT if not animated_sprite.flip_h else Vector2.LEFT)
		
		_update_shoot_point(input_dir)  # Корректируем точку выстрела
		WeaponManager.try_shoot(self, shoot_point, dir)  # Пытаемся выстрелить через менеджер оружия
		
		# Небольшая задержка, чтобы не стрелять слишком часто
		await get_tree().create_timer(0.05).timeout
		is_shooting = false

func _update_shoot_point(input_dir: Vector2) -> void:
	# Обновляет позицию точки выстрела в зависимости от позы и направления
	var flip = animated_sprite.flip_h
	var key = Vector2(sign(input_dir.x), sign(input_dir.y))
	
	if is_crouching:
		# При приседании - выстрел из фиксированной позиции
		shoot_point.position = Vector2(15, 14) if not flip else Vector2(-15, 14)
	elif not is_jumping:
		# На земле
		shoot_point.position = SHOOT_POS["move"].get(key, Vector2(14 if not flip else -14, 1) if input_dir.y >= 0 else Vector2(2 if not flip else -2, -23))
	else:
		# В прыжке
		shoot_point.position = SHOOT_POS["jump"].get(key, Vector2(9 if not flip else -9, 11))

func _update_animation() -> void:
	# Выбирает и воспроизводит нужную анимацию в зависимости от состояния
	
	# Приседание или обездвиженность
	if not can_move or is_crouching:
		animated_sprite.play("down" if is_crouching else "idle")
		return
	
	var dir_x = Input.get_axis("move_left", "move_right")
	var dir_y = Input.get_axis("move_down", "move_up")
	
	if is_on_floor():
		# На земле - сбрасываем коллайдер к стандартному
		_reset_collider()
		
		if dir_y > 0 and dir_x == 0:
			animated_sprite.play("up")              # Смотрим вверх
		elif dir_y > 0 and dir_x != 0:
			animated_sprite.play("shootUp")         # Бежим вверх-вбок
		elif dir_y < 0 and dir_x != 0:
			animated_sprite.play("shootDown")       # Бежим вниз-вбок
		elif is_shooting:
			# Анимация выстрела зависит от направления
			animated_sprite.play("shootLine" if dir_x != 0 and dir_y == 0 else "shoot")
		else:
			animated_sprite.play("move" if dir_x != 0 else "idle")  # Ходьба или покой
	else:
		# В воздухе
		if is_jumping:
			animated_sprite.play("jump")
			_set_collider(JUMP_COLLIDER["pos"], JUMP_COLLIDER["scale"])  # Уменьшаем коллайдер в прыжке
		else:
			animated_sprite.play("fall")
			_reset_collider()

func _set_collider(pos: Vector2, scl: Vector2) -> void:
	# Изменяет размер и положение коллайдера (основного и для урона)
	if scl.x: 
		collision_shape.scale.x = scl.x
		damage_collision.scale.x = scl.x
	if scl.y: 
		collision_shape.scale.y = scl.y
		damage_collision.scale.y = scl.y
	if pos.x: 
		collision_shape.position.x = pos.x
		damage_collision.position.x = pos.x
	if pos.y: 
		collision_shape.position.y = pos.y
		damage_collision.position.y = pos.y

func _reset_collider() -> void:
	# Возвращает коллайдеры в стандартное состояние
	collision_shape.position = default_collider_pos
	collision_shape.scale = default_collider_scale
	damage_collision.position = default_collider_pos
	damage_collision.scale = default_collider_scale

func _reset_jump_flag() -> void:
	# Если коснулись земли - выходим из состояния прыжка
	if is_on_floor(): 
		is_jumping = false

func take_control_away(use_shield: bool = false):
	# Временно отключает управление и делает игрока неуязвимым
	can_move = false
	is_invincible = true
	if use_shield:
		_create_shield()          # Если нужен щит - создаём визуальный эффект
	else:
		modulate = Color(0.7, 0.7, 1.0)  # Иначе просто меняем цвет (эффект "заморозки")

func restore_control():
	# Возвращает управление и отключает неуязвимость
	can_move = true
	is_invincible = false
	if shield_effect:
		shield_effect.queue_free()
		shield_effect = null
	modulate = original_modulate

func _create_shield():
	# Создаёт пульсирующий полупрозрачный круг вокруг игрока (эффект щита)
	if shield_effect:
		shield_effect.queue_free()
	
	shield_effect = Node2D.new()
	var s = Sprite2D.new()
	s.texture = _circle_texture(28, 4, Color(0.3, 0.5, 1.0))
	s.modulate.a = 0.4
	s.scale = Vector2(0.5, 0.5)
	shield_effect.add_child(s)
	add_child(shield_effect)
	_pulse(s)  # Запускаем анимацию пульсации

func _pulse(sprite: Sprite2D, up: bool = true):
	# Анимирует пульсацию щита (увеличение/уменьшение)
	if not sprite:
		return
	var t = create_tween()
	t.tween_property(sprite, "scale", Vector2(1, 1) if up else Vector2(0.5, 0.5), 0.5)
	await t.finished
	if sprite:
		_pulse(sprite, not up)  # Бесконечный цикл пульсации

func _circle_texture(r: int, w: int, c: Color) -> Texture2D:
	# Генерирует текстуру в виде кольца (окружности) заданного радиуса и толщины
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	for x in 64:
		for y in 64:
			var d = Vector2(32, 32).distance_to(Vector2(x, y))
			if d < r and d > r - w:
				img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)

func _on_area_2d_body_entered(body: Node2D) -> void:
	# Обработчик столкновения с врагами
	if body.is_in_group("enemy") or body.is_in_group("immortal_enemy"):
		if not is_invincible and not is_respawning:
			take_damage()

func take_damage():
	# Наносит урон: уменьшает жизни и запускает возрождение, если жизни ещё есть
	GameManager.sub_lives()
	if GameManager.get_lives() >= 0:
		start_respawn()

func start_respawn():
	# Запускает процесс возрождения
	if is_respawning:
		return
	
	is_respawning = true
	can_move = false
	
	# Взрываем персонажа на пиксели
	call_deferred("pixel_explode")
	
	# Ждём задержку
	await get_tree().create_timer(RESPAWN_DELAY).timeout
	
	# Перемещаем на точку возрождения
	global_position = _find_spawn()
	velocity = Vector2.ZERO
	is_jumping = false
	is_crouching = false
	_reset_collider()
	
	# Снова делаем видимым и активным
	visible = true
	damage_collision.disabled = false
	can_move = true
	
	# Включаем мигание (неуязвимость)
	_activate_blink()
	
	is_respawning = false

func pixel_explode():
	# Создаёт эффект взрыва персонажа на пиксели
	var e = pixel_explosion_scene.instantiate()
	get_tree().root.add_child(e)
	e.explode_from_animated_sprite(animated_sprite, global_position, explosion_force)
	
	# Прячем персонажа во время возрождения
	visible = false
	damage_collision.disabled = true

func _find_spawn() -> Vector2:
	# Ищет ближайшую точку возрождения (SpawnPoint)
	var spawn_points = $"../Environment/SpawnPoints"
	if not spawn_points:
		return Vector2.ZERO
	
	var nearest = null
	var min_distance = INF
	
	for child in spawn_points.get_children():
		if child is Node2D:
			var dist = global_position.distance_to(child.global_position)
			if dist < min_distance:
				min_distance = dist
				nearest = child
	
	return nearest.global_position if nearest else Vector2.ZERO

func _activate_blink():
	# Включает режим неуязвимости с миганием спрайта
	is_invincible = true
	
	# Убиваем старую анимацию, если есть
	if blink_tween:
		blink_tween.kill()
	
	# Запускаем бесконечное мигание (меняем прозрачность)
	blink_tween = create_tween().set_loops()
	blink_tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 0.3), BLINK_INTERVAL / 2)
	blink_tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 1.0), BLINK_INTERVAL / 2)
	
	# Через время неуязвимости отключаем мигание
	await get_tree().create_timer(INVINCIBILITY_DURATION).timeout
	
	if blink_tween:
		blink_tween.kill()
	
	animated_sprite.modulate = Color.WHITE
	modulate = original_modulate
	is_invincible = false
	
	# Сигнализируем о завершении возрождения
	player_respawned.emit(global_position)

# Вспомогательные методы для внешнего использования
func is_respawning_now() -> bool:
	return is_respawning

func force_respawn():
	# Принудительно запускает возрождение (например, при падении в пропасть)
	if not is_respawning:
		start_respawn()
