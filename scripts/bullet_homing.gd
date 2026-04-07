extends Area2D

# ============================================
# САМОНАВОДЯЩАЯСЯ РАКЕТА
# ============================================

class_name BulletHoming

# Параметры
var speed: float = 300.0
var damage: int = 2
var flight_time : float = 3
var homing_strength: float = 0.05
var search_radius: float = 4000.0
var spawn_deviation: float = 10.0  # Максимальный угол отклонения при спавне (в градусах)
var explosion_radius: float = 15.0
var _has_exploded: bool = false


var shooter: Node2D = null

# Сеттер для direction - автоматически поворачивает спрайт
var direction: Vector2 = Vector2.RIGHT:
	set(value):
		direction = value
		if $AnimatedSprite2D:
			$AnimatedSprite2D.rotation = direction.angle()

func _ready() -> void:
	# Применяем случайное отклонение к направлению при спавне
	_apply_spawn_deviation()
	
	# Стартуем таймер на уничтожение
	await get_tree().create_timer(flight_time).timeout
	call_deferred("_explode")

# ============================================
# СЛУЧАЙНОЕ ОТКЛОНЕНИЕ ПРИ СПАВНЕ
# ============================================
func _apply_spawn_deviation() -> void:
	# Генерируем случайный угол отклонения (в радианах)
	var deviation_angle = deg_to_rad(randf_range(-spawn_deviation, spawn_deviation))
	
	# Поворачиваем текущее направление на случайный угол
	var new_direction = direction.rotated(deviation_angle)
	direction = new_direction.normalized()
	
func _explode() -> void:
	if _has_exploded:
		return
	
	_has_exploded = true
	
	var explosion_scene = preload("res://scenes/effects/explosion_01.tscn")
	var explosion = explosion_scene.instantiate() as Explosion
	
	explosion.global_position = global_position
	explosion.damage = damage  # Просто передаём число
	explosion.explosion_radius = explosion_radius
	explosion.shooter = shooter
	
	get_tree().current_scene.add_child(explosion)
	WeaponManager.remove_bullet()
	queue_free()

func _physics_process(delta: float) -> void:
	# Поиск ближайшего врага
	var target = _find_nearest_enemy()
	
	if target:
		# Вектор к цели
		var to_target = (target.global_position - global_position).normalized()
		# Плавный поворот направления (сеттер сработает автоматически)
		direction = direction.lerp(to_target, homing_strength).normalized()
	
	# Движение
	global_position += direction * speed * delta

# ============================================
# ПОИСК БЛИЖАЙШЕГО ВРАГА
# ============================================
func _find_nearest_enemy() -> Node2D:
	var nearest = null
	var nearest_dist = search_radius
	
	for enemy in get_tree().get_nodes_in_group("enemy"):
		var dist = global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	
	return nearest

# ============================================
# СТОЛКНОВЕНИЯ
# ============================================
func _on_body_entered(body: Node2D) -> void:
	if body == shooter:
		return
	
	if body.is_in_group("enemy"):
		if body.has_method("on_hit"):
			body.on_hit(damage, "homing")
		call_deferred("_explode")
