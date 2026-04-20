# barrier_source_manager.gd
extends Node

signal group_destroyed(group_name: String)
signal group_respawned(group_name: String, respawned_count: int)

var source_scene_path: String = "res://scenes/barrier_source/barrier_source_1.tscn"

var death_times: Dictionary = {}
var source_positions: Dictionary = {}
var group_parents: Dictionary = {}
var group_tolerances: Dictionary = {}
var group_timers: Dictionary = {}
var source_data: Dictionary = {}


func register_source(group_name: String, source_name: String, position: Vector2, parent: Node, tolerance: float):
	if not death_times.has(group_name):
		death_times[group_name] = {}
		source_positions[group_name] = {}
		source_data[group_name] = {}
		group_parents[group_name] = parent
		group_tolerances[group_name] = tolerance
	
	source_positions[group_name][source_name] = position
	
	if not source_data[group_name].has(source_name):
		source_data[group_name][source_name] = {
			"position": position,
			"group": group_name,
			"parent": parent,
			"tolerance": tolerance
		}
	
	if death_times[group_name].has(source_name):
		death_times[group_name].erase(source_name)


func update_source_properties(group_name: String, source_name: String, properties: Dictionary):
	if source_data.has(group_name) and source_data[group_name].has(source_name):
		for key in properties:
			source_data[group_name][source_name][key] = properties[key]


func report_death(group_name: String, source_name: String):
	var time = Time.get_ticks_msec()
	
	if not death_times.has(group_name):
		return
	
	death_times[group_name][source_name] = time
	
	var destroyed_count = death_times[group_name].size()
	var total_sources = source_positions[group_name].size()
	var tolerance = group_tolerances[group_name]
	
	cancel_timer(group_name)
	
	if destroyed_count == total_sources:
		call_deferred("check_simultaneous_death", group_name)
	else:
		start_timer(group_name, tolerance)


func cancel_timer(group_name: String):
	if group_timers.has(group_name) and is_instance_valid(group_timers[group_name]):
		group_timers[group_name].stop()
		group_timers[group_name].queue_free()
		group_timers.erase(group_name)


func start_timer(group_name: String, wait_time: float):
	var timer = Timer.new()
	timer.wait_time = wait_time
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout.bind(group_name))
	add_child(timer)
	group_timers[group_name] = timer
	timer.start()


func _on_timer_timeout(group_name: String):
	if not death_times.has(group_name):
		return
	
	var destroyed_count = death_times[group_name].size()
	var total_sources = source_positions[group_name].size()
	
	if destroyed_count == total_sources:
		check_simultaneous_death(group_name)
	else:
		call_deferred("respawn_destroyed", group_name)
	
	group_timers.erase(group_name)


func check_simultaneous_death(group_name: String):
	if not death_times.has(group_name):
		return
	
	var times = []
	for t in death_times[group_name].values():
		times.append(t)
	times.sort()
	
	var time_diff = times[-1] - times[0]
	var tolerance_ms = group_tolerances[group_name] * 1000
	
	if time_diff <= tolerance_ms:
		group_destroyed.emit(group_name)
		clear_group_data(group_name)
	else:
		call_deferred("respawn_destroyed", group_name)


func clear_group_data(group_name: String):
	death_times.erase(group_name)
	source_positions.erase(group_name)
	source_data.erase(group_name)
	group_parents.erase(group_name)
	group_tolerances.erase(group_name)
	cancel_timer(group_name)


func respawn_destroyed(group_name: String):
	if source_scene_path.is_empty():
		push_error("BarrierSourceManager: Не указан путь к сцене!")
		return
	
	if not group_parents.has(group_name):
		push_error("BarrierSourceManager: Группа ", group_name, " не найдена!")
		return
	
	var parent = group_parents[group_name]
	
	if not is_instance_valid(parent):
		push_error("BarrierSourceManager: Родительский узел для группы ", group_name, " не существует!")
		clear_group_data(group_name)
		return
	
	if not death_times.has(group_name) or not source_data.has(group_name):
		return
	
	var destroyed_names = death_times[group_name].keys()
	
	var scene = load(source_scene_path)
	if scene == null:
		push_error("BarrierSourceManager: Не удалось загрузить сцену: ", source_scene_path)
		return
	
	death_times[group_name].clear()
	
	var respawned_count = 0
	for source_name in destroyed_names:
		if source_data[group_name].has(source_name):
			var data = source_data[group_name][source_name]
			
			var new_source = scene.instantiate()
			new_source.name = source_name
			new_source.global_position = data["position"]
			new_source.group_name = data["group"]
			
			if data.has("enable"):
				new_source.enable = data["enable"]
			if data.has("tolerance"):
				new_source.tolerance = data["tolerance"]
			
			parent.add_child.call_deferred(new_source)
			respawned_count += 1
	
	cancel_timer(group_name)
	group_respawned.emit(group_name, respawned_count)


func is_group_active(group_name: String) -> bool:
	return death_times.has(group_name) or source_positions.has(group_name)


func get_group_sources_count(group_name: String) -> int:
	if source_positions.has(group_name):
		return source_positions[group_name].size()
	return 0


func get_group_destroyed_count(group_name: String) -> int:
	if death_times.has(group_name):
		return death_times[group_name].size()
	return 0


func get_group_alive_count(group_name: String) -> int:
	return get_group_sources_count(group_name) - get_group_destroyed_count(group_name)


func debug_print_group_status(group_name: String):
	print("=== Статус группы: ", group_name, " ===")
	print("Всего источников: ", get_group_sources_count(group_name))
	print("Уничтожено: ", get_group_destroyed_count(group_name))
	print("Живых: ", get_group_alive_count(group_name))
	print("Активна: ", is_group_active(group_name))
	if death_times.has(group_name):
		print("Уничтоженные источники: ", death_times[group_name].keys())
	if source_data.has(group_name):
		print("Сохраненные данные источников:")
		for source_name in source_data[group_name]:
			print("  - ", source_name, ": группа=", source_data[group_name][source_name]["group"])
	print("================================")
