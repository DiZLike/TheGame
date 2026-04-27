# game_manager.gd
extends Node

## Сигналы для UI и других систем
signal lives_changed(new_lives: int, old_lives: int)
signal score_changed(new_score: int)
signal weapon_changed(weapon_type: WeaponsType.WeaponType, level: int)
signal game_saved()
signal game_loaded()
signal inventory_loaded()

const DEFAULT_LIVES = 2
const WeaponsType = preload("res://scripts/weapon_types.gd")

var sound_life = preload("res://data/audio/sounds/life/life.wav")

# ============================================
# ПУБЛИЧНЫЕ ПЕРЕМЕННЫЕ (для удобного доступа)
# ============================================

## Текущее состояние паузы
var is_paused: bool = false:
	set(value):
		is_paused = value
		get_tree().paused = value

## Ссылки на основные узлы (публичные для удобства)
var player: Player = null
var level: BaseLevel = null

# ============================================
# ПРИВАТНЫЕ ПЕРЕМЕННЫЕ
# ============================================

var _player_data: Dictionary = {
	"lives": DEFAULT_LIVES,
	"score": 0,
	"weapon": {
		"type": WeaponsType.WeaponType.DEFAULT,
		"level": 0
	},
	"skin": 2,
	"game": {
		"current_level": "",
		"intro_dialogues_completed": false,
		"weapon_training_completed": false,
		"coin_collection_started": false
	},
	"inventory": {},
	"collected_items": [],
	"triggered_dialogues": [],
	"removed_bugs": []
}
var _player_data_cont: Dictionary = {
}

# ============================================
# СБРОС ПРОГРЕССА (новая игра)
# ============================================

func reset_game() -> void:
	_player_data = {
		"lives": DEFAULT_LIVES,
		"score": 0,
		"weapon": {
			"type": WeaponsType.WeaponType.DEFAULT,
			"level": 0
		},
		"game": {
			"current_level": "1",
			"intro_dialogues_completed": false,
			"weapon_training_completed": false,
			"coin_collection_started": false
		},
		"inventory": {},
		"collected_items": [],
		"triggered_dialogues": [],
		"removed_bugs": []
	}
	
	ScoreManager.reset_score()
	clear_inventory()
	_apply_weapon_settings()
	
	lives_changed.emit(_player_data["lives"], 0)
	ScoreManager.set_score(_player_data["score"])

func save_cont_player_data() -> void:
	_player_data_cont = _player_data.duplicate()
	
func load_cont_player_dala() -> void:
	_player_data = _player_data_cont.duplicate()
	# Восстанавливаем состояние менеджеров
	ScoreManager.set_score(_player_data["score"])
	_load_inventory_from_data()
	_apply_weapon_settings()
		
	# Оповещаем UI
	lives_changed.emit(_player_data["lives"], _player_data["lives"])
		
	game_loaded.emit()
	
func set_current_level(level: String) -> void:
	_player_data["game"]["current_level"] = level
	
func get_current_level() -> String:
	return _player_data["game"]["current_level"]

# ============================================
# БАЗОВЫЕ МЕТОДЫ
# ============================================

func _ready() -> void:
	_initialize_game()
	_connect_signals()

func _initialize_game() -> void:
	# Синхронизируем очки с ScoreManager
	_player_data["score"] = ScoreManager.get_score()
	
	# Загружаем сохранение если есть
	if _has_save_file():
		#load_game()
		pass
	else:
		_load_inventory_from_data()
		_apply_weapon_settings()


func _connect_signals() -> void:
	# Подключаемся к сигналам других менеджеров
	if ScoreManager.has_signal("score_changed"):
		ScoreManager.score_changed.connect(_on_score_manager_changed)
	
	if WeaponManager.has_signal("weapon_changed"):
		WeaponManager.weapon_changed.connect(_on_weapon_manager_changed)
	
	if InventoryManager.has_signal("inventory_updated"):
		InventoryManager.inventory_updated.connect(_on_inventory_updated)


# ============================================
# РЕГИСТРАЦИЯ УЗЛОВ (упрощённый API)
# ============================================

func register_level(level_node: BaseLevel) -> void:
	level = level_node

func register_player(player_node: Player) -> void:
	player = player_node
	change_weapon(_player_data["weapon"]["type"])
	player.change_skin(_player_data["skin"])

# ============================================
# ЖИЗНИ (улучшенное API)
# ============================================

func get_lives() -> int:
	return _player_data["lives"]


func set_lives(value: int) -> void:
	var old_lives = _player_data["lives"]
	_player_data["lives"] = max(0, value)
	lives_changed.emit(_player_data["lives"], old_lives)
	
	if _player_data["lives"] <= 0:
		_game_over()


func add_lives(amount: int = 1) -> int:
	AudioManager.play_sfx(sound_life)
	set_lives(_player_data["lives"] + amount)
	return _player_data["lives"]


func remove_lives(amount: int = 1) -> int:
	set_lives(_player_data["lives"] - amount)
	return _player_data["lives"]


# ============================================
# ОЧКИ (делегирование к ScoreManager)
# ============================================

func get_score() -> int:
	return ScoreManager.get_score()


func add_score(amount: int) -> int:
	return ScoreManager.add_score(amount)


