extends Node
class_name WeaponTypes
# ============================================
# НАЗНАЧЕНИЕ: Хранилище данных об оружии
# ============================================

# ============================================
# ТИПЫ ОРУЖИЯ
# ============================================
enum WeaponType {
	DEFAULT,    # 0 - Стандартная пушка
	MACHINEGUN, # 1 - Пулемёт
	SPREADGUN,  # 2 - Спредган
	ROCKET,     # 3 - Ракеты
	HOMING,     # 4 - Самонаводящиеся
	TESLA		# 5 - Тесла
}

# ============================================
# ПУТИ К СЦЕНАМ ПУЛЬ (каждое оружие - своя сцена)
# ============================================
const BULLET_SCENES = {
	WeaponType.DEFAULT: preload("res://scenes/bullets/player/bullet_default.tscn"),
	WeaponType.MACHINEGUN: preload("res://scenes/bullets/player/bullet_machinegun.tscn"),
	WeaponType.SPREADGUN: preload("res://scenes/bullets/player/bullet_spread.tscn"),
	WeaponType.ROCKET: preload("res://scenes/bullets/player/bullet_rocket.tscn"),
	WeaponType.HOMING: preload("res://scenes/bullets/player/bullet_homing.tscn"),
	WeaponType.TESLA: preload("res://scenes/bullets/player/bullet_tesla.tscn"),
}

