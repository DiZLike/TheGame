extends BaseEnemyProjectile

# ============================================
# ПУЛЯ ТУРЕЛИ
# ============================================
# Быстрая пуля, летящая по прямой.
# Не подвержена гравитации.
# ============================================

func _ready() -> void:
	super._ready()
	
	# Устанавливаем значения по умолчанию
	speed = 300.0
	damage = 1
	bullet_type = "enemy_bullet"
	life_time = 5.0
	auto_delete_on_exit = true
	can_hit_shooter = false
	can_hit_player = true
	can_hit_enemies = false

func _update_visuals(delta: float) -> void:
	"""
	Поворачивает пулю в направлении полета.
	"""
	if direction != Vector2.ZERO:
		rotation = direction.angle()
	
	# Анимация если есть спрайт
	if animated_sprite:
		if animated_sprite.sprite_frames.has_animation("move"):
			animated_sprite.play("move")

func _play_hit_effect(target: Node2D) -> void:
	"""
	Создает эффект попадания пули.
	"""
	var effect_scene = load("res://scenes/effects/bullet_impact.tscn")
	if effect_scene:
		var effect = effect_scene.instantiate()
		get_tree().root.add_child(effect)
		effect.global_position = global_position
