@tool
extends StaticEnemy
class_name AcidDripper

# ============================================
# ACID DRIPPER - СТАТИЧНЫЙ ВРАГ, РОНЯЮЩИЙ КАПЛИ
# ============================================
# Использует стандартную логику StaticEnemy:
# - attack_interval, attack_delay, attacks_per_cycle
# - attack_on_first_appearance
# Капля спавнится после полного проигрывания анимации "drop"
# ============================================

# === НАСТРОЙКИ КАПЕЛЬ ===
@export var drop_scene: PackedScene              # Сцена капли кислоты
@export var drop_gravity: float = 300.0          # Гравитация капли
@export var drop_speed: float = 1.0              # Скорость анимации

# === КОМПОНЕНТЫ ===
@onready var spawn_point = $SpawnPoint

# === СОСТОЯНИЯ ===
var _waiting_for_drop_animation: bool = false    # Ожидаем окончания анимации drop
var _current_attack_cycle: int = 0               # Текущий номер атаки в цикле


# ============================================
# НАСТРОЙКА
# ============================================

func _configure_stats() -> void:
	_attack_pattern = "spread"

func _setup_components() -> void:
	super._setup_components()
	if not animated_sprite:
		animated_sprite = $AnimatedSprite2D
	
	if animated_sprite:
		animated_sprite.speed_scale = drop_speed
		if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
			animated_sprite.animation_finished.connect(_on_animation_finished)
		animated_sprite.play("idle")
	else:
		push_error("AcidDripper: AnimatedSprite2D не найден!")


# ============================================
# ПОЛНОСТЬЮ ПЕРЕОПРЕДЕЛЯЕМ ЛОГИКУ АТАКИ
# ============================================

func _perform_attack() -> void:
	"""
	Полностью переопределяем метод атаки.
	Вместо мгновенного цикла — управляем через анимации.
	"""
	if not is_player_valid() or _is_currently_attacking or _is_exploding:
		return
	
	_is_currently_attacking = true
	_current_attack_cycle = 0
	
	# Запускаем первую атаку
	_start_drop_animation()


func _start_drop_animation() -> void:
	"""
	Запускает анимацию drop для одной атаки.
	"""
	if not animated_sprite or _is_exploding:
		_is_currently_attacking = false
		return
	
	if animated_sprite.sprite_frames.has_animation("attack"):
		animated_sprite.play("attack")
	elif animated_sprite.sprite_frames.has_animation("drop"):
		animated_sprite.play("drop")
	else:
		# Если нет специальной анимации — спавним сразу
		_spawn_drop_and_continue()
		return
	
	_waiting_for_drop_animation = true


# ============================================
# АНИМАЦИЯ И СПАВН КАПЕЛЬ
# ============================================

func _on_animation_finished() -> void:
	"""
	Вызывается когда любая анимация полностью проигралась.
	"""
	if not _waiting_for_drop_animation:
		return
	
	if not animated_sprite:
		return
	
	# Проверяем, что это была анимация атаки
	var current_anim = animated_sprite.animation
	if current_anim == "drop" or current_anim == "attack":
		_waiting_for_drop_animation = false
		_spawn_drop_and_continue()


func _spawn_drop_and_continue() -> void:
	"""
	Спавнит каплю и решает, что делать дальше.
	"""
	# Спавним каплю
	_spawn_drop()
	
	# Проверяем, не умираем ли
	if _is_exploding:
		_is_currently_attacking = false
		return
	
	_current_attack_cycle += 1
	
	# Если нужно еще атаки в этом цикле
	if _current_attack_cycle < attacks_per_cycle and _is_attacking:
		# Ждём задержку и запускаем следующую атаку
		if animated_sprite:
			if animated_sprite.sprite_frames.has_animation("idle"):
				animated_sprite.play("idle")
		
		await get_tree().create_timer(attack_delay).timeout
		
		if not _is_exploding and _is_attacking:
			_start_drop_animation()
	else:
		# Цикл завершён — возвращаемся в idle
		_finish_attack_cycle()


func _finish_attack_cycle() -> void:
	"""
	Завершает цикл атаки и возвращает в idle.
	"""
	if animated_sprite and not _is_exploding:
		if animated_sprite.sprite_frames.has_animation("idle"):
			animated_sprite.play("idle")
	
	# Небольшая пауза перед завершением
	await get_tree().create_timer(0.3).timeout
	
	if not _is_exploding and _is_attacking:
		if animated_sprite and animated_sprite.sprite_frames.has_animation("idle"):
			animated_sprite.play("idle")
	
	_is_currently_attacking = false


func _spawn_drop() -> void:
	if not drop_scene:
		return
	
	var drop = drop_scene.instantiate()
	get_tree().root.add_child(drop)
	
	drop.global_position = _get_drop_spawn_position()
	
	if drop.has_method("set_velocity"):
		drop.set_velocity(Vector2.ZERO)
	if drop.has_method("set_gravity"):
		drop.set_gravity(drop_gravity)
	if drop.has_method("set_shooter"):
		drop.set_shooter(self)


func _get_drop_spawn_position() -> Vector2:
	return spawn_point.global_position if spawn_point else global_position


# ============================================
# ОТКЛЮЧАЕМ НЕНУЖНЫЕ МЕТОДЫ РОДИТЕЛЯ
# ============================================

func _execute_attack() -> void:
	# Переопределяем пустым, так как вся логика в _perform_attack
	pass


# ============================================
# ОЧИСТКА ПРИ СМЕРТИ
# ============================================

func _before_explode() -> void:
	super._before_explode()
	_waiting_for_drop_animation = false
	_is_currently_attacking = false
