# game_manager.gd
extends Node

signal lives_changed(new_lives: int)
signal inventory_loaded()  # Сигнал о загрузке инвентаря

const WeaponsType = preload("res://scripts/weapon_types.gd")
var _player: Player
var _dialogue_box: CanvasLayer
var _lives_panel: CanvasLayer
var is_paused = false

var player_data: Dictionary = {
	"lives": 4,
	"score": ScoreManager.get_score(),
	"weapon": {
		"type": WeaponManager.get_current_weapon(),
		"level": WeaponManager.get_current_level()
	},
	"game": {
		"weaponTrainingCompleted": false
	},
	"inventory": {}  # Сюда будет сохраняться инвентарь
}

func _ready() -> void:
	# Загружаем инвентарь при старте
	_load_inventory_from_save()
	set_weapon_from_data()

func register_player(player_node: Node2D) -> void:
	_player = player_node
	_player.weapon_picked_up.connect(ShowTrainingWeaponDialog)

func register_dialogue_box(dialogue_node: CanvasLayer) -> void:
	_dialogue_box = dialogue_node

func register_lives_panel(lives_panel_node: CanvasLayer):
	_lives_panel = lives_panel_node

# ============ Жизни игрока ============
func get_lives() -> int:
	return player_data["lives"]
func add_lives() -> int:
	player_data["lives"] += 1
	lives_changed.emit(player_data["lives"])
	return player_data["lives"]
func sub_lives() -> int:
	player_data["lives"] -= 1
	lives_changed.emit(player_data["lives"])
	return player_data["lives"]

# ============ Оружие игрока ============
func get_current_weapon_type() -> WeaponsType.WeaponType:
	return player_data["weapon"]["type"]
func get_current_weapon_level() -> WeaponsType.WeaponType:
	return player_data["weapon"]["level"]
func set_weapon_from_data():
	WeaponManager.change_weapon(player_data["weapon"]["type"])

# ============ Игра ============
func get_training_weapon_completed() -> bool:
	return player_data["game"]["weaponTrainingCompleted"]

func set_training_weapon_completed() -> void:
	player_data["game"]["weaponTrainingCompleted"] = true

# ============ ИНВЕНТАРЬ ============
func save_inventory_to_data() -> void:
	player_data["inventory"] = InventoryManager.save_inventory()

func load_inventory_from_data() -> void:
	if player_data.has("inventory") and not player_data["inventory"].is_empty():
		InventoryManager.load_inventory(player_data["inventory"])
		print("Inventory loaded from player_data")
		inventory_loaded.emit()
	else:
		print("No inventory data found, using default")

func _load_inventory_from_save() -> void:
	# Здесь можно загрузить сохранённую игру и восстановить player_data
	# Пример загрузки из файла сохранения:
	# var saved_data = load_game()
	# if saved_data.has("inventory"):
	#     player_data["inventory"] = saved_data["inventory"]
	# load_inventory_from_data()
	
	# Пока просто загружаем из текущей player_data
	load_inventory_from_data()
	
	# Подключаем сигналы для авто-сохранения
	InventoryManager.inventory_updated.connect(_on_inventory_updated)

func _on_inventory_updated(slot_index: int) -> void:
	# Автоматически сохраняем инвентарь при любом изменении
	save_inventory_to_data()

# Очистка инвентаря (например, при новой игре)
func clear_inventory() -> void:
	player_data["inventory"] = {}
	InventoryManager.load_inventory({})
	print("Inventory cleared")

# ============ Диалоги ============
func ShowTrainingWeaponDialog() -> void:
	return  # Убрать return, когда понадобится диалог
	if get_training_weapon_completed():
		return
	if _dialogue_box:
		_player.take_control_away(true)
		_lives_panel.visible = false
		set_training_weapon_completed()
		_dialogue_box.start_dialogue("01-dialogue03", "d1")
		_dialogue_box.dialogue_finished.connect(_on_training_dialog_finished, CONNECT_ONE_SHOT)
	else:
		push_error("DialogueBox not found!")

func _on_training_dialog_finished() -> void:
	_lives_panel.visible = true
	_player.restore_control()

# ============ СОХРАНЕНИЕ ВСЕЙ ИГРЫ ============
func save_game() -> void:
	save_inventory_to_data()
	# Сохраняем весь player_data в файл
	var save_file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	if save_file:
		var json_string = JSON.stringify(player_data)
		save_file.store_line(json_string)
		print("Game saved!")

func load_game() -> void:
	var save_file = FileAccess.open("user://savegame.save", FileAccess.READ)
	if save_file:
		var json_string = save_file.get_line()
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result == OK:
			player_data = json.data
			load_inventory_from_data()
			print("Game loaded!")
