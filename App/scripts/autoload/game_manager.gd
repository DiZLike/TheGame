extends Node

signal lives_changed(new_lives: int)
var player_data: Dictionary = {
	"lives": 4,
	"score": ScoreManager.get_score()
}

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
