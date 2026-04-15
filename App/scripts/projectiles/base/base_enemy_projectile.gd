extends Area2D
class_name BaseEnemyProjectile

# ============================================
# БАЗОВЫЙ КЛАСС ДЛЯ ВСЕХ ВРАЖЕСКИХ СНАРЯДОВ
# ============================================
# Используется для всех снарядов врагов:
# - enemy_bullet_default (пуля турели)
# - mg_fire_1 (фаербол)
# ============================================

# === ОБЩИЕ ПАРАМЕТРЫ ===
@export var speed: float = 300.0              # Скорость полета
@export var damage: int = 1                   # Урон
@export var bullet_type: String = "enemy"     # Тип снаряда (для определения эффектов)
@export var life_time: float = 5.0            # Время жизни
@export var auto_delete_on_exit: bool = true  # Удалять при выходе с экрана
@export var can_hit_shooter: bool = false     # Может ли попасть в стрелявшего

# === НАСТРОЙКИ ЦЕЛЕЙ ===
@export var can_hit_player: bool = true       # Может ли попасть в игрока
@export var can_hit_enemies: bool = false     # Может ли попасть в других врагов

# === ВНУТРЕННИЕ ПЕРЕМЕННЫЕ ===
var direction: Vector2 = Vector2.RIGHT        # Направление полета
var shooter: Node2D = null                    # Кто выпустил снаряд
var _is_queued_for_deletion: bool = false     # Помечен ли на удаление

# === КОМПОНЕНТЫ ===
@onready var animated_sprite: AnimatedSprite2D = $MainSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visible_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D


# ============================================
# ЖИЗНЕННЫЙ ЦИКЛ
# ============================================

func _ready() -> void:
	_initialize()
	_setup_signals()
	_setup_visuals()
	_setup_life_timer()
	_setup_screen_notifier()

func _physics_process(delta: float) -> void:
	if _is_queued_for_deletion:
		return
	
	_move(delta)
	_update_visuals(delta)


# ============================================
# ИНИЦИАЛИЗАЦИЯ
# ============================================

func _initialize() -> void:
	"""
	Инициализация снаряда.
	Переопределяется в дочерних классах для установки специфичных значений.
	"""
	pass

func _setup_signals() -> void:
	"""
	Подключение сигналов столкновений.
	"""
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _setup_visuals() -> void:
	"""
	Настройка визуальных компонентов.
	"""
	if animated_sprite:
		if animated_sprite.sprite_frames.has_animation("idle"):
			animated_sprite.play("idle")

func _setup_life_timer() -> void:
	"""
	Настройка таймера жизни снаряда.
	"""
	if life_time > 0:
		await get_tree().create_timer(life_time).timeout
		if not _is_queued_for_deletion:
			_on_lifetime_expired()

func _setup_screen_notifier() -> void:
	"""
	Настройка отслеживания выхода с экрана.
	"""
	if visible_notifier and auto_delete_on_exit:
		visible_notifier.screen_exited.connect(_on_screen_exited)


# ============================================
# ДВИЖЕНИЕ
# ============================================

func _move(delta: float) -> void:
	"""
	Базовое движение снаряда.
	Переопределяется в дочерних классах для особой физики.
	"""
	global_position += direction * speed * delta


# ============================================
# ВИЗУАЛЬНЫЕ ЭФФЕКТЫ
# ============================================

func _update_visuals(delta: float) -> void:
	"""
	Обновление визуальных эффектов (поворот, анимация).
	Переопределяется в дочерних классах.
	"""
	pass


# ============================================
# ОБРАБОТКА СТОЛКНОВЕНИЙ
# ============================================

func _on_body_entered(body: Node2D) -> void:
	"""
	Обработка столкновения с физическим телом.
	"""
	if _is_queued_for_deletion:
		return
	
	if not _can_hit_target(body):
		return
	
	_handle_hit(body)

func _on_area_entered(area: Area2D) -> void:
	"""
	Обработка столкновения с другой областью.
	"""
	if _is_queued_for_deletion:
		return
	
	var target = _get_target_from_area(area)
	if target and _can_hit_target(target):
		_handle_hit(target)

func _can_hit_target(target: Node2D) -> bool:
	"""
	Проверяет, можно ли атаковать данную цель.
	"""
	# Не можем попасть в стрелявшего (если не разрешено)
	if not can_hit_shooter and target == shooter:
		return false
	
	return _is_valid_target(target)

func _is_valid_target(target: Node2D) -> bool:
	"""
	Проверяет, является ли цель допустимой для атаки.
	"""
	# Проверка для игрока
	if target.is_in_group("player"):
		return can_hit_player
	
	# Проверка для врагов
	if target.is_in_group("enemy"):
		return can_hit_enemies
	
	return false

func _get_target_from_area(area: Area2D) -> Node2D:
	"""
	Извлекает цель из области столкновения.
	"""
	# Проверяем хитбокс игрока
	if area.is_in_group("player_hitbox"):
		var parent = area.get_parent()
		if parent and parent.has_method("on_hit"):
			return parent
	
	# Проверяем хитбокс врага
	if area.is_in_group("enemy_hitbox") and can_hit_enemies:
		var parent = area.get_parent()
		if parent and parent.has_method("on_hit"):
			return parent
	
	return null

func _handle_hit(target: Node2D) -> void:
	"""
	Обрабатывает попадание в цель.
	"""
	_apply_damage(target)
	_play_hit_effect(target)
	_on_hit(target)
	_queue_free()

func _apply_damage(target: Node2D) -> void:
	"""
	Наносит урон цели.
	"""
	if target.has_method("on_hit"):
		target.on_hit(damage, bullet_type)

func _play_hit_effect(target: Node2D) -> void:
	"""
	Проигрывает эффект попадания.
	Переопределяется в дочерних классах.
	"""
	pass

func _on_hit(target: Node2D) -> void:
	"""
	Хук, вызываемый при попадании.
	Переопределяется в дочерних классах для дополнительной логики.
	"""
	pass


# ============================================
# ЗАВЕРШЕНИЕ ЖИЗНИ
# ============================================

func _on_lifetime_expired() -> void:
	"""
	Вызывается когда истекает время жизни.
	"""
	_queue_free()

func _on_screen_exited() -> void:
	"""
	Вызывается когда снаряд покидает экран.
	"""
	if auto_delete_on_exit and not _is_queued_for_deletion:
		_queue_free()

func _queue_free() -> void:
	"""
	Помечает снаряд на удаление.
	"""
	if _is_queued_for_deletion:
		return
	
	_is_queued_for_deletion = true
	_before_free()
	queue_free()

func _before_free() -> void:
	"""
	Вызывается перед удалением снаряда.
	Переопределяется для эффектов исчезновения.
	"""
	pass


# ============================================
# ПУБЛИЧНЫЕ МЕТОДЫ
# ============================================

func set_direction(new_direction: Vector2) -> void:
	"""
	Устанавливает направление полета.
	"""
	direction = new_direction.normalized()

func set_shooter(new_shooter: Node2D) -> void:
	"""
	Устанавливает стрелявшего.
	"""
	shooter = new_shooter

func set_speed(new_speed: float) -> void:
	"""
	Устанавливает скорость полета.
	"""
	speed = new_speed

func set_damage(new_damage: int) -> void:
	"""
	Устанавливает урон.
	"""
	damage = new_damage

func set_bullet_type(new_type: String) -> void:
	"""
	Устанавливает тип снаряда.
	"""
	bullet_type = new_type
