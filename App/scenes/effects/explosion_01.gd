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
	# Настройка радиуса
	if collision_shape and collision_shape.shape is CircleShape2D:
		_original_radius = (collision_shape.shape as CircleShape2D).radius
	
	var target_scale = explosion_radius / _original_radius
	scale = Vector2(target_scale, target_scale)
	
	if animation:
		animation.play("explode")
		
	# Подключаем сигнал вручную, если не подключен через редактор
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# Пропускаем группы terrain
	if body.is_in_group("terrain") or body.is_in_group("terrain_deadly"):
		return
	
	# Обработка TileMapLayer
	if body is TileMapLayer:
		_handle_tilemap_destruction(body)
	
	# Исключаем стрелявшего и исключённую цель
	if body == shooter or body == excluded_target:
		return
	
	# Наносим урон только врагам
	if not body.is_in_group("enemy"):
		return
	
	if body.has_method("on_hit"):
		body.on_hit(damage, "explosion")

func _handle_tilemap_destruction(tilemap: TileMapLayer) -> void:
	var local_point = tilemap.to_local(global_position)
	var center_coords = tilemap.local_to_map(local_point)
	
	# Получаем размер тайла из TileSet
	var tile_size = tilemap.tile_set.tile_size
	
	# Вычисляем радиус в клетках (округляем вверх)
	var cell_radius = ceil(explosion_radius / max(tile_size.x, tile_size.y))
	
	# Собираем все тайлы в радиусе взрыва для уничтожения
	var cells_to_remove: Array[Vector2i] = []
	
	for x in range(-cell_radius, cell_radius + 1):
		for y in range(-cell_radius, cell_radius + 1):
			var coord = center_coords + Vector2i(x, y)
			
			# Проверяем, существует ли тайл в этой клетке
			if tilemap.get_cell_source_id(coord) != -1:
				# Центр клетки в глобальных координатах
				var cell_center = tilemap.to_global(tilemap.map_to_local(coord))
				var dist = global_position.distance_to(cell_center)
				
				# Уничтожаем только тайлы в радиусе взрыва
				if dist <= explosion_radius:
					cells_to_remove.append(coord)
	
	# Удаляем все найденные тайлы
	for coord in cells_to_remove:
		tilemap.set_cell(coord, -1)

func _on_animation_finished() -> void:
	queue_free()
