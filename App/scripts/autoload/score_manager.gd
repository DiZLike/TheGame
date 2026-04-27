# score_manager.gd
extends Node

## Сигнал, испускаемый при изменении счета
signal score_changed(new_score: int, old_score: int)

## Порог очков для получения дополнительной жизни
const LIFE_THRESHOLD: int = 20000

## Текущий счет
var score: int = 0
var record: int = 0

## Количество уже выданных жизней (для отслеживания порогов)
var _lives_awarded: int = 0

func add_score(add: int) -> int:
	if add <= 0:
		return score
	if score > record:
		record = score
	
	var old_score = score
	score += add
	
	# Проверяем, не превысили ли мы новый порог для жизни
	_check_life_threshold(old_score, score)
	
	score_changed.emit(score, old_score)
	return score

func set_score(new_score: int) -> int:
	score = new_score
	score_changed.emit(new_score, score)
	return score

func get_score() -> int:
	return score


func reset_score() -> int:
	var old_score = score
	score = 0
	_lives_awarded = 0
	score_changed.emit(score, old_score)
	return score


## Приватный метод для проверки порога и выдачи жизни
func _check_life_threshold(old_score: int, new_score: int) -> void:
	# Вычисляем, сколько порогов было достигнуто
	var new_thresholds_reached = int(new_score / LIFE_THRESHOLD)
	
	# Если достигнут новый порог, выдаем жизнь
	if new_thresholds_reached > _lives_awarded:
		var lives_to_add = new_thresholds_reached - _lives_awarded
		_lives_awarded = new_thresholds_reached
		
		# Вызываем метод GameManager для добавления жизней
		_award_lives(lives_to_add)


## Выдача дополнительных жизней через GameManager
func _award_lives(amount: int) -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_method("add_lives"):
		game_manager.add_lives(amount)
		print("Awarded ", amount, " extra life(s)! Total lives awarded: ", _lives_awarded)
	else:
		# Fallback: пытаемся найти GameManager в группе
		var game_managers = get_tree().get_nodes_in_group("game_manager")
		if game_managers.size() > 0 and game_managers[0].has_method("add_lives"):
			game_managers[0].add_lives(amount)
			print("Awarded ", amount, " extra life(s)! Total lives awarded: ", _lives_awarded)


## Получить прогресс до следующей жизни (0.0 - 1.0)
func get_next_life_progress() -> float:
	var current_threshold = _lives_awarded * LIFE_THRESHOLD
	var next_threshold = (_lives_awarded + 1) * LIFE_THRESHOLD
	var progress = float(score - current_threshold) / float(next_threshold - current_threshold)
	return clamp(progress, 0.0, 1.0)


## Получить очки, необходимые для следующей жизни
func get_points_to_next_life() -> int:
	var next_threshold = (_lives_awarded + 1) * LIFE_THRESHOLD
	return max(0, next_threshold - score)
