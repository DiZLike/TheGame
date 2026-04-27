# base_spawner.gd
@tool
class_name BaseSpawner
extends Node2D

enum SpawnDirection { ALL, LEFT, RIGHT, TOP, BOTTOM }

@export var on_shot: bool = false
@export var allowed_direction: SpawnDirection = SpawnDirection.ALL:
	set(value):
		allowed_direction = value
		if is_inside_tree() or Engine.is_editor_hint():
			update_arrow_direction()

@onready var arrow: AnimatedSprite2D = $Arrow
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var is_on_screen: bool = false


func _ready():
	if not Engine.is_editor_hint():
		_hide_editor_visuals()
	
	update_arrow_direction()
	
	if Engine.is_editor_hint():
		await get_tree().process_frame
		update_arrow_direction()


func _hide_editor_visuals():
	if arrow:
		arrow.visible = false
	if sprite:
		sprite.visible = false


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


func get_spawn_side_from_camera() -> String:
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
			if abs(diff.x) > abs(diff.y):
				return "left" if diff.x < 0 else "right"
			return "top" if diff.y < 0 else "bottom"
	
	return "unknown"


func check_spawn_allowed() -> bool:
	var side = get_spawn_side_from_camera()
	
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


# Виртуальные методы для переопределения в наследниках
func _on_visible_on_screen_notifier_2d_screen_entered():
	if check_spawn_allowed():
		is_on_screen = true


func _on_visible_on_screen_notifier_2d_screen_exited():
	is_on_screen = false
	if on_shot:
		queue_free()


func spawn_enemy():
	# Должен быть переопределён в наследниках
	push_error("spawn_enemy() must be overridden in child class")
