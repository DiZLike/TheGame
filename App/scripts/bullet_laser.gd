extends Area2D

class_name BulletLaser

@export var laser_color: Color = Color(0.353, 0.576, 1.0, 0.71)
@export var glow_color: Color = Color(1.0, 0.502, 0.2, 0.729)

var direction: Vector2 = Vector2.RIGHT
var shooter: Node2D = null
var speed: float = 300.0
var damage: int = 3
var pierce_count: int = 0
var laser_duration: float = 0.1

var _line: Line2D
var _hit_enemies: Array = []
var _hit_terrain_points: Array = []
var _laser_points: Array = []
var _hit_check_timer: Timer = null
var col_mask = 5

func _ready() -> void:
	_line = Line2D.new()
	_line.width = 2
	_line.default_color = laser_color
	_line.antialiased = true
	add_child(_line)
	
	_collect_laser_points(global_position, direction, pierce_count, _laser_points)
	
	if _laser_points.size() >= 2:
		var local_points = _laser_points.map(to_local)
		_line.points = local_points
		
		var glow = Line2D.new()
		glow.width = 1
		glow.default_color = glow_color
		glow.points = local_points
		add_child(glow)
	
	_start_hit_checking()
	
	await get_tree().create_timer(laser_duration).timeout
	_stop_hit_checking()
	
	WeaponManager.remove_bullet()
	queue_free()

func _collect_laser_points(start_pos: Vector2, laser_dir: Vector2, remaining_pierce: int, out_points: Array) -> void:
	var end_pos = start_pos + laser_dir * 2000
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(start_pos, end_pos)
	query.exclude = [shooter]
	if remaining_pierce >= 999:
		query.collision_mask = 4
	else:
		query.collision_mask = 5
	
	var result = space_state.intersect_ray(query)
	
	if result:
		var hit_point = result.position
		
		if out_points.is_empty():
			out_points.append(start_pos)
		out_points.append(hit_point)
		
		_process_hit(result.collider, hit_point)
		
		if remaining_pierce > 0:
			var new_start = hit_point + laser_dir * 5
			_collect_laser_points(new_start, laser_dir, remaining_pierce - 1, out_points)
	else:
		if out_points.is_empty():
			out_points.append(start_pos)
		out_points.append(end_pos)

func _process_hit(collider: Node2D, hit_point: Vector2) -> void:
	if collider.is_in_group("enemy"):
		if not collider in _hit_enemies:
			_hit_enemies.append(collider)
			if collider.has_method("on_hit"):
				collider.on_hit(damage, "laser")
			_create_spark_effect(hit_point)
	
	elif collider.is_in_group("terrain"):
		var is_duplicate = false
		for existing_point in _hit_terrain_points:
			if existing_point.distance_to(hit_point) < 5.0:
				is_duplicate = true
				break
		
		if not is_duplicate:
			_hit_terrain_points.append(hit_point)
			_create_spark_effect(hit_point)

func _start_hit_checking() -> void:
	_hit_check_timer = Timer.new()
	_hit_check_timer.wait_time = 0.05
	_hit_check_timer.autostart = true
	_hit_check_timer.timeout.connect(_check_new_hits)
	add_child(_hit_check_timer)

func _stop_hit_checking() -> void:
	if _hit_check_timer:
		_hit_check_timer.timeout.disconnect(_check_new_hits)
		_hit_check_timer.queue_free()
		_hit_check_timer = null

func _check_new_hits() -> void:
	if _laser_points.size() < 2:
		return
	
	var space_state = get_world_2d().direct_space_state
	
	for i in range(_laser_points.size() - 1):
		var start = _laser_points[i]
		var end = _laser_points[i + 1]
		
		var query = PhysicsRayQueryParameters2D.create(start, end)
		query.exclude = [shooter]
		query.collision_mask = col_mask
		
		var result = space_state.intersect_ray(query)
		
		if result:
			_process_hit(result.collider, result.position)

func _create_spark_effect(position: Vector2) -> void:
	print("Искры созданы в: ", position)
	var spark_scene = preload("res://scenes/effects/spark_effect.tscn")
	if spark_scene:
		var spark_instance = spark_scene.instantiate()
		spark_instance.global_position = position
		get_tree().root.add_child(spark_instance)
	else:
		print("Ошибка: SparkEffect.tscn не найдена!")
