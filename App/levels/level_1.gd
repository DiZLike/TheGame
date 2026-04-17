extends Node2D

@export var level_music: AudioStream

@onready var glitch_layer = $UI/MiniMap/GlitchLayer
@onready var tile_gnd = $"Environment/Tiles/TileGND"
@onready var dialogue_box = $UI/DialogLayer
@onready var game_menu: CanvasLayer = $UI/GameMenu
@onready var player = $Player

func _ready() -> void:
	if dialogue_box:
		dialogue_box.method_executed.connect(_on_dialogue_method_executed)
		dialogue_box.dialogue_finished.connect(_on_dialogue_finished)
	# Запускаем музыку уровня
	AudioManager.set_music(level_music)

@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	pass
	
# Меню
func _input(event: InputEvent) -> void:
	if GameManager.is_paused:
		return
	if event.is_action_pressed("menu"):
		get_tree().paused = true
		GameManager.is_paused = true
		game_menu.visible = true

func show_glitch(time: float):
	if glitch_layer:
		glitch_layer.visible = true
		if time > 0:
			await get_tree().create_timer(time).timeout
			hide_glitch()

func hide_glitch():
	if glitch_layer:
		glitch_layer.visible = false

func _on_dialogue_method_executed(method_name: String, success: bool):
	if success:
		print("✓ Метод '", method_name, "' успешно выполнен")
	else:
		print("✗ Ошибка при выполнении метода '", method_name, "'")

func _on_dialogue_finished():
	print("Диалог завершен")
	
# Методы диалогов
func _01_create_glitch_enemy():
	var enemy_scene: PackedScene = preload("res://scenes/enemy/schoolboy.tscn")
	var pos: Node2D = $Environment/Markers/Marker
	var enemy = enemy_scene.instantiate()
	enemy.global_position = pos.global_position
	enemy.set_move_direction("left")
	get_tree().current_scene.add_child(enemy)

# Методы активации триггеров
func _01_2_activate():
	var trig: DialogueTrigger = $Environment/DialogueTriggers/DTrig2
	trig.activate()

func weapon_training_enable():
	GameManager.dialogue_trig["weapon_training_enable"] = true
