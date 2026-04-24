# player.gd
extends CharacterBody2D
class_name Player

# Сигналы
signal player_respawned(new_position: Vector2)
signal weapon_picked_up()
signal coin_picked_up()

# Ссылки на узлы
@onready var camera_controller: CameraController = $CameraController
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var damage_collision: CollisionShape2D = $Detector/CollisionShape2D
@onready var shoot_point: Marker2D = $ShootPoint

# Ссылки на компоненты
@onready var movement_controller: MovementController = $MovementController
@onready var animation_controller: AnimationController = $AnimationController
@onready var shoot_controller: ShootController = $ShootController
@onready var respawn_controller: RespawnController = $RespawnController
@onready var shield_effect: ShieldEffect = $ShieldEffect
@onready var skin_manager: SkinManager = $SkinManager

var sound_death = preload("res://data/audio/sounds/player/death.wav")

# Флаги
var can_move: bool = true
var is_invincible: bool = false
var original_modulate: Color

func _ready():
	GameManager.register_player(self)
	original_modulate = modulate
	
	# Подключение сигналов
	respawn_controller.player_respawned.connect(_on_respawn_complete)

func _physics_process(delta: float) -> void:
	if GameManager.is_paused:
		return
	
	if respawn_controller.is_respawning:
		return
	
	movement_controller.apply_gravity(delta)
	_handle_input()
	_update_animation()
	#camera_controller._process(delta)
	move_and_slide()
	movement_controller.reset_jump_on_landing()

func _handle_input() -> void:
	var dir_x = Input.get_axis("move_left", "move_right")
	var dir_y = Input.get_axis("move_down", "move_up")
	
	# Приседание
	movement_controller.handle_crouch(dir_x, Input.is_action_pressed("move_down"))
	
	# Прыжок
	movement_controller.handle_jump(Input.is_action_just_pressed("jump"))
	
	# Горизонтальное движение
	movement_controller.handle_horizontal_movement(dir_x)
	
	# Отражение спрайта
	if dir_x != 0 and can_move:
		animation_controller.set_flip_h(dir_x < 0)
	
	# Стрельба
	if Input.is_action_pressed("shoot") and can_move:
		var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if movement_controller.is_crouching:
			input_dir.y = 0
		shoot_controller.try_shoot(input_dir)

func _update_animation() -> void:
	var dir_x = Input.get_axis("move_left", "move_right")
	var dir_y = Input.get_axis("move_down", "move_up")
	animation_controller.update_animation(dir_x, dir_y)

func take_control_away(use_shield: bool = false):
	movement_controller.can_move = false
	can_move = false
	is_invincible = true
	movement_controller.reset_jump_force()
	if use_shield:
		shield_effect.create_shield()
	else:
		modulate = Color(0.7, 0.7, 1.0)

func restore_control():
	movement_controller.can_move = true
	can_move = true
	is_invincible = false
	shield_effect.remove_shield()
	modulate = original_modulate

func take_damage():
	if is_invincible or respawn_controller.is_invincible:
		return
	AudioManager.play_sfx(sound_death, 1, 1, global_position)
	GameManager.remove_lives(1)
	if GameManager.get_lives() >= 0:
		respawn_controller.start_respawn()

func _on_respawn_complete(new_position: Vector2):
	player_respawned.emit(new_position)

func weapon_picked():
	weapon_picked_up.emit()

func is_respawning_now() -> bool:
	return respawn_controller.is_respawning

func force_respawn():
	respawn_controller.force_respawn()

func change_skin(index: int) -> void:
	skin_manager.change_skin(index)

# Обработчики столкновений
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy") or body.is_in_group("immortal_enemy") or body.is_in_group("terrain_deadly"):
		if not is_invincible and not respawn_controller.is_respawning:
			take_damage()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_bullet"):
		if not is_invincible and not respawn_controller.is_respawning:
			take_damage()
	if area.is_in_group("coin"):
		coin_picked_up.emit()
