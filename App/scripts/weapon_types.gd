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
	LASER,      # 3 - Лазер
	ROCKET,     # 4 - Ракеты
	HOMING      # 5 - Самонаводящиеся
}

# ============================================
# ПУТИ К СЦЕНАМ ПУЛЬ (каждое оружие - своя сцена)
# ============================================
const BULLET_SCENES = {
	WeaponType.DEFAULT: preload("res://scenes/bullets/player/bullet_default.tscn"),
	WeaponType.MACHINEGUN: preload("res://scenes/bullets/player/bullet_machinegun.tscn"),
	WeaponType.SPREADGUN: preload("res://scenes/bullets/player/bullet_spread.tscn"),
	WeaponType.LASER: preload("res://scenes/bullets/player/bullet_laser.tscn"),
	WeaponType.ROCKET: preload("res://scenes/bullets/player/bullet_rocket.tscn"),
	WeaponType.HOMING: preload("res://scenes/bullets/player/bullet_homing.tscn")
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
		"levels": [
			{"damage": 2, "max_bullets": 3, "shoot_delay": 0.128, "bullet_speed": 300, "spread_count": 1, "spread_angle": 0},
			{"damage": 2, "max_bullets": 3, "shoot_delay": 0.128, "bullet_speed": 325, "spread_count": 1, "spread_angle": 0},
			{"damage": 2, "max_bullets": 4, "shoot_delay": 0.128, "bullet_speed": 350, "spread_count": 1, "spread_angle": 0},
			{"damage": 3, "max_bullets": 4, "shoot_delay": 0.128, "bullet_speed": 1200, "spread_count": 1, "spread_angle": 0}
		],
		"description": "Стандартная пушка",
		"overload_name": "ТОЧКА"
	},
	
	# ------------------------------------------------------------
	# M - ПУЛЕМЁТ
	# ------------------------------------------------------------
	WeaponType.MACHINEGUN: {
		"name": "M - Пулемёт",
		"levels": [
			{"damage": 1, "max_bullets": 999, "shoot_delay": 0.15, "bullet_speed": 300, "spread_count": 1, "spread_angle": 0},
			{"damage": 1, "max_bullets": 999, "shoot_delay": 0.10, "bullet_speed": 350, "spread_count": 1, "spread_angle": 0},
			{"damage": 2, "max_bullets": 999, "shoot_delay": 0.08, "bullet_speed": 450, "spread_count": 1, "spread_angle": 0},
			{"damage": 1, "max_bullets": 999, "shoot_delay": 0.063, "bullet_speed": 450, "spread_count": 1, "spread_angle": 0}
		],
		"description": "Высокая скорострельность",
		"overload_name": "БЕСПОЛЕЗНАЯ ЛЕНТА"
	},
	
	# ------------------------------------------------------------
	# S - СПРЕДГАН
	# ------------------------------------------------------------
	WeaponType.SPREADGUN: {
		"name": "S - Спредган",
		"levels": [
			{"damage": 1, "max_bullets": 2, "shoot_delay": 0.128, "bullet_speed": 350, "spread_count": 2, "spread_angle": 15},
			{"damage": 1, "max_bullets": 3, "shoot_delay": 0.128, "bullet_speed": 400, "spread_count": 3, "spread_angle": 20},
			{"damage": 1, "max_bullets": 5 * 2, "shoot_delay": 0.128, "bullet_speed": 425, "spread_count": 5, "spread_angle": 25},
			{"damage": 1, "max_bullets": 7 * 2, "shoot_delay": 0.05, "bullet_speed": 450, "spread_count": 7, "spread_angle": 30}
		],
		"description": "Веерная стрельба",
		"overload_name": "ФАНТОМНЫЙ ВЕЕР"
	},
	
	# ------------------------------------------------------------
	# L - ЛАЗЕР
	# ------------------------------------------------------------
	WeaponType.LASER: {
		"name": "L - Лазер",
		"levels": [
			{"damage": 3, "max_bullets": 1, "shoot_delay": 0.8, "bullet_speed": 0, "spread_count": 1, "spread_angle": 0, "pierce": 0, "laser_duration": 0.1},
			{"damage": 3, "max_bullets": 1, "shoot_delay": 0.7, "bullet_speed": 0, "spread_count": 1, "spread_angle": 0, "pierce": 1, "laser_duration": 0.15},
			{"damage": 3, "max_bullets": 1, "shoot_delay": 0.6, "bullet_speed": 0, "spread_count": 1, "spread_angle": 0, "pierce": 2, "laser_duration": 0.2},
			{"damage": 4, "max_bullets": 1, "shoot_delay": 1.0, "bullet_speed": 0, "spread_count": 1, "spread_angle": 0, "pierce": 999, "laser_duration": 0.3}
		],
		"description": "Мгновенный луч",
		"overload_name": "РАЗРЫВ РЕАЛЬНОСТИ"
	},
	
	# ------------------------------------------------------------
	# R - РАКЕТЫ
	# ------------------------------------------------------------
	WeaponType.ROCKET: {
		"name": "R - Ракеты",
		"levels": [
			{"damage": 3, "max_bullets": 1, "shoot_delay": 0.7, "bullet_speed": 250, "spread_count": 1, "spread_angle": 0, "explosion_radius": 12},
			{"damage": 3, "max_bullets": 1, "shoot_delay": 0.8, "bullet_speed": 275, "spread_count": 1, "spread_angle": 0, "explosion_radius": 18},
			{"damage": 3, "max_bullets": 1, "shoot_delay": 1.2, "bullet_speed": 300, "spread_count": 1, "spread_angle": 0, "explosion_radius": 23},
			{"damage": 4, "max_bullets": 1, "shoot_delay": 1.5, "bullet_speed": 350, "spread_count": 1, "spread_angle": 0, "explosion_radius": 35}
		],
		"description": "Взрывчатые ракеты",
		"overload_name": "ТАКТИЧЕСКИЙ ГРИБ"
	},
	
	# ------------------------------------------------------------
	# H - САМОНАВОДЯЩИЕСЯ
	# ------------------------------------------------------------
	WeaponType.HOMING: {
		"name": "H - Самонаводящиеся",
		"levels": [
			{"damage": 2, "max_bullets": 2, "flight_time": 3.0, "shoot_delay": 0.4, "bullet_speed": 200, "spread_count": 1, "spread_angle": 0, "homing_strength": 0.06},
			{"damage": 2, "max_bullets": 2, "flight_time": 3.0, "shoot_delay": 0.35, "bullet_speed": 300, "spread_count": 1, "spread_angle": 0, "homing_strength": 0.08},
			{"damage": 2, "max_bullets": 3, "flight_time": 3.0, "shoot_delay": 0.3, "bullet_speed": 400, "spread_count": 1, "spread_angle": 0, "homing_strength": 0.10},
			{"damage": 3, "max_bullets": 4, "flight_time": 3.0, "shoot_delay": 0.3, "bullet_speed": 600, "spread_count": 1, "spread_angle": 0, "homing_strength": 1.0}
		],
		"description": "Самонаводящиеся снаряды",
		"overload_name": "РОЙ"
	}
}
