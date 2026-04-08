extends Area2D

# ============================================
# ОБЫЧНАЯ ПУЛЯ (для D и M)
# ============================================
# Просто летит по прямой, наносит урон при попадании

class_name BulletDefault

# Параметры (устанавливаются WeaponManager)
var direction: Vector2 = Vector2.RIGHT
var shooter: Node2D = null
var speed: float = 300.0
var damage: int = 1

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

# ============================================
# СТОЛКНОВЕНИЯ - только триггер, урон наносит враг
# ============================================
func _on_body_entered(body: Node2D) -> void:
	if body == shooter:
		return
	# Если это враг - передаём ему информацию о попадании
	if body.is_in_group("enemy"):
		if body.has_method("on_hit"):
			body.on_hit(damage, "default")
		WeaponManager.remove_bullet()
		queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	WeaponManager.remove_bullet()
	queue_free()