# ============================================
# ОРУЖИЕ (упрощённое API)
# ============================================

func get_current_weapon() -> WeaponsType.WeaponType:
	return WeaponManager.get_current_weapon()


func get_current_weapon_level() -> int:
	return WeaponManager.get_current_level()


func change_weapon(weapon_type: WeaponsType.WeaponType) -> void:
	_player_data["weapon"]["type"] = weapon_type
	_player_data["weapon"]["level"] = 0
	WeaponManager.change_weapon(weapon_type)


func upgrade_weapon() -> bool:
	if WeaponManager.upgrade_weapon():
		_player_data["weapon"]["level"] = WeaponManager.get_current_level()
		return true
	return false


func _apply_weapon_settings() -> void:
	WeaponManager.change_weapon(_player_data["weapon"]["type"])
	for i in range(_player_data["weapon"]["level"]):
		WeaponManager.upgrade_weapon()


# ============================================
# ИНВЕНТАРЬ (упрощённое API)
# ============================================
func has_unique_item(unique_id: String) -> bool:
	return _player_data["collected_items"].has(unique_id)

func add_item(slot: int, item_id: String, unique_id: String) -> bool:
	var ok = InventoryManager.add_item_by_id_to_slot(slot, item_id, 1)
	if not _player_data["collected_items"].has(unique_id):
		_player_data["collected_items"].append(unique_id)
	return ok

func remove_item(slot_index: int, quantity: int = 1) -> bool:
	return InventoryManager.remove_item(slot_index, quantity)

func use_item(slot_index: int) -> Dictionary:
	return InventoryManager.use_item(slot_index)

func get_inventory_slot(slot_index: int) -> Dictionary:
	return {
		"item": InventoryManager.get_item(slot_index),
		"quantity": InventoryManager.get_quantity(slot_index),
		"is_empty": InventoryManager.is_slot_empty(slot_index)
	}

func clear_inventory() -> void:
	_player_data["inventory"] = {}
	InventoryManager.load_inventory({})


func save_inventory_to_data() -> void:
	_player_data["inventory"] = InventoryManager.save_inventory()


func _load_inventory_from_data() -> void:
	if _player_data.has("inventory") and not _player_data["inventory"].is_empty():
		InventoryManager.load_inventory(_player_data["inventory"])
		inventory_loaded.emit()

# ============================================
# ДИАЛОГОВЫЕ ТРИГГЕРЫ
# ============================================

func has_triggered_dialogue(trigger_id: String) -> bool:
	return _player_data["triggered_dialogues"].has(trigger_id)

func mark_dialogue_triggered(trigger_id: String) -> void:
	if not _player_data["triggered_dialogues"].has(trigger_id):
		_player_data["triggered_dialogues"].append(trigger_id)
		print("Dialogue trigger marked as triggered: ", trigger_id)

func clear_triggered_dialogues() -> void:
	_player_data["triggered_dialogues"].clear()
	
# ============================================
# УДАЛЕНИЕ БАГОВ (БАРЬЕРОВ)
# ============================================
func has_bug_removed(bug_id: String) -> bool:
	return _player_data["removed_bugs"].has(bug_id)
func mark_bug_removed(bug_id: String) -> void:
	if not _player_data["removed_bugs"].has(bug_id):
		_player_data["removed_bugs"].append(bug_id)
		print("Bug marked as removed: ", bug_id)
func clear_removed_bugs() -> void:
	_player_data["removed_bugs"].clear()

# ============================================
# СОХРАНЕНИЕ И ЗАГРУЗКА
# ============================================

const SAVE_PATH = "user://savegame.save"

func save_game() -> void:
	# Обновляем данные перед сохранением
	_player_data["score"] = ScoreManager.get_score()
	save_inventory_to_data()
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(_player_data)
		file.store_line(json_string)
		file.close()
		game_saved.emit()
		print("Game saved successfully")


func load_game() -> bool:
	if not _has_save_file():
		return false
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false
	
	var json_string = file.get_line()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result == OK:
		_player_data = json.data
		
		# Восстанавливаем состояние менеджеров
		ScoreManager.score = _player_data["score"]
		_load_inventory_from_data()
		_apply_weapon_settings()
		
		# Оповещаем UI
		lives_changed.emit(_player_data["lives"], _player_data["lives"])
		ScoreManager.score_changed.emit(_player_data["score"])
		
		game_loaded.emit()
		print("Game loaded successfully")
		return true
	
	return false


func _has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func delete_save() -> void:
	if _has_save_file():
		DirAccess.remove_absolute(SAVE_PATH)

# ============================================
# ОБРАБОТЧИКИ СИГНАЛОВ
# ============================================

func _on_score_manager_changed(new_score: int, old_score: int) -> void:
	_player_data["score"] = new_score
	score_changed.emit(new_score)

func _on_weapon_manager_changed(weapon_type: WeaponsType.WeaponType, level: int) -> void:
	_player_data["weapon"]["type"] = weapon_type
	_player_data["weapon"]["level"] = level
	weapon_changed.emit(weapon_type, level)

func _on_inventory_updated(slot_index: int) -> void:
	save_inventory_to_data()

func _game_over() -> void:
	level.game_over()
