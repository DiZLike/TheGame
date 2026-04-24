extends BulletBase
class_name BulletSpread

func _ready() -> void:
	auto_delete_on_exit = false
	life_time = 3
	bullet_type = "spread"
	super()
