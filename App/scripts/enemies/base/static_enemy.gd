extends BaseEnemy
class_name StaticEnemy

# ============================================
# БАЗОВЫЙ КЛАСС ДЛЯ СТАТИЧНЫХ ВРАГОВ
# ============================================
# Для врагов которые стоят на месте и атакуют с интервалом:
# - mg_enemy_1 (бросает фаерболы)
# - turret_1 (стреляет пулями)
# ============================================

# === НАСТРОЙКИ АТАКИ ===
@export_range(0, 10) var attack_interval: float = 2.5      	# Интервал между атаками
@export_range(0, 10) var attack_delay: float = 0.4         	# Задержка между выстрелами в серии
@export_range(0, 10) var attacks_per_cycle: int = 1        	# Количество атак за цикл
@export var attack_on_first_appearance: bool = true  		# Атаковать сразу при появлении

# === СОСТОЯНИЯ АТАКИ ===
var _is_attacking: bool = false               # Активен ли режим атаки
var _is_currently_attacking: bool = false     # Выполняется ли атака сейчас
var _has_attacked_on_first_appearance: bool = false  # Была ли первая атака
var attack_timer: Timer                       # Таймер для интервалов атаки


# ============================================
# НАСТРОЙКА
# ============================================
func _ready() -> void:
	# Устанавливаем параметры ДО вызова родительского _ready()
	_movement_type = "rotate"     # Поворачивается к игроку
	if attacks_per_cycle > 1:
		_attack_pattern = "burst"
		burst_bonus = attacks_per_cycle * 10
	else:
		_attack_pattern = "single"
	super._ready()


func _setup_components() -> void:
	"""
	Настройка компонентов статичного врага.
	"""
	super._setup_components()
	_setup_attack_timer()
	
	# Запускаем idle анимацию если есть
	if animated_sprite:
		animated_sprite.play("idle")

func _setup_attack_timer() -> void:
	"""
	Создает и настраивает таймер для интервалов атаки.
	"""
	attack_timer = Timer.new()
	attack_timer.wait_time = attack_interval
	attack_timer.one_shot = false
	attack_timer.autostart = false
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	add_child(attack_timer)


# ============================================
# УПРАВЛЕНИЕ АКТИВАЦИЕЙ
# ============================================

func _on_activate() -> void:
	"""
	Вызывается когда враг появляется на экране.
	Запускает атаку.
	"""
	if not _has_attacked_on_first_appearance or not _is_attacking:
		_start_attacking()

func _on_deactivate() -> void:
	"""
	Вызывается когда враг покидает экран.
	Останавливает атаку.
	"""
	_stop_attacking()
	
	# Возвращаемся к idle анимации
	if not _is_exploding and animated_sprite:
		if animated_sprite.sprite_frames.has_animation("idle"):
			animated_sprite.play("idle")


# ============================================
# УПРАВЛЕНИЕ АТАКОЙ
# ============================================

func _start_attacking() -> void:
	"""
	Запускает режим атаки.
	"""
	if _is_exploding:
		return
	
	_is_attacking = true
	
	# Запускаем таймер
	if attack_timer.paused:
		attack_timer.paused = false
	else:
		attack_timer.start()
	
	# Если нужно атаковать сразу при появлении
	if attack_on_first_appearance and not _has_attacked_on_first_appearance:
		_perform_attack()
		_has_attacked_on_first_appearance = true

func _stop_attacking() -> void:
	"""
	Останавливает режим атаки.
	"""
	_is_attacking = false
	_is_currently_attacking = false
	if attack_timer:
		attack_timer.paused = true

func _on_attack_timer_timeout() -> void:
	"""
	Вызывается по таймеру для выполнения атаки.
	"""
	if _is_attacking and is_player_valid() and not _is_exploding:
		_perform_attack()


# ============================================
# ВЫПОЛНЕНИЕ АТАКИ
# ============================================

func _perform_attack() -> void:
	"""
	Выполняет цикл атаки.
	Может включать несколько выстрелов с задержкой.
	"""
	if not is_player_valid() or _is_currently_attacking or _is_exploding:
		return
	
	_is_currently_attacking = true
	
	# Проигрываем анимацию атаки
	if animated_sprite:
		if animated_sprite.sprite_frames.has_animation("attack"):
			animated_sprite.play("attack")
	
	# Выполняем нужное количество атак с задержкой
	for i in range(attacks_per_cycle):
		if not _is_attacking or _is_exploding:
			break
		
		# Выполняем одиночную атаку
		call_deferred("_execute_attack")
		
		# Ждем перед следующей атакой
		if i < attacks_per_cycle - 1:
			await get_tree().create_timer(attack_delay).timeout
	
	# Возвращаемся к idle анимации
	if animated_sprite and not _is_exploding:
		await get_tree().create_timer(0.3).timeout
		if not _is_exploding and _is_attacking:
			if animated_sprite.sprite_frames.has_animation("idle"):
				animated_sprite.play("idle")
	
	_is_currently_attacking = false

func _execute_attack() -> void:
	"""
	Выполняет одиночную атаку (создает снаряд).
	ОБЯЗАТЕЛЬНО переопределяется в дочерних классах.
	"""
	pass


# ============================================
# ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
# ============================================

func _face_player() -> void:
	"""
	Поворачивает спрайт лицом к игроку.
	"""
	if not animated_sprite or not is_player_valid():
		return
	
	var direction_to_player = (_player.global_position.x - global_position.x)
	animated_sprite.flip_h = direction_to_player > 0

func _before_explode() -> void:
	"""
	Останавливает атаку перед взрывом.
	"""
	_stop_attacking()
