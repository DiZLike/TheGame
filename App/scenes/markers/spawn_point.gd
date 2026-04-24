extends Node2D
class_name SpawnPoint

var active: bool = false
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	# В игре скрываем визуальные элементы, но оставляем функционал
	if not Engine.is_editor_hint():
		if sprite:
			sprite.visible = false

func is_active() -> bool:
	return active

func screen_entered() -> void:
	if not active:
		print("Спавнпоинт активирован")
	active = true
