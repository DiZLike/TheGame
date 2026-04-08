extends Control

#@export var player: CharacterBody2D
@export var tilemap_layer: TileMapLayer
@export var map_width: float = 250.0
@export var map_height: float = 150.0
@export var visible_radius: float = 500.0
@export var zoom_level: float = 2.0
@export var update_interval: float = 0.1  # Интервал обновления в секундах (10 FPS для миникарты)

var player: CharacterBody2D
# Цвета
var terrain_color = Color(0.402, 0.156, 0.0, 0.8)
var door_color = Color(1, 0.5, 0, 1)
var player_color = Color(0, 1, 0, 1)
var bg_color = Color(0.0, 0.0, 0.0, 0.922)

var door_positions = []
var update_timer: float = 0.0

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Автоматически ищем player, если не назначен
	if not is_instance_valid(player):
		find_player()
	
	find_doors()
	debug_print_status()

func find_player():
	# Ищем player в группе "player"
	var possible_player = get_tree().get_first_node_in_group("player")
	if possible_player:
		player = possible_player
		print("Player found automatically: ", player.name)
		return true
	else:
		# Если не нашли в группе, ищем по типу CharacterBody2D
		var players = get_tree().get_nodes_in_group("CharacterBody2D")
		for p in players:
			if p is CharacterBody2D and p.name.to_lower().contains("player"):
				player = p
				print("Player found by type: ", player.name)
				return true
		
		print("Warning: No player found! Mini-map will not work until player is set.")
		return false

func find_doors():
	door_positions.clear()
	var doors = get_tree().get_nodes_in_group("doors")
	for door in doors:
		if is_instance_valid(door):
			door_positions.append(door.global_position)

func get_level_bounds() -> Rect2:
	if not tilemap_layer:
		return Rect2(0, 0, 4000, 800)
	
	var used_rect = tilemap_layer.get_used_rect()
	if used_rect.size.x == 0 or used_rect.size.y == 0:
		return Rect2(0, 0, 4000, 800)
	
	var tile_size = tilemap_layer.tile_set.tile_size
	return Rect2(
		used_rect.position * tile_size,
		used_rect.size * tile_size
	)

func world_to_map_pos(world_pos: Vector2, center: Vector2, view_size: Vector2) -> Vector2:
	var relative_pos = world_pos - center
	var scaled_radius = visible_radius / zoom_level
	var x = (relative_pos.x / scaled_radius) * (map_width / 2) + map_width / 2
	var y = (relative_pos.y / scaled_radius) * (map_height / 2) + map_height / 2
	return Vector2(x, y)

func is_in_view(world_pos: Vector2, center: Vector2) -> bool:
	var scaled_radius = visible_radius / zoom_level
	return abs(world_pos.x - center.x) <= scaled_radius and abs(world_pos.y - center.y) <= scaled_radius

func _draw():
	# Проверяем существование player и tilemap_layer
	if not tilemap_layer:
		return
	
	if not is_instance_valid(player):
		# Показываем сообщение об отсутствии игрока на миникарте
		draw_rect(Rect2(Vector2.ZERO, size), bg_color)
		var font = ThemeDB.fallback_font
		var message = "Waiting for player..."
		var message_size = font.get_string_size(message, HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
		var text_pos = Vector2((size.x - message_size.x) / 2, (size.y - message_size.y) / 2)
		draw_string(font, text_pos, message, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.RED)
		return
	
	var bounds = get_level_bounds()
	var tile_size = tilemap_layer.tile_set.tile_size
	var player_center = player.global_position
	var scaled_radius = visible_radius / zoom_level
	
	draw_rect(Rect2(Vector2.ZERO, size), bg_color)
	
	var used_cells = tilemap_layer.get_used_cells()
	
	for cell in used_cells:
		var cell_world_pos = tilemap_layer.map_to_local(cell)
		
		if not is_in_view(cell_world_pos, player_center):
			continue
		
		var map_pos = world_to_map_pos(cell_world_pos, player_center, size)
		
		var map_tile_size = Vector2(
			(tile_size.x / scaled_radius) * (map_width / 2),
			(tile_size.y / scaled_radius) * (map_height / 2)
		)
		
		draw_rect(Rect2(map_pos - map_tile_size / 2, map_tile_size), terrain_color)
	
	for door_pos in door_positions:
		if not is_in_view(door_pos, player_center):
			continue
			
		var map_pos = world_to_map_pos(door_pos, player_center, size)
		var door_size = Vector2(6, 8)
		draw_rect(Rect2(map_pos - door_size / 2, door_size), door_color)
	
	var player_map_pos = world_to_map_pos(player.global_position, player_center, size)
	var player_size = Vector2(4, 4)
	draw_rect(Rect2(player_map_pos - player_size / 2, player_size), player_color)
	
	draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.5), false, 1.5)

func _process(delta):
	# Периодически проверяем наличие player (каждую секунду)
	if not is_instance_valid(player):
		# Пытаемся найти player заново
		find_player()
		if not is_instance_valid(player):
			queue_redraw()  # Обновляем миникарту с сообщением об ошибке
			return
	
	# Обновляем таймер
	update_timer += delta
	
	# Обновляем миникарту только когда прошло достаточно времени
	if update_timer >= update_interval:
		update_timer = 0.0
		queue_redraw()

# Публичный метод для ручной установки player (если нужно)
func set_player(new_player: CharacterBody2D):
	player = new_player
	queue_redraw()

func debug_print_status():
	print("=== MiniMap Status ===")
	print("Player valid: ", is_instance_valid(player))
	if is_instance_valid(player):
		print("Player name: ", player.name)
		print("Player position: ", player.global_position)
	print("TileMap valid: ", is_instance_valid(tilemap_layer))
	print("Doors count: ", door_positions.size())
