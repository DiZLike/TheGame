extends Node2D

enum SpawnMode {
	CAMERA_VISIBLE,  # Спавн только когда виден камерой (только при входе на экран)
	TIMER            # Спавн по таймеру после уничтожения
}

@export var enemy_scene: PackedScene = preload("res://scenes/platforms/destroy_platform.tscn")
@export var spawn_mode: SpawnMode = SpawnMode.CAMERA_VISIBLE
@export var respawn_delay: float = 0.7  # Задержка для режима TIMER
@export var on_shot: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var visibility_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

var current_enemy: Node2D = null
var is_spawning: bool = false
var needs_respawn: bool = false  # Флаг, что нужен респавн при входе на экран
var respawn_timer: Timer = null


func _ready():
	if not Engine.is_editor_hint():
		_hide_editor_visuals()
		
		# Создаем таймер для режима TIMER
		respawn_timer = Timer.new()
		respawn_timer.one_shot = true
		respawn_timer.wait_time = respawn_delay
		respawn_timer.timeout.connect(_on_respawn_timer_timeout)
		add_child(respawn_timer)
		
		# Подключаем сигналы видимости
		if visibility_notifier:
			visibility_notifier.screen_entered.connect(_on_screen_entered)
		
		# Начальный спавн
		spawn_enemy.call_deferred()


func _on_screen_entered():
	if spawn_mode == SpawnMode.CAMERA_VISIBLE and needs_respawn:
		needs_respawn = false
		spawn_enemy()


func _on_respawn_timer_timeout():
	if current_enemy == null and not is_spawning:
		spawn_enemy()


func spawn_enemy():
	if not enemy_scene or current_enemy != null or is_spawning:
		return
	
	is_spawning = true
	
	current_enemy = enemy_scene.instantiate()
	current_enemy.global_position = global_position
	
	if current_enemy.has_signal("tree_exited"):
		current_enemy.tree_exited.connect(_on_enemy_destroyed)
	
	var root = get_tree()
	if root and root.current_scene:
		root.current_scene.add_child.call_deferred(current_enemy)
	
	is_spawning = false


func _on_enemy_destroyed():
	current_enemy = null
	
	if on_shot:
		queue_free()
	else:
		match spawn_mode:
			SpawnMode.CAMERA_VISIBLE:
				# Просто устанавливаем флаг, что нужен респавн при следующем входе на экран
				needs_respawn = true
				
			SpawnMode.TIMER:
				# Для режима таймера - запускаем таймер
				if respawn_timer:
					respawn_timer.start()


func _hide_editor_visuals():
	if sprite:
		sprite.visible = false
