extends Area2D

# ============================================
# ПУЛЯ ЛЕТАЮЩЕГО ВРАГА
# ============================================

# === ОБЩИЕ ПАРАМЕТРЫ ===
var direction: Vector2 = Vector2.RIGHT:
	set(value):
		direction = value

var shooter: Node2D = null
var speed: float = 300.0
var damage: int = 1
var bullet_type: String = "enemy_bullet"

# === ДОПОЛНИТЕЛЬНЫЕ НАСТРОЙКИ ===
var auto_delete_on_exit: bool = true
var life_time: float = 5.0
var can_hit_shooter: bool = false

# === ВНУТРЕННИЕ ПЕРЕМЕННЫЕ ===
var _is_queued_for_deletion: bool = false


# ============================================
# ЖИЗНЕННЫЙ ЦИКЛ
# ============================================
func _ready() -> void:
	_setup_signals()
	_setup_life_timer()


func _physics_process(delta: float) -> void:
	_move(delta)


# ============================================
# НАСТРОЙКА
# ============================================
func _setup_signals() -> void:
	# Подключаем сигналы столкновений
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _setup_life_timer() -> void:
	if life_time > 0:
		await get_tree().create_timer(life_time).timeout
		if not _is_queued_for_deletion:
			_queue_free()


# ============================================
# ДВИЖЕНИЕ
# ============================================
func _move(delta: float) -> void:
	global_position += direction * speed * delta

# ============================================
# СТОЛКНОВЕНИЯ
# ============================================
func _on_body_entered(body: Node2D) -> void:
	if _is_queued_for_deletion:
		return
	
	# Проверка на стрелка (врага)
	if not can_hit_shooter and body == shooter:
		return
	
	# Попадание в игрока
	if body.is_in_group("player"):
		_queue_free()
		return

func _on_area_entered(area: Area2D) -> void:
	if _is_queued_for_deletion:
		return
	
	# Попадание в хитбокс игрока
	if area.is_in_group("player_hitbox"):
		var parent = area.get_parent()
		if parent and parent.has_method("on_hit"):
			parent.on_hit(damage, bullet_type)
		_queue_free()

# ============================================
# УДАЛЕНИЕ ПУЛИ
# ============================================
func _queue_free() -> void:
	if _is_queued_for_deletion:
		return
	
	_is_queued_for_deletion = true
	queue_free()


# ============================================
# ПУБЛИЧНЫЕ МЕТОДЫ
# ============================================

func set_direction(new_direction: Vector2) -> void:
	direction = new_direction.normalized()

func set_shooter(new_shooter: Node2D) -> void:
	shooter = new_shooter

func set_speed(new_speed: float) -> void:
	speed = new_speed
