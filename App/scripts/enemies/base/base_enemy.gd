extends CharacterBody2D
class_name BaseEnemy

# ============================================
# БАЗОВЫЙ КЛАСС ДЛЯ ВСЕХ ВРАГОВ
# ============================================
# Содержит общую логику для всех типов врагов:
# - Здоровье и получение урона
# - Система очков (автоматический расчёт)
# - Взрыв при смерти (с разной силой от разных пуль)
# - Отслеживание игрока
# - Активация/деактивация при входе/выходе с экрана
# ============================================

# === БАЗОВЫЕ ХАРАКТЕРИСТИКИ ===
@export var health: int = 100              # Здоровье врага
@export var score: int = 0                 # Очки за уничтожение (0 = авто-расчёт)
@export var explosion_force: float = 50.0  # Базовая сила взрыва (может меняться от типа пули)
@export var auto_remove: bool = false

# === НАСТРОЙКИ БАЛАНСА ===
const SCORE_BASE: int = 50                     # Базовая награда
const SCORE_HP_MULTIPLIER: float = 1.0         # Множитель за каждое очко здоровья
const SCORE_ATTACK_PATTERN_BONUS: Dictionary = {
	"none": 0,                                  # Нет атаки
	"single": 50,                               # Одиночный выстрел
	"burst": 100,                               # Серия выстрелов (турель)
	"spread": 150,                              # Веер/разброс
	"homing": 200,                              # Самонаводящиеся
}
const SCORE_MOVEMENT_BONUS: Dictionary = {
	"none": 0,
	"fixed_rotate": 30,
	"rotate": 50,                               # Поворачивается к игроку
	"move": 80,                                 # Ходит по платформам
	"fly": 120,                                  # Летает
}
const SCORE_ROUND_STEP: int = 10              # Шаг округления
var burst_bonus: int = 0

# === ХАРАКТЕРИСТИКИ ДЛЯ РАСЧЁТА (переопределяются в дочерних классах) ===
var _attack_pattern: String = "none"           # "none", "single", "burst", "spread", "homing"
var _movement_type: String = "none"            # "none", "rotate", "move", "fly"

# === КОМПОНЕНТЫ ===
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visible_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
var animated_sprite: AnimatedSprite2D

# === СОСТОЯНИЯ ===
var _is_active: bool = false               # Активен ли враг (на экране)
var _is_exploding: bool = false            # В процессе взрыва
var _player: Node2D = null                 # Ссылка на игрока
var _last_bullet_type: String = ""         # Тип пули, которой убили (для расчета силы взрыва)

# === РЕСУРСЫ ===
var pixel_explosion_scene: PackedScene = preload("res://scenes/effects/pixel_explosion.tscn")
var hit_sound: AudioStream = preload("res://data/audio/sounds/enemy/enemy_hit.wav")
var death_sound: AudioStream = preload("res://data/audio/sounds/enemy/death1.wav")
var shot_sound: AudioStream = preload("res://data/audio/sounds/enemy/shot1.wav")


# ============================================
# ЖИЗНЕННЫЙ ЦИКЛ
# ============================================
func _ready() -> void:
	_initialize()
	_setup_components()
	_connect_signals()
	
	# Попытаться найти спрайт, если он еще не установлен дочерним классом
	if not animated_sprite:
		if has_node("MainSprite2D"):
			animated_sprite = $MainSprite2D
	
	# Отложенный расчёт, чтобы дочерние классы успели установить параметры
	call_deferred("_calculate_and_set_score")

func _initialize() -> void:
	"""
	Инициализация врага. Находит игрока в сцене.
	Переопределяется в дочерних классах для дополнительной инициализации.
	"""
	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		_player = players[0]

func _setup_components() -> void:
	"""
	Настройка компонентов врага.
	Переопределяется в дочерних классах.
	"""
	pass

func _connect_signals() -> void:
	"""
	Подключение сигналов видимости на экране.
	"""
	if visible_notifier:
		visible_notifier.screen_entered.connect(_on_screen_entered)
		visible_notifier.screen_exited.connect(_on_screen_exited)


# ============================================
# РАСЧЁТ НАГРАДЫ
# ============================================

func _calculate_and_set_score() -> void:
	"""
	Рассчитывает и устанавливает награду, если она не задана вручную.
	"""
	if score == 0:
		score = calculate_score()
		print("=== " + name + " Score Calculation ===")
		print("  Raw total: " + str(SCORE_BASE + health * SCORE_HP_MULTIPLIER + 
			  SCORE_ATTACK_PATTERN_BONUS.get(_attack_pattern, 0) + 
			  SCORE_MOVEMENT_BONUS.get(_movement_type, 0)))
		print("  Final score: " + str(score))
		print("==============================")

