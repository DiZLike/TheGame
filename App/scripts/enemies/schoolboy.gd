extends MovingEnemy
class_name Schoolboy

# ============================================
# ШКОЛЬНИК - ДВИЖУЩИЙСЯ ВРАГ
# ============================================

func _ready() -> void:
	# Устанавливаем параметры ДО вызова родительского _ready()
	health = 1
	_attack_pattern = "none"      # Только контактный урон
	_movement_type = "move"       # Ходит и прыгает
	
	super._ready()
