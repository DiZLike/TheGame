extends BulletBase
class_name BulletSpread

func _ready() -> void:
	bullet_type = "spread"
	life_time = 5.0  # Автоматическое удаление через 5 секунд
	super()
