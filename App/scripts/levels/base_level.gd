extends Node2D
class_name BaseLevel

#region Экспортируемые переменные
@export var level_music: AudioStream
@export var ambient_music: AudioStream
#endregion

#region Узлы (onready)
@onready var glitch_layer: Control = $UI/MiniMap/GlitchLayer
@onready var dialogue_box: DialogueBox = $UI/DialogLayer
@onready var game_menu: CanvasLayer = $UI/GameMenu
@onready var player: Player = $Player
@onready var lives_panel: CanvasLayer = $UI/LivesPanel
#endregion

#region Жизненный цикл
func _ready() -> void:
	_setup_dialogue_signals()
	_setup_music()
	_setup_player_signals()
	_on_level_specific_ready()

func _input(event: InputEvent) -> void:
	if GameManager.is_paused:
		return
	if event.is_action_pressed("menu"):
		_pause_game()
#endregion

#region Инициализация (private)
func _setup_dialogue_signals() -> void:
	if dialogue_box:
		dialogue_box.method_executed.connect(_on_dialogue_method_executed)

func _setup_music() -> void:
	AudioManager.stop_music()
	if ambient_music:
		AudioManager.set_music(ambient_music)
	elif level_music:
		AudioManager.set_music(level_music)

func _setup_player_signals() -> void:
	if player:
		player.weapon_picked_up.connect(_on_weapon_picked_up)
		player.coin_picked_up.connect(_on_coin_picked_up)
#endregion

#region Управление игрой (пауза)
func _pause_game() -> void:
	get_tree().paused = true
	GameManager.is_paused = true
	if game_menu:
		game_menu.visible = true
#endregion

#region Визуальные эффекты (глитч)
func show_glitch(duration: float = 0.0) -> void:
	if not glitch_layer:
		return
	glitch_layer.visible = true
	if duration > 0:
		await get_tree().create_timer(duration).timeout
		hide_glitch()

func hide_glitch() -> void:
	if glitch_layer:
		glitch_layer.visible = false
#endregion

#region Система диалогов
func show_dialogue(dialogue_id: String, start_node: String = "d1", take_control: bool = true) -> void:
	if not dialogue_box:
		push_error("DialogueBox not found!")
		return
	
	_prepare_for_dialogue(take_control)
	dialogue_box.dialogue_finished.connect(_on_dialogue_finished, CONNECT_ONE_SHOT)
	dialogue_box.start_dialogue(dialogue_id, start_node)

func _prepare_for_dialogue(take_control: bool = true) -> void:
	if player:
		if take_control:
			player.take_control_away(true)
	if lives_panel:
		lives_panel.visible = false

func _on_dialogue_finished() -> void:
	if lives_panel:
		lives_panel.visible = true
	if player:
		player.restore_control()

func _on_dialogue_method_executed(method_name: String, success: bool) -> void:
	if success:
		print("✓ Метод '", method_name, "' успешно выполнен в ", name)
	else:
		push_warning("✗ Ошибка при выполнении метода '", method_name, "' в ", name)
#endregion

#region Система обучения (оружие)
func is_first_weapon_pickup() -> bool:
	return not GameManager._player_data["game"]["weapon_training_completed"]

func is_weapon_training_completed() -> bool:
	return GameManager._player_data["game"]["weapon_training_completed"]

func complete_weapon_training() -> void:
	GameManager._player_data["game"]["weapon_training_completed"] = true

func _on_weapon_picked_up() -> void:
	if is_first_weapon_pickup():
		_show_training_dialogue()
func _on_coin_picked_up() -> void:
	pass

func _show_training_dialogue() -> void:
	if not GameManager.dialogue_trig.get("weapon_training_enable", false):
		return
	
	if is_weapon_training_completed():
		return
	
	complete_weapon_training()
	show_dialogue("/level_01/03_weapon_tutorial", "d1", false)
#endregion

#region Виртуальные методы (для переопределения)
func _on_level_specific_ready() -> void:
	"""Переопределяется в дочерних классах для специфичной инициализации уровня"""
	pass
#endregion
