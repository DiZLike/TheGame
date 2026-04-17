extends Node

signal score_changed(new_score: int)
var score: int = 0

func add_score(add: int) -> int:
	score += add
	score_changed.emit(score)
	return score
	
func get_score() -> int:
	return score

func reset_score() -> int:
	score = 0
	return score
