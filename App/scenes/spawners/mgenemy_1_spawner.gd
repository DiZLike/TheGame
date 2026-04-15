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
@export var allowed_direction: SpawnDirection = SpawnDirection.ALL:
	set(value):
		allowed_direction = value
		if is_inside_tree() or Engine.is_editor_hint():
			update_arrow_direction()

@onready var arrow: AnimatedSprite2D = $Arrow
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var is_on_screen: bool = false
var current_enemy: Node2D = null
var has_spawned_in_current_view: bool = false
var is_spawning: bool = false  # ← Защита от повторного спавна во время задержки


func _ready():
	if not Engine.is_editor_hint():
		_hide_editor_visuals()
	
	update_arrow_direction()
	
	if Engine.is_editor_hint():
		await get_tree().process_frame
		update_arrow_direction()


func _process(_delta):
	# Спавним только если: на экране, нет врага, не спавним прямо сейчас, и ещё не спавнили в этот заход
	if is_on_screen and current_enemy == null and not is_spawning and not has_spawned_in_current_view:
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
		# Не сбрасываем has_spawned_in_current_view здесь
		# Он сбрасывается только при выходе или смерти врага


func _on_visible_on_screen_notifier_2d_screen_exited():
	is_on_screen = false
	if not current_enemy:
		has_spawned_in_current_view = false  # ← Сброс при выходе из кадра
		is_spawning = false  # ← Отменяем ожидающий спавн
	if on_shot:
		queue_free()

func spawn_enemy():
	if not enemy_scene or current_enemy != null or is_spawning or has_spawned_in_current_view:
		return
	
	is_spawning = true
	
	# Проверяем, что условия всё ещё валидны после задержки
	if not is_on_screen or current_enemy != null:
		is_spawning = false
		return
	
	current_enemy = enemy_scene.instantiate()
	current_enemy.global_position = global_position
	
	# Подключаем сигнал уничтожения
	if current_enemy.has_signal("tree_exited"):
		current_enemy.tree_exited.connect(_on_enemy_destroyed)
	
	get_tree().current_scene.add_child(current_enemy)
	
	has_spawned_in_current_view = true
	is_spawning = false


func _on_enemy_destroyed():
	current_enemy = null
	# ВАЖНО: Не сбрасываем has_spawned_in_current_view здесь
	# Если враг умер, но спавнер всё ещё на экране — НЕ СПАВНИМ повторно
	# Спавн произойдёт только после выхода и повторного входа спавнера в кадр


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
			if abs(diff.x) > abs(diff.y):
				return "left" if diff.x < 0 else "right"
			else:
				return "top" if diff.y < 0 else "bottom"
	
	return "unknown"


func _hide_editor_visuals():
	if arrow:
		arrow.visible = false
	if sprite:
		sprite.visible = false
