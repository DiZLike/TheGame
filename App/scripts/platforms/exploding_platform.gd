extends BasePlatform
class_name ExplodingPlatform

# === ПАРАМЕТРЫ ===
@export var delay_before_explosion: float = 0.01
@export var blink_duration: float = 0.253
@export var blink_interval: float = 0.05
@export var explosion_force: float = 400.0

# === КОМПОНЕНТЫ ===
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea

# === СОСТОЯНИЯ ===
var is_triggered: bool = false
var is_exploding: bool = false
var player_on_platform: bool = false

# === РЕСУРСЫ ===
var pixel_explosion_scene: PackedScene = preload("res://scenes/effects/pixel_explosion.tscn")

func _setup_platform() -> void:
	if detection_area:
		detection_area.body_entered.connect(_on_detection_entered)
		detection_area.body_exited.connect(_on_detection_exited)

func _on_detection_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not is_triggered and not is_exploding:
		player_on_platform = true
		start_explosion_sequence()

func _on_detection_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_on_platform = false

func start_explosion_sequence() -> void:
	is_triggered = true
	await get_tree().create_timer(delay_before_explosion).timeout
	
	if is_exploding:
		return
	
	start_blinking()

func start_blinking() -> void:
	var blink_timer: float = 0.0
	var is_visible: bool = true
	
	while blink_timer < blink_duration:
		if is_exploding:
			return
		
		is_visible = !is_visible
		if animated_sprite:
			animated_sprite.visible = is_visible
		
		await get_tree().create_timer(blink_interval).timeout
		blink_timer += blink_interval
	
	explode()

func explode() -> void:
	if is_exploding:
		return
	
	is_exploding = true
	disable_platform()
	
	var explosion = pixel_explosion_scene.instantiate()
	get_tree().root.add_child(explosion)
	explosion.explode_from_animated_sprite(animated_sprite, global_position, explosion_force)
	
	animated_sprite.visible = false
	await get_tree().create_timer(0.5).timeout
	queue_free()
