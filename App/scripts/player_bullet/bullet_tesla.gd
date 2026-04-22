extends BulletBase
class_name BulletTesla

# ============================================
# ПАРАМЕТРЫ ТЕСЛА-ПУШКИ
# ============================================

var chain_count: int = 3                    # Количество цепей
var chain_range: float = 200.0              # Радиус поиска следующей цели
var chain_damage_falloff: float = 0.7       # Множитель урона для каждой следующей цели
var chain_delay: float = 0.08               # Задержка между прыжками (сек)

# Внутренние переменные
var _hit_targets: Array = []                # Список уже поражённых целей
var _hit_positions: Array = []              # Список позиций попаданий (для тайлов)
var _current_chain: int = 0                 # Текущее количество прыжков
var _is_chaining: bool = false              # Флаг выполнения цепи

# Точка, откуда стартует первая молния
var _spawn_point: Vector2

# Цвета для визуализации
var lightning_color: Color = Color(0.3, 0.7, 1.0, 0.9)  # Голубой
var lightning_width: float = 3.0

# ============================================
# ЖИЗНЕННЫЙ ЦИКЛ
# ============================================

func _ready() -> void:
	bullet_type = "tesla"
	auto_delete_on_exit = false  # Управляем удалением сами
	speed = 0  # Пуля не двигается обычным способом
	
	# Сохраняем точку спавна ДО вызова super
	_spawn_point = global_position
	
	super()
	
	# Добавляем небольшую случайность к цвету для красоты
	lightning_color = Color(
		randf_range(0.2, 0.4),
		randf_range(0.6, 0.8),
		1.0,
		0.9
	)
	
	# Начинаем цепную реакцию
	_start_chain_reaction()

# ============================================
# ОСНОВНАЯ ЛОГИКА ЦЕПНОЙ МОЛНИИ
# ============================================

func _start_chain_reaction() -> void:
	if _is_chaining:
		return
	
	_is_chaining = true
	
	# Ищем первую цель от точки спавна
	var first_target = _find_nearest_target_from_point(_spawn_point)
	
	if first_target:
		# Получаем позицию попадания
		var hit_pos = _get_target_hit_position(first_target, _spawn_point)
		
		# Поражаем первую цель
		_hit_targets.append(first_target)
		_hit_positions.append(hit_pos)
		_deal_damage_to_target(first_target, hit_pos, damage)
		_current_chain += 1
		
		# Создаём эффект молнии от точки спавна к позиции попадания
		_create_lightning_effect(_spawn_point, hit_pos)
		
		# Запускаем цепь дальше от позиции попадания
		_chain_to_next_target(hit_pos)
	else:
		# Если целей нет - рисуем короткую молнию в направлении выстрела
		_create_short_lightning(_spawn_point)
		await get_tree().create_timer(0.1).timeout
		_queue_free()

func _chain_to_next_target(from_position: Vector2) -> void:
	# Условия завершения цепи
	if _current_chain >= chain_count:
		_finish_chain()
		return
	
	# Ищем следующую цель от текущей позиции
	var next_target = _find_nearest_unchained_target_from_point(from_position)
	
	if not next_target:
		_finish_chain()
		return
	
	# Ждём небольшую задержку для визуального эффекта
	await get_tree().create_timer(chain_delay).timeout
	
	# Проверяем, что цель всё ещё существует
	if not is_instance_valid(next_target):
		# Пробуем найти другую цель
		_chain_to_next_target(from_position)
		return
	
	# Получаем позицию попадания
	var hit_pos = _get_target_hit_position(next_target, from_position)
	
	# Рассчитываем урон с учётом falloff
	var current_damage = ceil(damage * pow(chain_damage_falloff, _current_chain))
	
	# Наносим урон
	_deal_damage_to_target(next_target, hit_pos, current_damage)
	
	# Создаём визуальный эффект молнии от предыдущей позиции к позиции попадания
	_create_lightning_effect(from_position, hit_pos)
	
	# Запоминаем цель и позицию
	_hit_targets.append(next_target)
	_hit_positions.append(hit_pos)
	_current_chain += 1
	
	# Продолжаем цепь от позиции попадания
	_chain_to_next_target(hit_pos)

