extends Area2D

# ============================================
# ПУЛЯ ДЛЯ СПРЕДГАНА
# ============================================
# Та же логика, что и у обычной пули, но может иметь свой визуал

class_name BulletSpread

var direction: Vector2 = Vector2.RIGHT
var shooter: Node2D = null
var speed: float = 300.0
var damage: int = 1

func _ready() -> void:
	await get_tree().create_timer(5.0).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body == shooter:
		return
	
	if body.is_in_group("enemy"):
		if body.has_method("on_hit"):
			body.on_hit(damage, "spread")
			WeaponManager.remove_bullet()
		queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	WeaponManager.remove_bullet()