# ============================================
# ДАННЫЕ ОРУЖИЯ ПО УРОВНЯМ
# ============================================
const WEAPON_DATA = {
	# ------------------------------------------------------------
	# D - СТАНДАРТНАЯ ПУШКА
	# ------------------------------------------------------------
	WeaponType.DEFAULT: {
		"name": "D - Стандартная пушка",
		"sound": "res://data/audio/sounds/player_weapon/weapon_default.ogg",
		"levels": [
			{"damage": 20, "magazine_size": 3, "reload_time": 0.8, "shoot_delay": 0.128, "bullet_speed": 325, "spread_count": 1, "spread_angle": 0},
			{"damage": 20, "magazine_size": 3, "reload_time": 0.6, "shoot_delay": 0.128, "bullet_speed": 350, "spread_count": 1, "spread_angle": 0},
			{"damage": 20, "magazine_size": 4, "reload_time": 0.45, "shoot_delay": 0.128, "bullet_speed": 375, "spread_count": 1, "spread_angle": 0},
			{"damage": 30, "magazine_size": 4, "reload_time": 0.4, "shoot_delay": 0.128, "bullet_speed": 1200, "spread_count": 1, "spread_angle": 0}
		],
		"description": "Стандартная пушка",
		"overload_name": "ТОЧКА"
	},
	
	# ------------------------------------------------------------
	# M - ПУЛЕМЁТ
	# ------------------------------------------------------------
	WeaponType.MACHINEGUN: {
		"name": "M - Пулемёт",
		"sound": "res://data/audio/sounds/player_weapon/weapon_machinegun.ogg",
		"levels": [
			{"damage": 10, "magazine_size": 30, "reload_time": 3, "shoot_delay": 0.15, "bullet_speed": 300, "spread_count": 1, "spread_angle": 0},
			{"damage": 10, "magazine_size": 35, "reload_time": 3, "shoot_delay": 0.10, "bullet_speed": 350, "spread_count": 1, "spread_angle": 0},
			{"damage": 20, "magazine_size": 40, "reload_time": 1.1, "shoot_delay": 0.08, "bullet_speed": 450, "spread_count": 1, "spread_angle": 0},
			{"damage": 15, "magazine_size": 50, "reload_time": 0.9, "shoot_delay": 0.063, "bullet_speed": 450, "spread_count": 1, "spread_angle": 0}
		],
		"description": "Высокая скорострельность",
		"overload_name": "БЕСПОЛЕЗНАЯ ЛЕНТА"
	},
	
	# ------------------------------------------------------------
	# S - СПРЕДГАН
	# ------------------------------------------------------------
	WeaponType.SPREADGUN: {
		"name": "S - Спредган",
		"sound": "res://data/audio/sounds/player_weapon/weapon_spread.ogg",
		"levels": [
			{"damage": 10, "magazine_size": 1, "reload_time": 0.6, "shoot_delay": 0.128, "bullet_speed": 350, "spread_count": 3, "spread_angle": 15},
			{"damage": 10, "magazine_size": 2, "reload_time": 0.55, "shoot_delay": 0.128, "bullet_speed": 400, "spread_count": 3, "spread_angle": 20},
			{"damage": 10, "magazine_size": 2, "reload_time": 0.5, "shoot_delay": 0.128, "bullet_speed": 425, "spread_count": 5, "spread_angle": 25},
			{"damage": 10, "magazine_size": 3, "reload_time": 0.4, "shoot_delay": 0.05, "bullet_speed": 450, "spread_count": 7, "spread_angle": 30}
		],
		"description": "Веерная стрельба",
		"overload_name": "ФАНТОМНЫЙ ВЕЕР"
	},
	
	# ------------------------------------------------------------
	# R - РАКЕТЫ
	# ------------------------------------------------------------
	WeaponType.ROCKET: {
		"name": "R - Ракеты",
		"sound": "res://data/audio/sounds/player_weapon/weapon_rocket.ogg",
		"levels": [
			{"damage": 30, "magazine_size": 1, "reload_time": 0.7, "shoot_delay": 0.7, "bullet_speed": 300, "spread_count": 1, "spread_angle": 0, "explosion_radius": 12},
			{"damage": 30, "magazine_size": 2, "reload_time": 0.8, "shoot_delay": 0.7, "bullet_speed": 350, "spread_count": 1, "spread_angle": 0, "explosion_radius": 18},
			{"damage": 30, "magazine_size": 2, "reload_time": 1.2, "shoot_delay": 0.7, "bullet_speed": 350, "spread_count": 1, "spread_angle": 0, "explosion_radius": 23},
			{"damage": 40, "magazine_size": 2, "reload_time": 1.5, "shoot_delay": 0.7, "bullet_speed": 400, "spread_count": 1, "spread_angle": 0, "explosion_radius": 35}
		],
		"description": "Взрывчатые ракеты",
		"overload_name": "ТАКТИЧЕСКИЙ ГРИБ"
	},
	
	# ------------------------------------------------------------
	# H - САМОНАВОДЯЩИЕСЯ
	# ------------------------------------------------------------
	WeaponType.HOMING: {
		"name": "H - Самонаводящиеся",
		"sound": "res://data/audio/sounds/player_weapon/weapon_rocket.ogg",
		"levels": [
			{"damage": 20, "magazine_size": 2, "reload_time": 2, "flight_time": 2.0, "shoot_delay": 0.4, "bullet_speed": 250, "spread_count": 1, "spread_angle": 0, "homing_strength": 0.06},
			{"damage": 20, "magazine_size": 2, "reload_time": 1.8, "flight_time": 2.0, "shoot_delay": 0.35, "bullet_speed": 300, "spread_count": 1, "spread_angle": 0, "homing_strength": 0.08},
			{"damage": 20, "magazine_size": 3, "reload_time": 1.6, "flight_time": 2.0, "shoot_delay": 0.3, "bullet_speed": 400, "spread_count": 1, "spread_angle": 0, "homing_strength": 0.10},
			{"damage": 30, "magazine_size": 4, "reload_time": 1.5, "flight_time": 2.0, "shoot_delay": 0.3, "bullet_speed": 600, "spread_count": 1, "spread_angle": 0, "homing_strength": 1.0}
		],
		"description": "Самонаводящиеся снаряды",
		"overload_name": "РОЙ"
	},
	WeaponType.TESLA: {
		"sound": "res://data/audio/sounds/player_weapon/weapon_laser.ogg",
		"levels": [
			{
				"damage": 15,
				"bullet_speed": 0,
				"shoot_delay": 0.8,
				"magazine_size": 1,
				"reload_time": 1.5,
				"chain_count": 3,
				"chain_range": 200.0,
				"chain_damage_falloff": 0.7,
				"chain_delay": 0.08
			},
			# Уровень 2
			{
				"damage": 20,
				"bullet_speed": 0,
				"shoot_delay": 0.7,
				"magazine_size": 1,
				"reload_time": 1.3,
				"chain_count": 4,
				"chain_range": 250.0,
				"chain_damage_falloff": 0.75,
				"chain_delay": 0.06
			},
			# Уровень 3
			{
				"damage": 25,
				"bullet_speed": 0,
				"shoot_delay": 0.6,
				"magazine_size": 1,
				"reload_time": 1.0,
				"chain_count": 5,
				"chain_range": 300.0,
				"chain_damage_falloff": 0.8,
				"chain_delay": 0.05
			}
		]
	}
}
