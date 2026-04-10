extends Node

signal lives_changed(new_lives: int)

const WeaponsType = preload("res://scripts/weapon_types.gd")
var player: Player
var dialogue_box: CanvasLayer
var lives_panel: CanvasLayer

var player_data: Dictionary = {
	"lives": 4,
	"score": ScoreManager.get_score(),
	"weapon": {
		"type": WeaponManager.get_current_weapon(),
		"level": WeaponManager.get_current_level()
	},
	"game": {
		"weaponTrainingCompleted": false
	}
}
	
func register_player(player_node: Node2D) -> void:
	player = player_node
	player.weapon_picked_up.connect(ShowTrainingWeaponDialog)
func register_dialogue_box(dialogue_node: CanvasLayer) -> void:
	dialogue_box = dialogue_node
func register_lives_panel(lives_panel_node: CanvasLayer):
	lives_panel = lives_panel_node

# Жизни игрока
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

# Оружие игрока
func get_current_weapon_type() -> WeaponsType.WeaponType:
	return player_data["weapon"]["type"]
func get_current_weapon_level() -> WeaponsType.WeaponType:
	return player_data["weapon"]["level"]
	
# Игра
func get_training_weapon_completed() -> bool:
	return player_data["game"]["weaponTrainingCompleted"]
func set_training_weapon_completed() -> void:
	player_data["game"]["weaponTrainingCompleted"] = true
	
# Диалогиыыыыыыыыыыыыы
func ShowTrainingWeaponDialog() -> void:
	if get_training_weapon_completed():
		return
	if dialogue_box:
		player.take_control_away(true)
		lives_panel.visible = false
		set_training_weapon_completed()
		dialogue_box.start_dialogue("01-dialogue03", "d1")
		dialogue_box.dialogue_finished.connect(_on_training_dialog_finished, CONNECT_ONE_SHOT)
	else:
		push_error("DialogueBox not found!")
func _on_training_dialog_finished() -> void:
	lives_panel.visible = true
	player.restore_control()
