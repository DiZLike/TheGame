extends StaticEnemy

# ============================================
# ВРАГ БРОСАЮЩИЙ ФАЕРБОЛЫ - СТАТИЧНЫЙ ВРАГ
# ============================================

const GRAVITY: float = 700.0

@export var min_fireballs: int = 1
@export var max_fireballs: int = 3
@export var min_throw_force: float = 250.0
@export var max_throw_force: float = 300.0

var fireball_scene: PackedScene = preload("res://scenes/bullets/enemy/fireball1.tscn")

func _ready() -> void:
	# Устанавливаем параметры ДО вызова родительского _ready()
	_attack_pattern = "spread"    # Веер фаерболов с разбросом
	_movement_type = "none"       # Стоит на месте
	
	super._ready()

func _physics_process(delta: float) -> void:
	if _is_exploding:
		return
	
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	move_and_slide()
	
	if is_player_valid():
		_face_player()

func _on_activate() -> void:
	# Случайное количество фаерболов за бросок
	attacks_per_cycle = randi_range(min_fireballs, max_fireballs)
	super._on_activate()

func _execute_attack() -> void:
	if not fireball_scene or not is_player_valid():
		return
	
	var fireball = fireball_scene.instantiate()
	get_tree().root.add_child(fireball)
	
	fireball.set_shooter(self)
	
	var spawn_offset = 10 if not animated_sprite.flip_h else -10
	fireball.global_position = global_position + Vector2(spawn_offset, -10)
	
	var direction_to_player = (_player.global_position - global_position).normalized()
	var throw_force = randf_range(min_throw_force, max_throw_force)
	var vertical_force = randf_range(-300.0, -100.0)
	var throw_vector = Vector2(direction_to_player.x * throw_force, vertical_force)
	
	fireball.apply_force(throw_vector)
