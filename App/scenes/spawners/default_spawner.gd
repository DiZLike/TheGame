@tool
extends Node2D

enum SpawnDirection {
	ALL,        # Все стороны
	LEFT,       # Только левая сторона
	RIGHT,      # Только правая сторона
	TOP,        # Только верхняя сторона
	BOTTOM,     # Только нижняя сторона
}

@export var enemy_scene: PackedScene
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
var is_spawned: bool = false
var spawn_timer: float = 0.0

func _ready():
	# В игре скрываем визуальные элементы, но оставляем функционал
	if not Engine.is_editor_hint():
		if arrow:
			arrow.visible = false
		if sprite:
			sprite.visible = false
	
	if Engine.is_editor_hint():
		# В редакторе ждём немного, чтобы узлы успели загрузиться
		await get_tree().process_frame
		update_arrow_direction()
	else:
		# В игре обновляем направление без визуальных эффектов
		update_arrow_direction()

func update_arrow_direction():
	if not arrow:
		return
	
	# В редакторе показываем стрелку, в игре - нет
	if Engine.is_editor_hint():
		arrow.visible = true
	else:
		arrow.visible = false
	
	# Сбрасываем предыдущие трансформации
	arrow.rotation = 0
	arrow.scale = Vector2(1, 1)
	
	match allowed_direction:
		SpawnDirection.LEFT:
			arrow.scale = Vector2(-1, 1)  # Зеркалим по горизонтали (влево)
		SpawnDirection.RIGHT:
			arrow.scale = Vector2(1, 1)   # Обычное направление (вправо)
		SpawnDirection.TOP:
			arrow.rotation = deg_to_rad(-90)  # Поворот вверх
		SpawnDirection.BOTTOM:
			arrow.rotation = deg_to_rad(90)   # Поворот вниз
		SpawnDirection.ALL:
			arrow.scale = Vector2(1, 1)       # Стандартное направление
			arrow.rotation = 0

func _process(delta):
	if is_on_screen:
		spawn_timer += delta
		if spawn_timer >= spawn_delay:
			spawn_enemy()
			spawn_timer = 0.0

func get_spawn_side_from_camera() -> String:
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return "unknown"
	
	var camera_pos = camera.global_position
	var spawn_pos = global_position
	
	# Определяем разницу позиций
	var diff_x = spawn_pos.x - camera_pos.x
	var diff_y = spawn_pos.y - camera_pos.y
	
	# Для горизонтальных направлений (LEFT, RIGHT, HORIZONTAL) - игнорируем Y
	match allowed_direction:
		SpawnDirection.LEFT, SpawnDirection.RIGHT:
			if diff_x < 0:
				return "left"
			else:
				return "right"
		
		SpawnDirection.TOP, SpawnDirection.BOTTOM:
			if diff_y < 0:
				return "top"
			else:
				return "bottom"
		
		SpawnDirection.ALL:
			# Определяем по максимальному отклонению
			if abs(diff_x) > abs(diff_y):
				return "left" if diff_x < 0 else "right"
			else:
				return "top" if diff_y < 0 else "bottom"
	
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

func get_enemy_direction(side: String):
	# Определяем направление движения врага в зависимости от стороны спавна
	match side:
		"left":
			return "right"  # Слева - бежит направо
		"right":
			return "left"   # Справа - бежит налево
		"top":
			return "right"  # Сверху - бежит направо (или можно random)
		"bottom":
			return "right"  # Снизу - бежит направо
		_:
			return "right"

func _on_visible_on_screen_notifier_2d_screen_entered():
	var side = get_spawn_side_from_camera()
	
	if check_spawn_allowed():
		is_on_screen = true
		spawn_timer = 0.0

func _on_visible_on_screen_notifier_2d_screen_exited():
	is_on_screen = false
	if not on_shot:
		is_spawned = false

func spawn_enemy():
	if not enemy_scene:
		print("Ошибка: enemy_scene не назначен!")
		return
	if is_spawned:
		return
	is_spawned = true
	var enemy = enemy_scene.instantiate()
	
	# Определяем сторону спавна и задаем направление врагу
	var side = get_spawn_side_from_camera()
	var direction = get_enemy_direction(side)
	
	# Устанавливаем направление движения врага
	if enemy.has_method("set_move_direction"):
		enemy.set_move_direction(direction)
	elif enemy.has_method("change_direction"):
		# Альтернативный вариант
		if direction == "left" and enemy.move_direction == enemy.Direction.RIGHT:
			enemy.change_direction()
		elif direction == "right" and enemy.move_direction == enemy.Direction.LEFT:
			enemy.change_direction()
	else:
		# Прямое присвоение свойства
		enemy.move_direction = {
			"left": enemy.Direction.LEFT,
			"right": enemy.Direction.RIGHT,
			"up": enemy.Direction.UP,
			"down": enemy.Direction.DOWN,
		}.get(direction, enemy.Direction.RIGHT)
	
	var spawn_position = global_position
	
	enemy.global_position = spawn_position
	get_tree().current_scene.add_child(enemy)