func calculate_score() -> int:
	"""
	Рассчитывает награду за врага на основе его параметров.
	Учитывает только HP, паттерн атаки и тип движения.
	"""
	var raw_score: float = SCORE_BASE
	
	# Бонус за здоровье (чем дольше живёт — тем опаснее)
	raw_score += health * SCORE_HP_MULTIPLIER
	
	# Бонус за сложность паттерна атаки
	raw_score += SCORE_ATTACK_PATTERN_BONUS.get(_attack_pattern, 0)
	raw_score += burst_bonus
	
	# Бонус за подвижность (сложнее попасть)
	raw_score += SCORE_MOVEMENT_BONUS.get(_movement_type, 0)
	
	return _round_to_step(int(raw_score), SCORE_ROUND_STEP)

func _round_to_step(value: int, step: int) -> int:
	"""Округляет значение до ближайшего числа, кратного step."""
	return int(round(float(value) / step) * step)


# ============================================
# УПРАВЛЕНИЕ АКТИВАЦИЕЙ (ВХОД/ВЫХОД С ЭКРАНА)
# ============================================

func _on_screen_entered() -> void:
	"""
	Вызывается когда враг появляется на экране.
	Активирует врага и запускает его поведение.
	"""
	_is_active = true
	_on_activate()

func _on_screen_exited() -> void:
	"""
	Вызывается когда враг покидает экран.
	Деактивирует врага для экономии ресурсов.
	"""
	_is_active = false
	_on_deactivate()

func _on_activate() -> void:
	"""
	Вызывается при активации врага.
	Переопределяется в дочерних классах.
	"""
	pass

func _on_deactivate() -> void:
	"""
	Вызывается при деактивации врага.
	Переопределяется в дочерних классах.
	"""
	if not auto_remove:
		return
	await get_tree().create_timer(3).timeout
	if not _is_active:
		queue_free()
	pass


# ============================================
# СИСТЕМА УРОНА И СМЕРТИ
# ============================================

func on_hit(damage: int, bullet_type: String) -> void:
	"""
	Обработка получения урона.
	Вызывается когда в врага попадает пуля или снаряд.
	
	Параметры:
	- damage: количество урона
	- bullet_type: тип пули ("rocket", "homing", "enemy_bullet", "fire" и т.д.)
	"""
	health -= damage
	print("Получен урон")
	print(damage)
	
	if health > 0:
		# Враг еще жив - проигрываем звук попадания
		_on_damaged(bullet_type)
		return
	
	if _is_exploding:
		# Уже в процессе смерти
		return
	
	# Сохраняем тип пули для расчета силы взрыва
	_last_bullet_type = bullet_type
	
	# Враг погибает
	_on_death(bullet_type)

func _on_damaged(bullet_type: String) -> void:
	"""
	Вызывается при получении урона (но не смерти).
	Проигрывает звук попадания.
	"""
	AudioManager.play_sfx(hit_sound, 1, 1, global_position)

func _on_death(bullet_type: String) -> void:
	"""
	Обработка смерти врага.
	Начисляет очки и запускает взрыв.
	"""
	if not bullet_type == "terrain_deadly":
		ScoreManager.add_score(score)
	_is_exploding = true
	AudioManager.play_sfx(death_sound, 1, 1, global_position)
	# Даем дочернему классу возможность выполнить действия перед взрывом
	_before_explode()
	
	# Запускаем взрыв
	call_deferred("_explode")

func _before_explode() -> void:
	"""
	Вызывается перед началом взрыва.
	Переопределяется в дочерних классах для остановки атак и т.д.
	"""
	pass

func _explode() -> void:
	"""
	Создает эффект взрыва и уничтожает врага.
	"""
	# Создаем взрыв
	var explosion = pixel_explosion_scene.instantiate()
	get_tree().root.add_child(explosion)
	
	# Определяем силу взрыва в зависимости от типа пули
	var force = _calculate_explosion_force()
	
	# Запускаем взрыв от спрайта врага
	explosion.explode_from_animated_sprite(animated_sprite, global_position, force)
	
	# Скрываем врага
	visible = false
	collision_shape.disabled = true
	if animated_sprite:
		animated_sprite.visible = false
	
	# Удаляем через небольшую задержку
	await get_tree().create_timer(0.5).timeout
	queue_free()

func _calculate_explosion_force() -> float:
	"""
	Вычисляет силу взрыва в зависимости от типа пули.
	Переопределяется в дочерних классах если нужна другая логика.
	"""
	match _last_bullet_type:
		"rocket":
			return 800.0
		"homing":
			return 500.0
		_:
			return explosion_force


# ============================================
# ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
# ============================================

func _find_player() -> Node2D:
	"""
	Находит игрока в сцене.
	Возвращает ссылку на игрока или null.
	"""
	if _player and is_instance_valid(_player):
		return _player
	
	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		_player = players[0]
	
	return _player

func is_player_valid() -> bool:
	"""
	Проверяет, существует ли еще игрок.
	"""
	return _player != null and is_instance_valid(_player)
