extends CharacterBody2D

const WeaponsType = preload("res://scripts/weapon_types.gd")

@export var speed: float = 200.0
@export var amplitude: float = 75.0
@export var frequency: float = 2.0
@export var move_direction: Direction = Direction.RIGHT
@export var weapon_type: WeaponsType.WeaponType = WeaponsType.WeaponType.DEFAULT

enum Direction { LEFT, RIGHT, UP, DOWN }
var pickup: PackedScene
var time: float = 0.0
var base_y: float
var base_x: float
var direction: Vector2:
	get:
		return {
			Direction.LEFT: Vector2.LEFT,
			Direction.RIGHT: Vector2.RIGHT,
			Direction.UP: Vector2.UP,
			Direction.DOWN: Vector2.DOWN,
		}.get(move_direction, Vector2.ZERO)
		
var _on_hit: bool = false
var spawn_only_if_player_doesnt_have: bool = false

func _ready():
	if weapon_type == WeaponsType.WeaponType.DEFAULT:
		pickup = preload("res://scenes/pickups/d_pickup.tscn")
	elif weapon_type == WeaponsType.WeaponType.MACHINEGUN:
		pickup = preload("res://scenes/pickups/m_pickup.tscn")
	elif weapon_type == WeaponsType.WeaponType.SPREADGUN:
		pickup = preload("res://scenes/pickups/s_pickup.tscn")
	elif weapon_type == WeaponsType.WeaponType.ROCKET:
		pickup = preload("res://scenes/pickups/r_pickup.tscn")
	elif weapon_type == WeaponsType.WeaponType.HOMING:
		pickup = preload("res://scenes/pickups/h_pickup.tscn")
	base_y = position.y
	base_x = position.x

func _physics_process(delta):
	time += delta
	
	if move_direction == Direction.LEFT or move_direction == Direction.RIGHT:
		velocity = Vector2(speed * direction.x, 0)
		position.y = base_y + sin(time * frequency * TAU) * amplitude
	elif move_direction == Direction.UP or move_direction == Direction.DOWN:
		velocity = Vector2(0, speed * direction.y)  # Исправлено: скорость должна идти в компоненту Y
		position.x = base_x + sin(time * frequency * TAU) * amplitude
	# Перемещаем объект
	move_and_slide()
	
@warning_ignore("unused_parameter")
func on_hit(damage: int, bullet: String):
	call_deferred("pickup_spawn")

func pickup_spawn():
	if _on_hit:
		return
	_on_hit = true
	var pic = pickup.instantiate() as CharacterBody2D
	pic.spawn_only_if_player_doesnt_have = spawn_only_if_player_doesnt_have
	pic.global_position = global_position
	pic.velocity.y = -200
	get_tree().current_scene.add_child(pic)
	queue_free()
