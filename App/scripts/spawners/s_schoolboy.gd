@tool
extends BaseSpawner

@export var move_speed: float = 100.0
@export var jump_velocity: float = -175.0
@export var max_enemies: int = 1
@export var invert: bool = false:
	set(value):
		invert = value
		if is_inside_tree() or Engine.is_editor_hint():
			update_arrow_direction()
@export var invert_x: bool = false
@export var invert_y: bool = false

@onready var enemy_scene = preload("res://scenes/enemy/schoolboy.tscn")
@onready var visibility_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

var is_spawned: bool = false
var can_spawn: bool = true
var spawned_enemies: Array = []
var current_enemy_count: int:
	get:
		return spawned_enemies.filter(func(e): return is_instance_valid(e)).size()


func _ready():
	super._ready()
	if not Engine.is_editor_hint():
		if visibility_notifier:
			if not visibility_notifier.screen_entered.is_connected(_on_visible_on_screen_notifier_2d_screen_entered):
				visibility_notifier.screen_entered.connect(_on_visible_on_screen_notifier_2d_screen_entered)
			if not visibility_notifier.screen_exited.is_connected(_on_visible_on_screen_notifier_2d_screen_exited):
				visibility_notifier.screen_exited.connect(_on_visible_on_screen_notifier_2d_screen_exited)


func update_arrow_direction():
	super.update_arrow_direction()
	if not arrow: return
	
	if invert:
		arrow.modulate = Color.RED
	else:
		arrow.modulate = Color.WHITE


func get_enemy_direction_to_player() -> String:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		var camera = get_viewport().get_camera_2d()
		if camera:
			var diff_to_camera = global_position - camera.global_position
			return "right" if diff_to_camera.x < 0 else "left"
		return "right"
	
	var diff_to_player = player.global_position - global_position
	return "right" if diff_to_player.x > 0 else "left"


func get_inverted_spawn_position() -> Vector2:
	var camera = get_viewport().get_camera_2d()
	if not camera: return global_position
	
	var offset = global_position - camera.global_position
	
	match allowed_direction:
		SpawnDirection.LEFT, SpawnDirection.RIGHT:
			offset.x = -offset.x
		SpawnDirection.TOP, SpawnDirection.BOTTOM:
			offset.y = -offset.y
		SpawnDirection.ALL:
			if invert_x:
				offset.x = -offset.x
			if invert_y:
				offset.y = -offset.y
	
	return camera.global_position + offset


func _on_visible_on_screen_notifier_2d_screen_entered():
	if not check_spawn_allowed():
		return
	
	is_on_screen = true
	
	if can_spawn and not is_spawned and current_enemy_count < max_enemies:
		spawn_enemy()


func _on_visible_on_screen_notifier_2d_screen_exited():
	is_on_screen = false
	
	if not on_shot:
		is_spawned = false
		can_spawn = true
		cleanup_invalid_enemies()
	
	super._on_visible_on_screen_notifier_2d_screen_exited()


func cleanup_invalid_enemies():
	spawned_enemies = spawned_enemies.filter(func(e): return is_instance_valid(e))


func spawn_enemy():
	if not is_on_screen or is_spawned or current_enemy_count >= max_enemies:
		return
	
	is_spawned = true
	can_spawn = false
	
	var enemy = enemy_scene.instantiate() as Schoolboy
	enemy.move_speed = move_speed
	enemy.jump_velocity = jump_velocity
	
	if invert:
		enemy.global_position = get_inverted_spawn_position()
	else:
		enemy.global_position = global_position
	
	get_tree().current_scene.add_child(enemy)
	
	spawned_enemies.append(enemy)
	enemy.tree_exited.connect(_on_enemy_destroyed.bind(enemy))
	
	var direction = get_enemy_direction_to_player()
	if invert:
		direction = "left" if direction == "right" else "right"
	enemy.set_move_direction(direction)
	
	cleanup_invalid_enemies()
	if on_shot:
		queue_free()


func _on_enemy_destroyed(enemy):
	spawned_enemies.erase(enemy)
	cleanup_invalid_enemies()
