@tool
extends Node2D

enum SpawnDirection {
	ALL,
	LEFT,
	RIGHT,
	TOP,
	BOTTOM,
}

@export var enemy_scene: PackedScene = preload("res://scenes/enemy/mg_enemy_1.tscn")
@export var on_shot: bool = false
@export var spawn_delay: float = 2.0
@export var allowed_direction: SpawnDirection = SpawnDirection.ALL:
	set(value):
		allowed_direction = value
		if is_inside_tree() or Engine.is_editor_hint():
			update_arrow_direction()

@onready var arrow: AnimatedSprite2D = $Arrow
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var is_on_screen: bool = false
var current_enemy: Node2D = null
var can_spawn: bool = true


func _ready():
	if not Engine.is_editor_hint():
		_hide_editor_visuals()
	
	update_arrow_direction()
	
	if Engine.is_editor_hint():
		await get_tree().process_frame
		update_arrow_direction()


func _process(delta):
	if is_on_screen and can_spawn and current_enemy == null:
		can_spawn = false
		await get_tree().create_timer(spawn_delay).timeout
		spawn_enemy()


func update_arrow_direction():
	if not arrow:
		return
	
	arrow.visible = Engine.is_editor_hint()
	arrow.rotation = 0
	arrow.scale = Vector2.ONE
	
	match allowed_direction:
		SpawnDirection.LEFT:
			arrow.scale = Vector2(-1, 1)
		SpawnDirection.RIGHT:
			arrow.scale = Vector2.ONE
		SpawnDirection.TOP:
			arrow.rotation = deg_to_rad(-90)
		SpawnDirection.BOTTOM:
			arrow.rotation = deg_to_rad(90)
		SpawnDirection.ALL:
			arrow.scale = Vector2.ONE
			arrow.rotation = 0


func _on_visible_on_screen_notifier_2d_screen_entered():
	if check_spawn_allowed():
		is_on_screen = true
		can_spawn = true


func _on_visible_on_screen_notifier_2d_screen_exited():
	is_on_screen = false
	if not on_shot and current_enemy:
		current_enemy.queue_free()
		current_enemy = null


func spawn_enemy():
	if not enemy_scene or current_enemy != null:
		return
	
	current_enemy = enemy_scene.instantiate()
	current_enemy.global_position = global_position
	
	if current_enemy.has_signal("tree_exited"):
		current_enemy.tree_exited.connect(_on_enemy_destroyed)
	
	get_tree().current_scene.add_child(current_enemy)


func _on_enemy_destroyed():
	current_enemy = null


func check_spawn_allowed() -> bool:
	var side = _get_spawn_side_from_camera()
	
	match allowed_direction:
		SpawnDirection.LEFT:
			return side == "left"
		SpawnDirection.RIGHT:
			return side == "right"
		SpawnDirection.TOP:
			return side == "top"
		SpawnDirection.BOTTOM:
			return side == "bottom"
		SpawnDirection.ALL:
			return true
	
	return false


func _get_spawn_side_from_camera() -> String:
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return "unknown"
	
	var diff = global_position - camera.global_position
	
	match allowed_direction:
		SpawnDirection.LEFT, SpawnDirection.RIGHT:
			return "left" if diff.x < 0 else "right"
		SpawnDirection.TOP, SpawnDirection.BOTTOM:
			return "top" if diff.y < 0 else "bottom"
		SpawnDirection.ALL:
			return "left" if abs(diff.x) > abs(diff.y) and diff.x < 0 else "right" if abs(diff.x) > abs(diff.y) else "top" if diff.y < 0 else "bottom"
	
	return "unknown"


func _hide_editor_visuals():
	if arrow:
		arrow.visible = false
	if sprite:
		sprite.visible = false
