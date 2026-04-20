extends Node2D

@export var level_music: AudioStream

@onready var glitch_layer = $UI/MiniMap/GlitchLayer
@onready var tile_gnd = $"Environment/Tiles/TileGND"
@onready var dialogue_box = $UI/DialogLayer
@onready var game_menu: CanvasLayer = $UI/GameMenu
@onready var player = $Player
@onready var lives_panel = $UI/LivesPanel

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
	if lives_panel:
		lives_panel.visible = true
	if player:
		player.restore_control()

func show_dialogue(dialogue_id: String, start_node: String = "d1") -> void:
	if not dialogue_box:
		push_error("DialogueBox not registered!")
		return
	
	if player:
		player.take_control_away(true)
	
	if lives_panel:
		lives_panel.visible = false
	
	dialogue_box.dialogue_finished.connect(_on_dialogue_finished, CONNECT_ONE_SHOT)
	dialogue_box.start_dialogue(dialogue_id, start_node)

# Методы диалогов
func _01_create_glitch_enemy():
	var enemy_scene: PackedScene = preload("res://scenes/enemy/schoolboy.tscn")
	var pos: Node2D = $Environment/Markers/Marker
	var enemy = enemy_scene.instantiate()
	enemy.global_position = pos.global_position
	enemy.set_move_direction("left")
	get_tree().current_scene.add_child(enemy)
	
func barrier_1_puzzle_activate():
	$"Environment/BarrierSources/Barrier Source 1".set_enable()
	$"Environment/BarrierSources/Barrier Source 2".set_enable()
	$"Environment/BarrierSources/Barrier Source 3".set_enable()
	$Environment/SpawnersCapsule/CapsuleSpawner6.enable = true
	BarrierSourceManager.group_destroyed.connect(group_destroyed)

# Методы барьеров
func group_destroyed(group_name: String):
	if group_name == "b1":
		$Environment/Bags/Bug.queue_free()
		$Environment/SpawnersCapsule/CapsuleSpawner6.queue_free()
		show_dialogue("/level_01/null_hint_barrier_01_destroy", "d1")

# Методы активации триггеров
func _01_2_activate():
	var trig: DialogueTrigger = $Environment/DialogueTriggers/DTrig2
	trig.activate()

func weapon_training_enable():
	GameManager.dialogue_trig["weapon_training_enable"] = true
