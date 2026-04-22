# respawn_controller.gd
extends Node
class_name RespawnController

signal player_respawned(new_position: Vector2)

const RESPAWN_DELAY: float = 1.5
const INVINCIBILITY_DURATION: float = 2.0
const BLINK_INTERVAL: float = 0.1
const EXPLOSION_FORCE: float = 200.0

var is_respawning: bool = false
var is_invincible: bool = false
var blink_tween: Tween = null
var pixel_explosion_scene: PackedScene = preload("res://scenes/effects/pixel_explosion.tscn")

@onready var player: CharacterBody2D = $".."
@onready var animated_sprite: AnimatedSprite2D = $"../AnimatedSprite2D"
@onready var damage_collision: CollisionShape2D = $"../Detector/CollisionShape2D"
@onready var movement_controller: MovementController = $"../MovementController"

func start_respawn():
	if is_respawning:
		return
	
	is_respawning = true
	movement_controller.can_move = false
	
	call_deferred("pixel_explode")
	
	await get_tree().create_timer(RESPAWN_DELAY).timeout
	
	player.global_position = _find_spawn()
	player.velocity = Vector2.ZERO
	movement_controller.is_jumping = false
	movement_controller.is_crouching = false
	movement_controller._reset_collider()
	
	player.visible = true
	damage_collision.disabled = false
	movement_controller.can_move = true
	
	_activate_blink()
	
	is_respawning = false
	WeaponManager.change_weapon(0)

func pixel_explode():
	var e = pixel_explosion_scene.instantiate()
	get_tree().root.add_child(e)
	e.explode_from_animated_sprite(animated_sprite, player.global_position, EXPLOSION_FORCE)
	
	player.visible = false
	damage_collision.disabled = true

func _find_spawn() -> Vector2:
	var spawn_points = player.get_node("../Environment/SpawnPoints")
	if not spawn_points:
		return Vector2.ZERO
	
	var nearest = null
	var min_distance = INF
	
	for child in spawn_points.get_children():
		if child is Node2D:
			var dist = player.global_position.distance_to(child.global_position)
			if dist < min_distance:
				min_distance = dist
				nearest = child
	
	return nearest.global_position if nearest else Vector2.ZERO

func _activate_blink():
	is_invincible = true
	
	if blink_tween:
		blink_tween.kill()
	
	blink_tween = create_tween().set_loops()
	blink_tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 0.3), BLINK_INTERVAL / 2)
	blink_tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 1.0), BLINK_INTERVAL / 2)
	
	await get_tree().create_timer(INVINCIBILITY_DURATION).timeout
	
	if blink_tween:
		blink_tween.kill()
	
	animated_sprite.modulate = Color.WHITE
	player.modulate = player.original_modulate
	is_invincible = false
	
	player_respawned.emit(player.global_position)

func force_respawn():
	if not is_respawning:
		start_respawn()
