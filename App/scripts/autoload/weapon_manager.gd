extends Node

# ============================================
# НАЗНАЧЕНИЕ: Управление оружием игрока
# ============================================

const WeaponsType = preload("res://scripts/weapon_types.gd")

# Сигналы для UI
signal weapon_changed(weapon_type: int, level: int)
signal weapon_upgraded(weapon_type: int, new_level: int)

# Текущее состояние
var current_weapon: int = WeaponsType.WeaponType.DEFAULT
var current_level: int = 0                        # 0-3
var _current_weapon_data: Dictionary
var _current_shooter: Node2D = null
var _can_shoot: bool = true
var _shoot_timer: Timer = null

# Лимит пуль на экране
var _active_bullets: Array = []
var _bullet_count: int = 0

func _ready() -> void:
	_update_weapon_cache()
	
	_shoot_timer = Timer.new()
	_shoot_timer.one_shot = true
	_shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	add_child(_shoot_timer)

func _update_weapon_cache() -> void:
	var weapon_info = WeaponsType.WEAPON_DATA[current_weapon]
	if current_level >= weapon_info["levels"].size():
		current_level = weapon_info["levels"].size() - 1
	_current_weapon_data = weapon_info["levels"][current_level].duplicate()

# ============================================
# ОСНОВНОЙ МЕТОД СТРЕЛЬБЫ
# ============================================
func try_shoot(shooter: Node2D, shoot_point: Marker2D, direction: Vector2) -> bool:
	if not _can_shoot:
		return false
	
	var max_bullets = _current_weapon_data["max_bullets"]
	if max_bullets != 999 and _bullet_count >= max_bullets:
		return false
	
	_current_shooter = shooter
	_shoot(shoot_point, direction)
	_start_shoot_cooldown()
	return true

func _shoot(shoot_point: Marker2D, direction: Vector2) -> void:
	var weapon = _current_weapon_data
	var spread_count = weapon.get("spread_count", 1)
	var spread_angle = weapon.get("spread_angle", 0.0)
	
	if spread_count <= 1 or spread_angle <= 0.0:
		_spawn_bullet(shoot_point.global_position, direction, weapon)
	else:
		_spread_shoot(shoot_point.global_position, direction, weapon)

func _spread_shoot(origin: Vector2, base_direction: Vector2, weapon: Dictionary) -> void:
	var spread_count = weapon["spread_count"]
	var spread_angle_rad = deg_to_rad(weapon["spread_angle"])
	var start_angle = -spread_angle_rad * 0.5
	var step = spread_angle_rad / (spread_count - 1) if spread_count > 1 else 0.0
	
	for i in range(spread_count):
		var angle = start_angle + step * i
		var bullet_direction = base_direction.rotated(angle)
		_spawn_bullet(origin, bullet_direction, weapon)

func _spawn_bullet(origin: Vector2, direction: Vector2, weapon: Dictionary) -> void:
	# Получаем нужную сцену пули в зависимости от типа оружия
	var bullet_scene = WeaponsType.BULLET_SCENES[current_weapon]
	var bullet = bullet_scene.instantiate()
	
	bullet.global_position = origin
	bullet.direction = direction
	bullet.shooter = _current_shooter
	
	# Передаём параметры оружия в пулю
	bullet.damage = weapon["damage"]
	bullet.speed = weapon["bullet_speed"]
	
	# Дополнительные параметры для специальных типов
	if weapon.has("explosion_radius"):
		bullet.explosion_radius = weapon["explosion_radius"]
	if weapon.has("homing_strength"):
		bullet.homing_strength = weapon["homing_strength"]
	if weapon.has("flight_time"):
		bullet.flight_time = weapon["flight_time"]
	if weapon.has("pierce"):
		bullet.pierce_count = weapon["pierce"]
	if weapon.has("laser_duration"):
		bullet.laser_duration = weapon["laser_duration"]
	
	# Отслеживание лимита пуль
	_bullet_count += 1
	
	get_tree().current_scene.add_child(bullet)

func remove_bullet() -> void:
	_bullet_count -= 1
	print("Пуля удалена: " + str(_bullet_count))

func _start_shoot_cooldown() -> void:
	_can_shoot = false
	_shoot_timer.wait_time = _current_weapon_data["shoot_delay"]
	_shoot_timer.start()

func _on_shoot_timer_timeout() -> void:
	_can_shoot = true

# ============================================
# ПУБЛИЧНЫЕ МЕТОДЫ
# ============================================
func change_weapon(weapon_type: int) -> void:
	current_weapon = weapon_type
	current_level = 0
	_update_weapon_cache()
	weapon_changed.emit(current_weapon, current_level)

func upgrade_weapon() -> bool:
	var weapon_info = WeaponsType.WEAPON_DATA[current_weapon]
	var max_level = weapon_info["levels"].size() - 1
	
	if current_level < max_level:
		current_level += 1
		_update_weapon_cache()
		weapon_upgraded.emit(current_weapon, current_level)
		return true
	return false

func get_current_weapon_data() -> Dictionary:
	return _current_weapon_data.duplicate()

func get_current_level() -> int:
	return current_level

func is_overloaded() -> bool:
	var weapon_info = WeaponsType.WEAPON_DATA[current_weapon]
	return current_level == weapon_info["levels"].size() - 1
