extends Node

# ============================================
# НАЗНАЧЕНИЕ: Управление оружием игрока
# ============================================

const WeaponsType = preload("res://scripts/weapon_types.gd")

# Сигналы для UI
signal weapon_changed(weapon_type: WeaponsType.WeaponType, level: int)
signal weapon_upgraded(weapon_type: WeaponsType.WeaponType, new_level: int)
signal ammo_changed(current_ammo: int, max_ammo: int)
signal reload_started(reload_time: float)
signal reload_finished()

# Текущее состояние
var current_weapon: WeaponsType.WeaponType = WeaponsType.WeaponType.DEFAULT
var current_level: int = 0                        # 0-3
var _current_weapon_data: Dictionary
var _current_weapon_info: Dictionary
var _current_shooter: Node2D = null

# Система стрельбы и перезарядки
var _can_shoot: bool = true
var _is_reloading: bool = false
var _current_ammo: int = 0
var _shoot_timer: Timer = null
var _reload_timer: Timer = null

func _ready() -> void:
	_update_weapon_cache()
	
	_shoot_timer = Timer.new()
	_shoot_timer.one_shot = true
	_shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	add_child(_shoot_timer)
	
	_reload_timer = Timer.new()
	_reload_timer.one_shot = true
	_reload_timer.timeout.connect(_on_reload_timer_timeout)
	add_child(_reload_timer)
	
	# Инициализируем патроны
	_current_ammo = _current_weapon_data.get("magazine_size", 3)
	ammo_changed.emit(_current_ammo, _current_weapon_data.get("magazine_size", 3))

func _update_weapon_cache() -> void:
	_current_weapon_info = WeaponsType.WEAPON_DATA[current_weapon]
	if current_level >= _current_weapon_info["levels"].size():
		current_level = _current_weapon_info["levels"].size() - 1
	_current_weapon_data = _current_weapon_info["levels"][current_level].duplicate()

# ============================================
# ОСНОВНОЙ МЕТОД СТРЕЛЬБЫ
# ============================================
func try_shoot(shooter: Node2D, shoot_point: Marker2D, direction: Vector2) -> bool:
	if not _can_shoot or _is_reloading:
		return false
	
	if _current_ammo <= 0:
		_start_reload()
		return false
	
	_current_shooter = shooter
	_shoot(shoot_point, direction)
	
	_current_ammo -= 1
	ammo_changed.emit(_current_ammo, _current_weapon_data.get("magazine_size", 3))
	
	_start_shoot_cooldown()
	
	# Автоматическая перезарядка если патроны кончились
	if _current_ammo <= 0:
		_start_reload()
	
	return true

func _shoot(shoot_point: Marker2D, direction: Vector2) -> void:
	var weapon = _current_weapon_data
	var sound_file: String = _current_weapon_info.get("sound")
	var sound: AudioStream = load(sound_file)
	var spread_count = weapon.get("spread_count", 1)
	var spread_angle = weapon.get("spread_angle", 0.0)
	AudioManager.play_sfx(sound)
	
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
	
	# Параметры для тесла-пушки
	if current_weapon == WeaponsType.WeaponType.TESLA:
		if weapon.has("chain_count"):
			bullet.chain_count = weapon["chain_count"]
		if weapon.has("chain_range"):
			bullet.chain_range = weapon["chain_range"]
		if weapon.has("chain_damage_falloff"):
			bullet.chain_damage_falloff = weapon["chain_damage_falloff"]
		if weapon.has("chain_delay"):
			bullet.chain_delay = weapon["chain_delay"]
	
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
	
	get_tree().current_scene.add_child(bullet)

func _start_shoot_cooldown() -> void:
	_can_shoot = false
	_shoot_timer.wait_time = _current_weapon_data["shoot_delay"]
	_shoot_timer.start()

func _on_shoot_timer_timeout() -> void:
	_can_shoot = true

# ============================================
# СИСТЕМА ПЕРЕЗАРЯДКИ
# ============================================
func _start_reload() -> void:
	if _is_reloading:
		return
	
	_is_reloading = true
	_can_shoot = false
	
	var reload_time = _current_weapon_data.get("reload_time", 1.0)
	_reload_timer.wait_time = reload_time
	_reload_timer.start()
	
	reload_started.emit(reload_time)

func _on_reload_timer_timeout() -> void:
	_current_ammo = _current_weapon_data.get("magazine_size", 3)
	_is_reloading = false
	_can_shoot = true
	
	ammo_changed.emit(_current_ammo, _current_weapon_data.get("magazine_size", 3))
	reload_finished.emit()

func reload() -> void:
	"""Принудительная перезарядка (по нажатию кнопки)"""
	if not _is_reloading and _current_ammo < _current_weapon_data.get("magazine_size", 3):
		_start_reload()

# ============================================
# ПУБЛИЧНЫЕ МЕТОДЫ
# ============================================
func change_weapon(weapon_type: int) -> void:
	current_weapon = weapon_type
	if current_weapon == WeaponsType.WeaponType.DEFAULT:
		InventoryManager.add_item_by_id("weapon_d")
	if current_weapon == WeaponsType.WeaponType.MACHINEGUN:
		InventoryManager.add_item_by_id("weapon_m")
	if current_weapon == WeaponsType.WeaponType.SPREADGUN:
		InventoryManager.add_item_by_id("weapon_s")
	if current_weapon == WeaponsType.WeaponType.ROCKET:
		InventoryManager.add_item_by_id("weapon_r")
	if current_weapon == WeaponsType.WeaponType.HOMING:
		InventoryManager.add_item_by_id("weapon_h")
	if current_weapon == WeaponsType.WeaponType.LASER:
		InventoryManager.add_item_by_id("weapon_l")
	if current_weapon == WeaponsType.WeaponType.TESLA:
		InventoryManager.add_item_by_id("weapon_t")
	
	current_level = 0
	_update_weapon_cache()
	
	# Сброс состояния при смене оружия
	_is_reloading = false
	_reload_timer.stop()
	_shoot_timer.stop()
	_can_shoot = true
	
	_current_ammo = _current_weapon_data.get("magazine_size", 3)
	
	weapon_changed.emit(current_weapon, current_level)
	ammo_changed.emit(_current_ammo, _current_weapon_data.get("magazine_size", 3))

func upgrade_weapon() -> bool:
	var weapon_info = WeaponsType.WEAPON_DATA[current_weapon]
	var max_level = weapon_info["levels"].size() - 1
	
	if current_level < max_level:
		current_level += 1
		_update_weapon_cache()
		
		# При улучшении пополняем патроны
		_current_ammo = _current_weapon_data.get("magazine_size", 3)
		ammo_changed.emit(_current_ammo, _current_weapon_data.get("magazine_size", 3))
		
		weapon_upgraded.emit(current_weapon, current_level)
		return true
	return false

func get_current_weapon_data() -> Dictionary:
	return _current_weapon_data.duplicate()

func get_current_weapon() -> WeaponsType.WeaponType:
	return current_weapon

func get_current_level() -> int:
	return current_level

func get_current_ammo() -> int:
	return _current_ammo

func get_max_ammo() -> int:
	return _current_weapon_data.get("magazine_size", 3)

func is_reloading() -> bool:
	return _is_reloading

func is_overloaded() -> bool:
	var weapon_info = WeaponsType.WEAPON_DATA[current_weapon]
	return current_level == weapon_info["levels"].size() - 1
