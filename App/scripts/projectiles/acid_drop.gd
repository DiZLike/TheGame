extends BaseEnemyProjectile
class_name AcidDrop

# ============================================
# КАПЛЯ КИСЛОТЫ
# ============================================
# Подбрасывается вверх со случайной силой.
# Подвержена гравитации, падает вниз по дуге.
# При касании с землёй создаёт пиксельный взрыв.
# ============================================

# === ПАРАМЕТРЫ ФИЗИКИ ===
@export var acid_gravity: float = 500.0                # Гравитация, действующая на каплю
@export var explosion_force: float = 30.0          # Сила пиксельного взрыва

# === ВНУТРЕННИЕ ПЕРЕМЕННЫЕ ===
var _velocity: Vector2 = Vector2.ZERO             # Текущая скорость капли

# === РЕСУРСЫ ===
var pixel_explosion_scene: PackedScene = preload("res://scenes/effects/pixel_explosion.tscn")
var splash_sound: AudioStream = preload("res://data/audio/sounds/enemy/death1.wav")


# ============================================
# ИНИЦИАЛИЗАЦИЯ
# ============================================

func _initialize() -> void:
	"""
	Настройка параметров капли кислоты.
	"""
	bullet_type = "acid"
	life_time = 10.0
	auto_delete_on_exit = true


# ============================================
# ДВИЖЕНИЕ
# ============================================

func _move(delta: float) -> void:
	"""
	Движение капли с учётом гравитации.
	"""
	_velocity.y += gravity * delta
	global_position += _velocity * delta


# ============================================
# ОБРАБОТКА СТОЛКНОВЕНИЙ
# ============================================

func _on_body_entered(body: Node2D) -> void:
	"""
	Обработка столкновения с физическим телом (земля, стены).
	"""
	if _is_queued_for_deletion:
		return
	
	if _can_hit_target(body):
		_handle_hit(body)
		return
	
	_explode()

func _handle_hit(target: Node2D) -> void:
	"""
	Обрабатывает попадание в цель и взрывается.
	"""
	# Игрок сам обрабатывает урон через свой метод on_hit
	if target.has_method("on_hit"):
		target.on_hit(1, bullet_type)
	
	_explode()


# ============================================
# ВЗРЫВ
# ============================================

func _explode() -> void:
	"""
	Создаёт пиксельный взрыв и уничтожает каплю.
	"""
	if _is_queued_for_deletion:
		return
	
	_is_queued_for_deletion = true
	
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	
	if pixel_explosion_scene:
		var explosion = pixel_explosion_scene.instantiate()
		get_tree().root.add_child(explosion)
		
		if animated_sprite:
			explosion.explode_from_animated_sprite(animated_sprite, global_position, explosion_force)
		else:
			explosion.explode_from_animated_sprite(null, global_position, explosion_force)
	
	queue_free()


# ============================================
# ЦЕЛИ
# ============================================

func _is_valid_target(target: Node2D) -> bool:
	"""
	Капля может попасть только в игрока.
	"""
	return target.is_in_group("player") and can_hit_player


# ============================================
# ПУБЛИЧНЫЕ МЕТОДЫ
# ============================================

func set_velocity(vel: Vector2) -> void:
	_velocity = vel

func set_acid_gravity(grav: float) -> void:
	gravity = grav

func set_explosion_force(force: float) -> void:
	explosion_force = force
