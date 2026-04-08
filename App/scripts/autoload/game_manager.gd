extends Node

var player_data: Dictionary = {
	"lives": 3
}

# Жизни персонажа
func get_lives() -> int:
	return player_data["lives"]
func add_lives() -> void:
	player_data["lives"] += 1
func sub_lives() -> void:
	player_data["lives"] -= 1
