# game_manager.gd
extends Node

## Сигналы для UI и других систем
signal lives_changed(new_lives: int, old_lives: int)
signal score_changed(new_score: int)
signal weapon_changed(weapon_type: WeaponsType.WeaponType, level: int)
signal game_saved()
signal game_loaded()
signal inventory_loaded()

const WeaponsType = preload("res://scripts/weapon_types.gd")

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
var dialogue_box: CanvasLayer = null
var lives_panel: CanvasLayer = null

# ============================================
# ПРИВАТНЫЕ ПЕРЕМЕННЫЕ
# ============================================

var _player_data: Dictionary = {
	"lives": 4,
	"score": 0,
	"weapon": {
		"type": WeaponsType.WeaponType.DEFAULT,
		"level": 0
	},
	"game": {
		"weapon_training_completed": false
	},
	"inventory": {}
}

var dialogue_trig: Dictionary = {}

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
		load_game()
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

func register_player(player_node: Player) -> void:
	player = player_node
	player.weapon_picked_up.connect(_on_weapon_picked_up)


func register_dialogue_box(dialogue_node: CanvasLayer) -> void:
	dialogue_box = dialogue_node


func register_lives_panel(panel: CanvasLayer) -> void:
	lives_panel = panel


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

func add_item(item_id: String, quantity: int = 1) -> bool:
	return InventoryManager.add_item_by_id(item_id, quantity)


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
# ПРОГРЕСС ИГРЫ
# ============================================

func is_weapon_training_completed() -> bool:
	return _player_data["game"]["weapon_training_completed"]


func complete_weapon_training() -> void:
	_player_data["game"]["weapon_training_completed"] = true


func is_first_weapon_pickup() -> bool:
	return not _player_data["game"]["weapon_training_completed"]


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
# СБРОС ПРОГРЕССА (новая игра)
# ============================================

func reset_game() -> void:
	_player_data = {
		"lives": 4,
		"score": 0,
		"weapon": {
			"type": WeaponsType.WeaponType.DEFAULT,
			"level": 0
		},
		"game": {
			"weapon_training_completed": false
		},
		"inventory": {}
	}
	
	ScoreManager.score = 0
	clear_inventory()
	_apply_weapon_settings()
	
	lives_changed.emit(_player_data["lives"], 0)
	ScoreManager.score_changed.emit(0)


# ============================================
# ДИАЛОГИ
# ============================================

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


func _show_training_dialogue() -> void:
	if dialogue_trig.has("weapon_training_enable"):
		if not dialogue_trig["weapon_training_enable"]:
			return
	else:
		return
	if is_weapon_training_completed():
		return
	
	complete_weapon_training()
	show_dialogue("01-dialogue03", "d1")


# ============================================
# ОБРАБОТЧИКИ СИГНАЛОВ
# ============================================

func _on_weapon_picked_up() -> void:
	if is_first_weapon_pickup():
		_show_training_dialogue()


func _on_dialogue_finished() -> void:
	if lives_panel:
		lives_panel.visible = true
	
	if player:
		player.restore_control()


func _on_score_manager_changed(new_score: int) -> void:
	_player_data["score"] = new_score
	score_changed.emit(new_score)


func _on_weapon_manager_changed(weapon_type: WeaponsType.WeaponType, level: int) -> void:
	_player_data["weapon"]["type"] = weapon_type
	_player_data["weapon"]["level"] = level
	weapon_changed.emit(weapon_type, level)


func _on_inventory_updated(slot_index: int) -> void:
	save_inventory_to_data()


func _game_over() -> void:
	print("Game Over!")
	# Здесь можно добавить логику окончания игры
	# Например, показать экран Game Over
