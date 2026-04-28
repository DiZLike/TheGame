extends MovingEnemy
class_name Schoolboy

# ============================================
# ШКОЛЬНИК - ДВИЖУЩИЙСЯ ВРАГ
# ============================================

func _configure_stats() -> void:
	health = 1
	_attack_pattern = "none"      # Только контактный урон
