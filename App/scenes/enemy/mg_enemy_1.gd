extends CharacterBody2D

const GRAVITY: float = 700.0

@export var fireball_scene: PackedScene  # Сцена огня
@export var min_fireballs: int = 1      # Минимум огней за бросок
@export var max_fireballs: int = 3      # Максимум огней за бросок
@export var min_throw_force: float = 100.0   # Минимальная сила броска
@export var max_throw_force: float = 300.0   # Максимальная сила броска
@export var throw_interval: float = 2.0      # Интервал между бросками
@export var throw_delay: float = 0.2         # Задержка между огнями при множественном броске

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visible_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

var score: int = 200
var health: int = 100
var explosion_force: float = 50.0

var _is_throwing: bool = false
var _is_currently_throwing: bool = false
var _is_exploding: bool = false
var _player: Node2D = null
var throw_timer: Timer

# Предзагружаем сцену взрыва
var pixel_explosion_scene: PackedScene = preload("res://scenes/effects/pixel_explosion.tscn")

# Звуки
var hit_sound: AudioStream = preload("res://data/audio/sounds/enemy_hit/enemy_hit.mp3")

func _ready() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		_player = players[0]
	
	_setup_sprite()
	_setup_timer()

func _setup_sprite() -> void:
	if animated_sprite:
		animated_sprite.play("idle")  # Стоит на месте, анимация ожидания

func _setup_timer() -> void:
	throw_timer = Timer.new()
	throw_timer.wait_time = throw_interval
	throw_timer.one_shot = false
	throw_timer.autostart = false
	throw_timer.timeout.connect(_on_throw_timer_timeout)
	add_child(throw_timer)

func _physics_process(delta: float) -> void:
	if _is_exploding:
		return
	
	# Применяем гравитацию
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	move_and_slide()
	
	# Поворачиваемся в сторону игрока (даже во время броска)
	if _player:
		_face_player()

func _face_player() -> void:
	if not animated_sprite or not _player:
		return
	
	var direction_to_player = (_player.global_position.x - global_position.x)
	if direction_to_player > 0:
		animated_sprite.flip_h = true   # Смотрим вправо
	else:
		animated_sprite.flip_h = false  # Смотрим влево

func _start_throwing() -> void:
	if not _is_throwing and not _is_exploding:
		_is_throwing = true
		throw_timer.start()
		_throw_fireballs()  # Бросить сразу при входе игрока

func _stop_throwing() -> void:
	_is_throwing = false
	_is_currently_throwing = false
	if throw_timer:
		throw_timer.stop()

func _on_throw_timer_timeout() -> void:
	if _is_throwing and _player and is_instance_valid(_player) and not _is_exploding:
		_throw_fireballs()

func _throw_fireballs() -> void:
	if not _player or not is_instance_valid(_player) or _is_currently_throwing or _is_exploding:
		return
	
	_is_currently_throwing = true
	
	# Определяем количество огней
	var fireball_count = randi_range(min_fireballs, max_fireballs)
	
	# Анимация броска
	if animated_sprite:
		animated_sprite.play("attack")
	
	# Бросаем огни с задержкой
	for i in range(fireball_count):
		if not _is_throwing or _is_exploding:
			break
		call_deferred("_throw_single_fireball")
		if i < fireball_count - 1:
			await get_tree().create_timer(throw_delay).timeout
	
	# Возвращаемся к анимации ожидания
	if animated_sprite and not _is_exploding:
		await get_tree().create_timer(0.3).timeout
		if not _is_exploding and _is_throwing:
			animated_sprite.play("idle")
	
	_is_currently_throwing = false

func _throw_single_fireball() -> void:
	if not fireball_scene or not _player:
		return
	
	# Создаем огонь
	var fireball = fireball_scene.instantiate()
	get_tree().root.add_child(fireball)
	
	# Позиция появления (перед врагом)
	var spawn_offset = 10 if not animated_sprite.flip_h else -10
	fireball.global_position = global_position + Vector2(spawn_offset, -10)
	
	# Направление в сторону игрока (горизонталь)
	var direction_to_player = (_player.global_position - global_position).normalized()
	
	# Случайная сила броска
	var throw_force = randf_range(min_throw_force, max_throw_force)
	
	# Добавляем вертикальную силу (подброс вверх)
	var vertical_force = randf_range(-350.0, -100.0)  # Отрицательное значение = вверх
	
	# Комбинируем горизонтальную и вертикальную силы
	var throw_vector = Vector2(direction_to_player.x * throw_force, vertical_force)
	
	# Применяем физику
	fireball.apply_force(throw_vector)

func on_hit(damage: int, bullet_type: String) -> void:
	health -= damage
	if health > 0:
		AudioManager.play_sfx(hit_sound, 1, 1.0, global_position)
		return
	if _is_exploding:
		return
	match bullet_type:
		"rocket":
			explosion_force = 800
		"homing":
			explosion_force = 500
		
	ScoreManager.add_score(score)
	
	_is_exploding = true
	_stop_throwing()  # Останавливаем броски при смерти
	call_deferred("_explode")

func _explode() -> void:
	# Создаем сцену взрыва
	var explosion = pixel_explosion_scene.instantiate()
	get_tree().root.add_child(explosion)
	
	# Запускаем взрыв от текущего спрайта
	explosion.explode_from_animated_sprite(animated_sprite, global_position, 50.0)
	
	# Скрываем оригинального персонажа
	visible = false
	collision_shape.disabled = true
	animated_sprite.visible = false
	
	# Удаляем персонажа после небольшой задержки
	await get_tree().create_timer(0.5).timeout
	queue_free()


func screen_entered() -> void:
	_start_throwing()

func screen_exited() -> void:
	_stop_throwing()
	# Возвращаем анимацию, только если не взрываемся
	if not _is_exploding and animated_sprite:
		animated_sprite.play("idle")
