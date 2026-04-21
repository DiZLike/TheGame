@tool
extends Node2D

enum SpawnDirection { ALL, LEFT, RIGHT, TOP, BOTTOM }

@export var on_shot: bool = false
@export var spawn_delay: float = 0
@export var max_enemies: int = 1
@export var allowed_direction: SpawnDirection = SpawnDirection.ALL:
	set(value):
		allowed_direction = value
		if is_inside_tree() or Engine.is_editor_hint():
			update_arrow_direction()

@onready var arrow: AnimatedSprite2D = $Arrow
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var enemy_scene = preload("res://scenes/enemy/schoolboy.tscn")
@onready var visibility_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

var is_on_screen: bool = false
var is_spawned: bool = false
var can_spawn: bool = true
var spawned_enemies: Array = []
var current_enemy_count: int:
	get:
		return spawned_enemies.filter(func(e): return is_instance_valid(e)).size()

func _ready():
	if not Engine.is_editor_hint():
		if arrow: arrow.visible = false
		if sprite: sprite.visible = false
		update_arrow_direction()
		
		if visibility_notifier:
			if not visibility_notifier.screen_entered.is_connected(_on_visible_on_screen_notifier_2d_screen_entered):
				visibility_notifier.screen_entered.connect(_on_visible_on_screen_notifier_2d_screen_entered)
			if not visibility_notifier.screen_exited.is_connected(_on_visible_on_screen_notifier_2d_screen_exited):
				visibility_notifier.screen_exited.connect(_on_visible_on_screen_notifier_2d_screen_exited)
	else:
		await get_tree().process_frame
		update_arrow_direction()

func update_arrow_direction():
	if not arrow: return
	
	arrow.visible = Engine.is_editor_hint()
	arrow.rotation = 0
	arrow.scale = Vector2(1, 1)
	
	match allowed_direction:
		SpawnDirection.LEFT:   arrow.scale = Vector2(-1, 1)
		SpawnDirection.TOP:    arrow.rotation = deg_to_rad(-90)
		SpawnDirection.BOTTOM: arrow.rotation = deg_to_rad(90)

func get_spawn_side_from_camera() -> String:
	var camera = get_viewport().get_camera_2d()
	if not camera: return "unknown"
	
	var diff = global_position - camera.global_position
	
	match allowed_direction:
		SpawnDirection.LEFT, SpawnDirection.RIGHT:
			return "left" if diff.x < 0 else "right"
		SpawnDirection.TOP, SpawnDirection.BOTTOM:
			return "top" if diff.y < 0 else "bottom"
		SpawnDirection.ALL:
			if abs(diff.x) > abs(diff.y):
				return "left" if diff.x < 0 else "right"
			return "top" if diff.y < 0 else "bottom"
	return "unknown"

func check_spawn_allowed() -> bool:
	var side = get_spawn_side_from_camera()
	match allowed_direction:
		SpawnDirection.LEFT:   return side == "left"
		SpawnDirection.RIGHT:  return side == "right"
		SpawnDirection.TOP:    return side == "top"
		SpawnDirection.BOTTOM: return side == "bottom"
		SpawnDirection.ALL:    return true
	return false

func get_enemy_direction_to_player() -> String:
	# Находим игрока
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		# Если игрок не найден, используем камеру как точку отсчета
		var camera = get_viewport().get_camera_2d()
		if camera:
			var diff_to_camera = global_position - camera.global_position
			return "right" if diff_to_camera.x < 0 else "left"
		return "right"
	
	# Определяем направление от врага к игроку
	var diff_to_player = player.global_position - global_position
	
	# Возвращаем направление, куда должен смотреть враг
	# Учитываем, что стандартно враг смотрит влево
	if diff_to_player.x > 0:
		return "right"  # Игрок справа -> враг должен смотреть вправо
	else:
		return "left"   # Игрок слева -> враг должен смотреть влево

func _on_visible_on_screen_notifier_2d_screen_entered():
	if not check_spawn_allowed():
		return
	
	is_on_screen = true
	
	if can_spawn and not is_spawned and current_enemy_count < max_enemies:
		if spawn_delay > 0:
			await get_tree().create_timer(spawn_delay).timeout
			if not is_on_screen:
				return
		
		spawn_enemy()

func _on_visible_on_screen_notifier_2d_screen_exited():
	is_on_screen = false
	
	if not on_shot:
		is_spawned = false
		can_spawn = true
		cleanup_invalid_enemies()

func cleanup_invalid_enemies():
	spawned_enemies = spawned_enemies.filter(func(e): return is_instance_valid(e))

func spawn_enemy():
	if not is_on_screen or is_spawned or current_enemy_count >= max_enemies:
		return
	
	is_spawned = true
	can_spawn = false
	
	var enemy = enemy_scene.instantiate()
	enemy.global_position = global_position
	get_tree().current_scene.add_child(enemy)
	
	spawned_enemies.append(enemy)
	enemy.tree_exited.connect(_on_enemy_destroyed.bind(enemy))
	
	# Устанавливаем направление лицом к игроку
	var direction = get_enemy_direction_to_player()
	enemy.set_move_direction(direction)
	
	cleanup_invalid_enemies()
	if on_shot:
		queue_free()

func _on_enemy_destroyed(enemy):
	spawned_enemies.erase(enemy)
	cleanup_invalid_enemies()