# ============================================
# ПОЛУЧЕНИЕ ПОЗИЦИИ ПОПАДАНИЯ ДЛЯ РАЗНЫХ ТИПОВ ЦЕЛЕЙ
# ============================================

func _get_target_hit_position(target: Node2D, from_point: Vector2) -> Vector2:
	# Если цель - TileMapLayer, ищем ближайший тайл
	if target is TileMapLayer:
		return _get_closest_tile_position(target, from_point)
	
	# Для обычных целей возвращаем их глобальную позицию
	return target.global_position

func _get_closest_tile_position(tilemap: TileMapLayer, from_point: Vector2) -> Vector2:
	var closest_pos: Vector2 = tilemap.global_position
	var min_dist: float = chain_range
	
	# Проходим по всем используемым ячейкам тайлмапа
	for cell in tilemap.get_used_cells():
		var cell_center = tilemap.to_global(tilemap.map_to_local(cell))
		var dist = from_point.distance_to(cell_center)
		
		if dist < min_dist:
			min_dist = dist
			closest_pos = cell_center
	
	return closest_pos

# ============================================
# ПОИСК ЦЕЛЕЙ
# ============================================

func _find_nearest_target_from_point(from_point: Vector2) -> Node2D:
	var nearest_target: Node2D = null
	var min_distance: float = chain_range
	
	var all_targets: Array = []
	all_targets.append_array(get_tree().get_nodes_in_group("enemy"))
	all_targets.append_array(get_tree().get_nodes_in_group("capsules"))
	all_targets.append_array(get_tree().get_nodes_in_group("destroyed_tile"))
	
	for target in all_targets:
		if not _is_valid_target(target):
			continue
		
		var target_pos = _get_target_hit_position(target, from_point)
		var distance = from_point.distance_to(target_pos)
		
		if distance < min_distance:
			min_distance = distance
			nearest_target = target
	
	return nearest_target

func _find_nearest_unchained_target_from_point(from_point: Vector2) -> Node2D:
	var nearest_target: Node2D = null
	var min_distance: float = chain_range
	
	var all_targets: Array = []
	all_targets.append_array(get_tree().get_nodes_in_group("enemy"))
	all_targets.append_array(get_tree().get_nodes_in_group("capsules"))
	all_targets.append_array(get_tree().get_nodes_in_group("destroyed_tile"))
	
	for target in all_targets:
		# Пропускаем невалидные цели
		if not _is_valid_target(target):
			continue
		
		# Пропускаем уже поражённые цели
		if target in _hit_targets:
			# Для TileMapLayer проверяем дополнительно по позиции
			if target is TileMapLayer:
				var hit_pos = _get_target_hit_position(target, from_point)
				if hit_pos in _hit_positions:
					continue
			else:
				continue
		
		var target_pos = _get_target_hit_position(target, from_point)
		var distance = from_point.distance_to(target_pos)
		
		if distance < min_distance:
			min_distance = distance
			nearest_target = target
	
	return nearest_target

func _is_valid_target(target: Node2D) -> bool:
	# Проверяем, что цель существует и не является стрелком
	if not is_instance_valid(target):
		return false
	
	if target == shooter:
		return false
	
	# Проверяем, что цель - враг, капсула или разрушаемый тайл
	if not (target.is_in_group("enemy") or target.is_in_group("capsules") or target.is_in_group("destroyed_tile")):
		return false
	
	# Проверяем уязвимость (для врагов и капсул)
	if not target is TileMapLayer:
		if target.has_method("get_is_vulnerable") and not target.get_is_vulnerable():
			return false
	
	return true

# ============================================
# НАНЕСЕНИЕ УРОНА
# ============================================

func _deal_damage_to_target(target: Node2D, hit_position: Vector2, amount: int) -> void:
	# Для TileMapLayer - разрушаем тайл
	if target is TileMapLayer:
		_destroy_tile_at_position(target, hit_position)
	else:
		# Для обычных целей вызываем on_hit
		if target.has_method("on_hit"):
			target.on_hit(amount, bullet_type)
	
	# Создаём эффект попадания
	_create_hit_effect(hit_position)

