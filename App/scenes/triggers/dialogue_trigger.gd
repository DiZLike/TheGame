# DialogueTrigger.gd
extends Area2D
class_name DialogueTrigger

@export var dialogue_file: String = ""
@export var dialogue_start_id: String = ""
@export var active: bool = true

# Настройки безопасности
@export var take_control: bool = true  # Забрать управление
@export var make_invincible: bool = true  # Сделать неуязвимым
@export var use_shield_effect: bool = true  # Использовать визуальный эффект пузыря

@export var one_shot: bool = true  # Сработать один раз

@onready var lives_panel: CanvasLayer = $"../../../UI/LivesPanel"
@onready var dialogue_box: CanvasLayer = $"../../../UI/DialogLayer"
var player: CharacterBody2D = null
var triggered: bool = false

func _ready():
	if dialogue_box == null:
		dialogue_box = get_tree().current_scene.find_child("DialogueBox", true, false)

func _on_body_entered(body):
	if not active:
		return
	if not body.is_in_group("player"):
		return
	
	if one_shot and triggered:
		return
	
	player = body
	triggered = true
	prepare_and_start_dialogue()

func prepare_and_start_dialogue():
	# Подготавливаем игрока к диалогу
	if take_control or make_invincible:
		if make_invincible:
			# Передаём флаг использования щита
			player.take_control_away(use_shield_effect)
			pass
		elif take_control:
			# Только забрать управление без неуязвимости
			player.can_move = false
	
	# Запускаем диалог (БЕЗ паузы игры)
	dialogue_box.start_dialogue(dialogue_file, dialogue_start_id)
	dialogue_box.dialogue_finished.connect(_on_dialogue_finished, CONNECT_ONE_SHOT)
	dialogue_box.dialogue_started.connect(_on_dialogue_started, CONNECT_ONE_SHOT)

func _on_dialogue_started():
	lives_panel.visible = false

func _on_dialogue_finished():
	lives_panel.visible = true
	# Восстанавливаем игрока
	if make_invincible:
		player.restore_control()
		pass
	elif take_control:
		player.can_move = true
	
	# Удаляем триггер, если он одноразовый
	if one_shot:
		queue_free()
		
func activate() -> void:
	active = true
