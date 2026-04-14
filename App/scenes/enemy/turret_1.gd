extends CharacterBody2D

# Настройки врага
@export var rotation_speed: float = 1.0          # Скорость поворота к игроку (радиан/сек)
@export var shoot_interval: float = 2.0          # Интервал между выстрелами
@export var bullet_delay: float = 0.2            # Задержка между двумя пулями
@export var bullet_speed: float = 175.0          # Скорость пули
@export var bullets_per_shot: int = 2            # Количество пуль за выстрел

@onready var turret_node: Node2D = $Turret
@onready var animated_sprite: AnimatedSprite2D = $Turret/TurretSprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visible_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
@onready var shooting_point: Marker2D = $Turret/ShootingPoint

var score: int = 150
var health: int = 80
var explosion_force: float = 50.0

var _player: Node2D = null
var _is_shooting: bool = false
var _is_currently_shooting: bool = false
var _is_exploding: bool = false
var shoot_timer: Timer

var bullet_scene: PackedScene = preload("res://scenes/bullets/enemy/enemy_bullet_default.tscn")
var pixel_explosion_scene: PackedScene = preload("res://scenes/effects/pixel_explosion.tscn")
# Звуки
var hit_sound: AudioStream = preload("res://data/audio/sounds/enemy_hit/enemy_hit.mp3")


func _ready() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		_player = players[0]
	
	_setup_timer()


func _setup_timer() -> void:
	shoot_timer = Timer.new()
	shoot_timer.wait_time = shoot_interval
	shoot_timer.one_shot = false
	shoot_timer.autostart = false
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	add_child(shoot_timer)


func _physics_process(delta: float) -> void:
	if _is_exploding:
		return
	
	# Плавный поворот к игроку
	if _player and is_instance_valid(_player):
		_rotate_towards_player(delta)
	
	move_and_slide()


func _rotate_towards_player(delta: float) -> void:
	if not turret_node or not _player:
		return
	
	# Направление от врага к игроку
	var direction_to_player = (_player.global_position - global_position).normalized()
	
	# Целевой угол с учетом того, что спрайт смотрит вверх
	var target_angle = direction_to_player.angle() + PI/2
	
	# Плавно интерполируем текущий угол к целевому
	turret_node.rotation = lerp_angle(turret_node.rotation, target_angle, rotation_speed * delta)


func _start_shooting() -> void:
	if not _is_shooting and not _is_exploding:
		_is_shooting = true
		shoot_timer.start()
		_shoot()  # Выстрелить сразу при входе игрока

func _stop_shooting() -> void:
	_is_shooting = false
	_is_currently_shooting = false
	if shoot_timer:
		shoot_timer.stop()

func _on_shoot_timer_timeout() -> void:
	if _is_shooting and _player and is_instance_valid(_player) and not _is_exploding:
		_shoot()

func _shoot() -> void:
	if not _player or not is_instance_valid(_player) or _is_currently_shooting or _is_exploding:
		return
	
	_is_currently_shooting = true
	
	# Стреляем заданное количество пуль с задержкой
	for i in range(bullets_per_shot):
		if not _is_shooting or _is_exploding:
			break
		
		call_deferred("_spawn_bullet")
		
		if i < bullets_per_shot - 1:
			await get_tree().create_timer(bullet_delay).timeout
	
	# Возвращаемся к анимации ожидания
	if not _is_exploding:
		await get_tree().create_timer(0.3).timeout
	
	_is_currently_shooting = false

func _spawn_bullet() -> void:
	if not bullet_scene or not _player:
		return
	
	# Создаем пулю
	var bullet = bullet_scene.instantiate()
	get_tree().root.add_child(bullet)
	
	# Позиция появления - используем ShootingPoint
	bullet.global_position = shooting_point.global_position if shooting_point else global_position
	
	# Направление к игроку
	var direction = (_player.global_position - global_position).normalized()
	
	# Устанавливаем параметры пули
	bullet.direction = direction
	bullet.shooter = self
	bullet.speed = bullet_speed

func on_hit(damage: int, bullet_type: String) -> void:
	health -= damage
	if health > 0:
		AudioManager.play_sfx(hit_sound, 1, 1.0, global_position)
		return
	if _is_exploding:
		return
	# Устанавливаем силу взрыва в зависимости от типа пули
	match bullet_type:
		"rocket":
			explosion_force = 800
		"homing":
			explosion_force = 500
	
	ScoreManager.add_score(score)
	
	_is_exploding = true
	_stop_shooting()
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
	_start_shooting()

func screen_exited() -> void:
	_stop_shooting()