func _destroy_tile_at_position(tilemap: TileMapLayer, hit_position: Vector2) -> void:
	# Конвертируем глобальную позицию в координаты тайла
	var local_point = tilemap.to_local(hit_position)
	var coords = tilemap.local_to_map(local_point)
	
	# Проверяем, есть ли тайл в этой позиции
	if tilemap.get_cell_source_id(coords) != -1:
		# Создаём эффект взрыва тайла (опционально)
		_create_tile_explosion(hit_position, tilemap, coords)
		
		# Удаляем тайл
		tilemap.set_cell(coords, -1)

# ============================================
# ВИЗУАЛЬНЫЕ ЭФФЕКТЫ
# ============================================

func _create_short_lightning(from: Vector2) -> void:
	# Создаём короткую молнию в направлении direction
	var to = from + direction * 100.0  # Длина короткой молнии
	
	# Проверяем столкновение со стенами
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(from, to)
	query.collision_mask = 2116  # Используем ту же маску, что и в лазере
	query.exclude = [shooter]
	
	var result = space_state.intersect_ray(query)
	if result:
		to = result.position
		# Создаём искры в точке попадания
		_create_spark_effect(to)
	
	# Рисуем короткую молнию
	_create_lightning_effect(from, to)

func _create_spark_effect(position1: Vector2) -> void:
	var spark_scene = load("res://scenes/effects/spark_effect.tscn")
	if spark_scene:
		var spark = spark_scene.instantiate()
		spark.global_position = position1
		get_tree().current_scene.add_child(spark)

func _create_lightning_effect(from: Vector2, to: Vector2) -> void:
	# Основная линия молнии
	var line = Line2D.new()
	line.width = lightning_width
	line.default_color = lightning_color
	line.antialiased = true
	
	# Добавляем небольшую "дрожь" для реалистичности
	var points = _generate_lightning_points(from, to)
	
	# Переводим в локальные координаты относительно пули
	line.points = points.map(func(p): return to_local(p))
	
	add_child(line)
	
	# Свечение вокруг молнии
	var glow = Line2D.new()
	glow.width = lightning_width * 2.5
	glow.default_color = Color(lightning_color.r, lightning_color.g, lightning_color.b, 0.3)
	glow.points = line.points
	add_child(glow)
	glow.z_index = -1
	
	# Анимируем исчезновение линий
	var tween = create_tween().set_parallel(true)
	tween.tween_property(line, "modulate:a", 0.0, 0.3).set_delay(0.2)
	tween.tween_property(glow, "modulate:a", 0.0, 0.3).set_delay(0.2)
	tween.tween_callback(line.queue_free).set_delay(0.5)
	tween.tween_callback(glow.queue_free).set_delay(0.5)

func _generate_lightning_points(from: Vector2, to: Vector2) -> Array:
	var points = [from]
	var segments = 8
	var displacement = 15.0
	
	for i in range(1, segments):
		var t = float(i) / segments
		var base_point = from.lerp(to, t)
		
		# Добавляем случайное смещение перпендикулярно направлению
		var direction1 = (to - from).normalized()
		var perpendicular = Vector2(-direction1.y, direction1.x)
		var offset = randf_range(-displacement, displacement)
		
		var point = base_point + perpendicular * offset
		points.append(point)
	
	points.append(to)
	return points

func _create_hit_effect(position1: Vector2) -> void:
	# Создаём электрические искры при попадании
	var spark_scene = load("res://scenes/effects/spark_effect.tscn")
	if spark_scene:
		var spark = spark_scene.instantiate()
		spark.global_position = position1
		get_tree().current_scene.add_child(spark)
		
		# Если есть метод для изменения цвета, вызываем его
		if spark.has_method("set_color"):
			spark.set_color(lightning_color)

func _finish_chain() -> void:
	# Создаём финальную вспышку в последней позиции попадания
	if _hit_positions.size() > 0:
		_create_hit_effect(_hit_positions.back())
	else:
		_create_hit_effect(_spawn_point)
	
	# Небольшая задержка перед удалением
	await get_tree().create_timer(0.1).timeout
	_queue_free()

# ============================================
# ПЕРЕОПРЕДЕЛЯЕМ МЕТОДЫ БАЗОВОГО КЛАССА
# ============================================
