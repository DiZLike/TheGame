extends BaseEnemyProjectile
class_name FlamethrowerBullet

# ============================================
# ПУЛЯ ОГНЕМЁТЧИКА
# ============================================
# Короткоживущая пуля, имитирующая струю огня.
# Не подвержена гравитации.
# Время жизни определяется длительностью анимации "default".
# СПРАЙТ ПУЛИ ИЗНАЧАЛЬНО СМОТРИТ ВЛЕВО.
# ============================================

func _ready() -> void:
	super._ready()
	
	# Устанавливаем значения по умолчанию
	speed = 200.0
	damage = 1
	bullet_type = "fire"
	life_time = 0.0           # Будет переопределено анимацией
	auto_delete_on_exit = true
	can_hit_shooter = false
	can_hit_player = true
	can_hit_enemies = false
	
	# Запускаем анимацию и получаем её длительность
	_setup_animation_lifetime()


func _setup_animation_lifetime() -> void:
	"""
	Устанавливает время жизни пули равным длительности анимации "default".
	Подключает сигнал окончания анимации для автоматического удаления.
	"""
	if not animated_sprite:
		return
	
	if not animated_sprite.sprite_frames:
		return
	
	if not animated_sprite.sprite_frames.has_animation("default"):
		return
	
	# Вычисляем длительность анимации вручную
	var anim_duration = _get_animation_duration("default")
	
	# Устанавливаем время жизни (небольшой запас на всякий случай)
	life_time = anim_duration + 0.1
	
	# Проигрываем анимацию
	animated_sprite.play("default")
	
	# Подключаемся к сигналу окончания анимации
	if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
		animated_sprite.animation_finished.connect(_on_animation_finished)


func _get_animation_duration(anim_name: String) -> float:
	"""
	Вычисляет полную длительность анимации в секундах.
	Суммирует длительность всех кадров с учётом FPS анимации.
	"""
	var frames = animated_sprite.sprite_frames
	var frame_count = frames.get_frame_count(anim_name)
	
	if frame_count == 0:
		return 1.0  # Защита от деления на ноль
	
	var total_duration: float = 0.0
	var anim_fps = frames.get_animation_speed(anim_name)
	
	if anim_fps <= 0:
		anim_fps = 5.0  # Стандартный FPS по умолчанию
	
	for i in range(frame_count):
		var relative_duration = frames.get_frame_duration(anim_name, i)
		total_duration += relative_duration / anim_fps
	
	return total_duration


func _on_animation_finished() -> void:
	"""
	Вызывается когда анимация "default" полностью проигралась.
	Удаляет пулю.
	"""
	if not _is_queued_for_deletion:
		_on_lifetime_expired()


func _update_visuals(delta: float) -> void:
	"""
	Зеркалит спрайт пули в зависимости от направления полета.
	Спрайт изначально смотрит ВЛЕВО.
	"""
	if not animated_sprite:
		return
	
	# Если летит вправо — зеркалим спрайт
	animated_sprite.flip_h = direction.x > 0
	
	# Анимация если есть
	if animated_sprite.sprite_frames.has_animation("move"):
		animated_sprite.play("move")


func _play_hit_effect(target: Node2D) -> void:
	"""
	Создает эффект попадания огня.
	"""
	var effect_scene = load("res://scenes/effects/fire_impact.tscn")
	if effect_scene:
		var effect = effect_scene.instantiate()
		get_tree().root.add_child(effect)
		effect.global_position = global_position
