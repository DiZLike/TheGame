extends Area2D
class_name Explosion

# Параметры
var damage: int = 3
var explosion_radius: float = 50.0
var shooter: Node2D = null
var excluded_target: Node2D = null

@onready var _original_radius: float = 12.0
@onready var animation: AnimatedSprite2D = $ExplosionAnimation
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

@onready var sound: AudioStream = preload("res://data/audio/sounds/explosions/rocket_explosion.ogg")

func _ready() -> void:
	AudioManager.play_sfx(sound, 1, global_position)
	# Настройка радиус
	if collision_shape and collision_shape.shape is CircleShape2D:
		_original_radius = (collision_shape.shape as CircleShape2D).radius
	
	var target_scale = explosion_radius / _original_radius
	scale = Vector2(target_scale, target_scale)
	
	if animation:
		animation.play("explode")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("terrain") or body.is_in_group("terrain_deadly"):
		return
	if body is TileMapLayer:
		var local_point = body.to_local(global_position)
		var center_coords = body.local_to_map(local_point)
		
		var closest_coord: Vector2i
		var min_distance = INF
		
		# Ищем в радиусе 3, выбираем ближайший тайл к точке коллизии
		for x in range(-3, 4):
			for y in range(-3, 4):
				var coord = center_coords + Vector2i(x, y)
				if body.get_cell_source_id(coord) != -1:
					# Центр клетки в глобальных координатах
					var cell_center = body.to_global(body.map_to_local(coord))
					var dist = global_position.distance_to(cell_center)
					if dist < min_distance:
						min_distance = dist
						closest_coord = coord
		
		if min_distance != INF:
			body.set_cell(closest_coord, -1)
	
	# Исключаем исключённую цель
	if body == shooter or body == excluded_target or not body.is_in_group("enemy"):
		return
	
	if body.has_method("on_hit"):
		body.on_hit(damage, "explosion")

func _on_animation_finished() -> void:
	queue_free()
