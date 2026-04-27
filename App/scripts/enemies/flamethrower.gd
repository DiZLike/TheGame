extends StaticEnemy
class_name Flamethrower

# ============================================
# ОГНЕМЁТЧИК - СТАТИЧНЫЙ ВРАГ БЕЗ ГРАВИТАЦИИ
# ============================================
# Всегда смотрит на игрока и стреляет строго прямо.
# Спрайт изначально смотрит ВЛЕВО.
# ============================================

# === НАСТРОЙКИ ===
@export var bullet_speed: float = 200.0
@export var bullet_scene: PackedScene

# === ТОЧКА СПАВНА ПУЛЬ ===
@onready var shooting_point: Marker2D = $ShootingPoint


func _ready() -> void:
	# Настраиваем параметры для расчёта очков
	_attack_pattern = "burst"
	_movement_type = "rotate"
	
	super._ready()
	
	# Загружаем стандартную пулю, если не указана другая
	if not bullet_scene:
		bullet_scene = preload("res://scenes/bullets/enemy/enemy_bullet_default.tscn")


func _physics_process(delta: float) -> void:
	if _is_exploding:
		return
	
	# Поворачиваемся лицом к игроку
	if is_player_valid():
		_face_player()
		_update_shooting_point()
	
	move_and_slide()


func _execute_attack() -> void:
	"""
	Создаёт пулю, летящую строго в том направлении, куда смотрит враг.
	"""
	if not bullet_scene or not is_player_valid():
		return
	
	var bullet = bullet_scene.instantiate()
	get_tree().root.add_child(bullet)
	
	# Позиция появления
	bullet.global_position = shooting_point.global_position if shooting_point else global_position
	
	# Базовое направление — ВЛЕВО (спрайт изначально смотрит влево)
	var direction = Vector2.LEFT
	
	# Если спрайт отзеркален (flip_h = true), враг смотрит вправо
	if animated_sprite and animated_sprite.flip_h:
		direction = Vector2.RIGHT
	
	# Устанавливаем параметры пули
	if bullet.has_method("set_shooter"):
		bullet.set_shooter(self)
	
	var pitch: float = randf_range(0.7, 1)
	
	AudioManager.play_sfx(shot_sound, 1, pitch, global_position)
	bullet.set("direction", direction)
	bullet.set("speed", bullet_speed)


func _update_shooting_point() -> void:
	"""
	Зеркалит позицию ShootingPoint при повороте спрайта.
	Спрайт изначально смотрит влево, поэтому:
	- flip_h = false (влево): shooting_point.position.x отрицательный
	- flip_h = true  (вправо): shooting_point.position.x положительный
	"""
	if not shooting_point or not animated_sprite:
		return
	
	if animated_sprite.flip_h:
		# Смотрит вправо — точка спавна справа
		shooting_point.position.x = abs(shooting_point.position.x)
	else:
		# Смотрит влево — точка спавна слева
		shooting_point.position.x = -abs(shooting_point.position.x)
