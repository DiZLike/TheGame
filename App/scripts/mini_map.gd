extends Control

@export var tilemap_layers: Array[TileMapLayer] = []
@export var map_width: float = 250.0
@export var map_height: float = 150.0
@export var visible_radius: float = 500.0
@export var zoom_level: float = 2.0
@export var update_interval: float = 0.1

var player: CharacterBody2D
var terrain_color = Color(0.402, 0.156, 0.0, 0.8)
var door_color = Color(1, 0.5, 0, 1)
var player_color = Color(0, 1, 0, 1)
var bg_color = Color(0.0, 0.0, 0.0, 0.922)

var door_positions = []
var update_timer: float = 0.0

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if not is_instance_valid(player):
		find_player()
	
	if tilemap_layers.is_empty():
		find_all_tilemap_layers()
	
	find_doors()
	debug_print_status()

func find_all_tilemap_layers():
	var parent = get_parent()
	if parent:
		_find_layers_recursive(parent)

func _find_layers_recursive(node: Node):
	for child in node.get_children():
		if child is TileMapLayer:
			tilemap_layers.append(child)
		_find_layers_recursive(child)

func find_player():
	var possible_player = get_tree().get_first_node_in_group("player")
	if possible_player:
		player = possible_player
		print("Player found: ", player.name)
		return true
	
	var players = get_tree().get_nodes_in_group("CharacterBody2D")
	for p in players:
		if p is CharacterBody2D and p.name.to_lower().contains("player"):
			player = p
			print("Player found by type: ", player.name)
			return true
	
	print("Warning: No player found!")
	return false

func find_doors():
	door_positions.clear()
	var doors = get_tree().get_nodes_in_group("bug")
	for door in doors:
		if is_instance_valid(door):
			door_positions.append(door.global_position)

func world_to_map_pos(world_pos: Vector2, center: Vector2) -> Vector2:
	var relative_pos = world_pos - center
	var scaled_radius = visible_radius / zoom_level
	var x = (relative_pos.x / scaled_radius) * (map_width / 2) + map_width / 2
	var y = (relative_pos.y / scaled_radius) * (map_height / 2) + map_height / 2
	return Vector2(x, y)

func is_in_view(world_pos: Vector2, center: Vector2) -> bool:
	var scaled_radius = visible_radius / zoom_level
	return abs(world_pos.x - center.x) <= scaled_radius and abs(world_pos.y - center.y) <= scaled_radius

func _draw():
	if tilemap_layers.is_empty() or not is_instance_valid(player):
		draw_rect(Rect2(Vector2.ZERO, size), bg_color)
		return
	
	var player_center = player.global_position
	var scaled_radius = visible_radius / zoom_level
	
	draw_rect(Rect2(Vector2.ZERO, size), bg_color)
	
	for layer in tilemap_layers:
		if not is_instance_valid(layer):
			continue
		
		var used_cells = layer.get_used_cells()
		var tile_size = layer.tile_set.tile_size
		
		for cell in used_cells:
			var cell_world_pos = layer.to_global(layer.map_to_local(cell))
			
			if not is_in_view(cell_world_pos, player_center):
				continue
			
			var map_pos = world_to_map_pos(cell_world_pos, player_center)
			var map_tile_size = Vector2(
				(tile_size.x / scaled_radius) * (map_width / 2),
				(tile_size.y / scaled_radius) * (map_height / 2)
			)
			draw_rect(Rect2(map_pos - map_tile_size / 2, map_tile_size), terrain_color)
	
	for door_pos in door_positions:
		if not is_in_view(door_pos, player_center):
			continue
		var map_pos = world_to_map_pos(door_pos, player_center)
		draw_rect(Rect2(map_pos - Vector2(3, 4), Vector2(6, 8)), door_color)
	
	var player_map_pos = world_to_map_pos(player.global_position, player_center)
	draw_rect(Rect2(player_map_pos - Vector2(2, 2), Vector2(4, 4)), player_color)
	
	draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.5), false, 1.5)

func _process(delta):
	if not is_instance_valid(player):
		find_player()
		if not is_instance_valid(player):
			queue_redraw()
			return
	
	update_timer += delta
	if update_timer >= update_interval:
		update_timer = 0.0
		queue_redraw()

func set_player(new_player: CharacterBody2D):
	player = new_player
	queue_redraw()

func debug_print_status():
	print("=== MiniMap Status ===")
	print("Player valid: ", is_instance_valid(player))
	print("TileMap layers count: ", tilemap_layers.size())
	for i in tilemap_layers.size():
		print("  Layer ", i, ": ", tilemap_layers[i].name if is_instance_valid(tilemap_layers[i]) else "INVALID")
	print("Doors count: ", door_positions.size())
