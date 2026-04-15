extends MovingEnemy

# ============================================
# ШКОЛЬНИК - ДВИЖУЩИЙСЯ ВРАГ
# ============================================

func _ready() -> void:
	# Устанавливаем параметры ДО вызова родительского _ready()
	health = 1
	_attack_pattern = "none"      # Только контактный урон
	_movement_type = "move"       # Ходит и прыгает
	
	super._ready()
	
	# Остальные параметры
	move_speed = 100.0
	jump_velocity = -175.0
	explosion_force = 50.0
