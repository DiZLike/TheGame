@tool
extends BaseSpawner

@export var min_fireballs: int = 1
@export var max_fireballs: int = 3
@export var min_throw_force: float = 250.0
@export var max_throw_force: float = 300.0
@export var min_vertical_force: float = -100.0
@export var max_vertical_force: float = -300.0
@export_range(0, 5) var attack_interval: float = 2.5
@export_range(0, 5) var attack_delay: float = 0.4
@export var attack_on_first_appearance: bool = true
@export var health: int = 100
@export var score: int = 0

@onready var enemy_scene: PackedScene = preload("res://scenes/enemy/blazeman.tscn")

var current_enemy: Blazeman = null
var has_spawned_in_current_view: bool = false
var is_spawning: bool = false


func _process(_delta):
	if is_on_screen and current_enemy == null and not is_spawning and not has_spawned_in_current_view:
		spawn_enemy()


func _on_visible_on_screen_notifier_2d_screen_entered():
	if check_spawn_allowed():
		is_on_screen = true


func _on_visible_on_screen_notifier_2d_screen_exited():
	is_on_screen = false
	if not current_enemy:
		has_spawned_in_current_view = false
		is_spawning = false
	super._on_visible_on_screen_notifier_2d_screen_exited()


func spawn_enemy():
	if not enemy_scene or current_enemy != null or is_spawning or has_spawned_in_current_view:
		return
	
	is_spawning = true
	
	if not is_on_screen or current_enemy != null:
		is_spawning = false
		return
	
	current_enemy = enemy_scene.instantiate()
	
	current_enemy.min_fireballs = min_fireballs
	current_enemy.max_fireballs = max_fireballs
	current_enemy.min_throw_force = min_throw_force
	current_enemy.max_throw_force = max_throw_force
	current_enemy.min_vertical_force = min_vertical_force
	current_enemy.max_vertical_force = max_vertical_force
	current_enemy.attack_interval = attack_interval
	current_enemy.attack_delay = attack_delay
	current_enemy.attack_on_first_appearance = attack_on_first_appearance
	current_enemy.health = health
	current_enemy.score = score
	
	current_enemy.global_position = global_position
	
	if current_enemy.has_signal("tree_exited"):
		current_enemy.tree_exited.connect(_on_enemy_destroyed)
	
	get_tree().current_scene.add_child(current_enemy)
	
	has_spawned_in_current_view = true
	is_spawning = false


func _on_enemy_destroyed():
	current_enemy = null
