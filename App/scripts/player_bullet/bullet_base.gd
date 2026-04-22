extends Area2D
class_name BulletBase

# ============================================
# БАЗОВЫЙ КЛАСС ДЛЯ ВСЕХ ПУЛЬ
# ============================================

# === ОБЩИЕ ПАРАМЕТРЫ ===
var direction: Vector2 = Vector2.RIGHT:
	set(value):
		direction = value
		_update_visual_rotation()  # Хук для обновления визуала

var shooter: Node2D = null
var speed: float = 300.0
var damage: int = 1
var bullet_type: String = "default"  # Тип пули (для врагов)

# === ДОПОЛНИТЕЛЬНЫЕ НАСТРОЙКИ ===
var auto_delete_on_exit: bool = true  # Удалять при выходе за экран
var life_time: float = -1.0  # -1 = бесконечно, иначе время жизни в секундах
var can_hit_shooter: bool = false  # Может ли пуля попасть в стрелка

# === ВНУТРЕННИЕ ПЕРЕМЕННЫЕ ===
var _is_queued_for_deletion: bool = false

# ============================================
# ЖИЗНЕННЫЙ ЦИКЛ
# ============================================

func _ready() -> void:
	_setup_life_timer()
	_on_ready()  # Хук для дочерних классов

func _physics_process(delta: float) -> void:
	_move(delta)
	_on_physics_process(delta)  # Хук для дочерних классов

# ============================================
# БАЗОВАЯ ЛОГИКА ДВИЖЕНИЯ
# ============================================
func _move(delta: float) -> void:
	global_position += direction * speed * delta

# ============================================
# ТАЙМЕР ЖИЗНИ
# ============================================
func _setup_life_timer() -> void:
	if life_time > 0:
		await get_tree().create_timer(life_time).timeout
		if not _is_queued_for_deletion:
			_on_life_timeout()

# Хук для дочерних классов
func _on_life_timeout() -> void:
	_queue_free()

# ============================================
# СТОЛКНОВЕНИЯ (ОБЩАЯ ЛОГИКА)
# ============================================
func _on_body_entered(body: Node2D) -> void:
	if _is_queued_for_deletion:
		return
	
	if not can_hit_shooter and body == shooter:
		return
	
	var is_valid_target = body.is_in_group("enemy") or body.is_in_group("capsules")
	if not (is_valid_target and body.has_method("on_hit")):
		_on_other_collision(body)
		return
	
	# Проверка уязвимости
	if body.has_method("get_is_vulnerable") and not body.get_is_vulnerable():
		return
	
	body.on_hit(damage, bullet_type)
	_on_hit_enemy(body)
	_queue_free()

func _on_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	pass

# ============================================
# ВЫХОД ЗА ЭКРАН
# ============================================
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	if auto_delete_on_exit and not _is_queued_for_deletion:
		_queue_free()

# ============================================
# УДАЛЕНИЕ ПУЛИ
# ============================================
func _queue_free() -> void:
	if _is_queued_for_deletion:
		return
	
	_is_queued_for_deletion = true
	queue_free()

# ============================================
# ВИЗУАЛЬНЫЕ ХУКИ
# ============================================
func _update_visual_rotation() -> void:
	# Переопределить в дочернем классе для поворота спрайта
	pass

# ============================================
# ХУКИ ДЛЯ ДОЧЕРНИХ КЛАССОВ
# ============================================

# Вызывается после _ready()
func _on_ready() -> void:
	pass

# Вызывается каждый кадр в _physics_process
@warning_ignore("unused_parameter")
func _on_physics_process(delta: float) -> void:
	pass

# Вызывается при попадании во врага (перед удалением пули)
@warning_ignore("unused_parameter")
func _on_hit_enemy(enemy: Node2D) -> void:
	pass

# Вызывается при столкновении с не-врагом
@warning_ignore("unused_parameter")
func _on_other_collision(body: Node2D) -> void:
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
			# Получаем центр уничтожаемого тайла
			var cell_center = body.to_global(body.map_to_local(closest_coord))
			
			# Создаем взрыв тайла перед удалением
			_create_tile_explosion(cell_center, body, closest_coord)
			
			# Удаляем тайл
			body.set_cell(closest_coord, -1)
			queue_free()

# ============================================
# ВЗРЫВ ТАЙЛА
# ============================================
func _create_tile_explosion(position: Vector2, tilemap: TileMapLayer, coords: Vector2i) -> void:
	# Получаем текстуру тайла
	var tile_texture = _get_tile_texture_from_atlas(tilemap, coords)
	
	if tile_texture:
		var tile_scene = load("res://scenes/tile.tscn")
		var tile = tile_scene.instantiate()
		
		get_tree().root.add_child(tile)
		tile.global_position = position
		
		var sprite = Sprite2D.new()
		sprite.texture = tile_texture
		sprite.centered = true
		
		tile.set_sprite(sprite)
		tile.destroy(bullet_type)
		sprite.queue_free()
	else:
		print("=== NO TEXTURE DATA ===")

# ============================================
# ПОЛУЧЕНИЕ ТЕКСТУРЫ ТАЙЛА ИЗ АТЛАСА
# ============================================
func _get_tile_texture_from_atlas(tilemap: TileMapLayer, coords: Vector2i) -> Texture2D:
	var source_id = tilemap.get_cell_source_id(coords)
	
	if source_id == -1:
		return null
	
	var tileset = tilemap.tile_set
	var source = tileset.get_source(source_id)
	
	if source is TileSetAtlasSource:
		var atlas_coords = tilemap.get_cell_atlas_coords(coords)
		
		var region = source.get_tile_texture_region(atlas_coords)
		
		if region != Rect2i() and source.texture:
			var atlas_texture = AtlasTexture.new()
			atlas_texture.atlas = source.texture
			atlas_texture.region = region
			return atlas_texture
	
	return null
