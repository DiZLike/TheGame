extends Area2D

@export var id: String
@export var unique_id: String

@onready var sound: AudioStream = preload("res://data/audio/sounds/pickups/coin.wav")

func _ready() -> void:
	# Сразу проверяем, не собран ли уже предмет
	if GameManager.has_unique_item(unique_id):
		queue_free()
		return
	
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		pick_up()

func pick_up() -> void:
	# Добавляем в инвентарь
	var success = GameManager.add_item(1, id, unique_id)
	
	if success:
		_play_pickup_effect()
		queue_free()
	else:
		push_error("Failed to add item to inventory: ", id)

func _play_pickup_effect() -> void:
	AudioManager.play_sfx(sound)
	pass
