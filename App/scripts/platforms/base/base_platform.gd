extends CharacterBody2D
class_name BasePlatform

# === ОБЩИЕ ПАРАМЕТРЫ ===
@export var platform_color: Color = Color.WHITE
@export var is_visible_on_start: bool = true

# === ОБЩИЕ КОМПОНЕНТЫ ===
@onready var sprite: Node2D = $Sprite2D if has_node("Sprite2D") else $AnimatedSprite2D if has_node("AnimatedSprite2D") else null
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# === СОСТОЯНИЯ ===
var is_active: bool = true
var is_disabled: bool = false

func _ready() -> void:
	if Engine.is_editor_hint():
		# В редакторе только отображаем спрайт
		if sprite:
			sprite.visible = is_visible_on_start
			_modulate_sprite(platform_color)
		return
	
	if sprite:
		sprite.visible = is_visible_on_start
		_modulate_sprite(platform_color)
	
	_setup_platform()

# Виртуальные методы (переопределяются в наследниках)
func _setup_platform() -> void:
	pass

func _on_platform_enter(body: Node2D) -> void:
	pass

func _on_platform_exit(body: Node2D) -> void:
	pass

func disable_platform() -> void:
	is_disabled = true
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	
	if has_node("DetectionArea"):
		var area = get_node("DetectionArea")
		area.set_deferred("monitoring", false)
		area.set_deferred("monitorable", false)

func enable_platform() -> void:
	is_disabled = false
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	
	if has_node("DetectionArea"):
		var area = get_node("DetectionArea")
		area.set_deferred("monitoring", true)
		area.set_deferred("monitorable", true)

func _modulate_sprite(color: Color) -> void:
	if sprite and sprite is CanvasItem:
		sprite.modulate = color

# Обработка столкновений с игроком
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_on_platform_enter(body)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_on_platform_exit(body)
