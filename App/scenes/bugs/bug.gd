extends StaticBody2D

# Уникальный идентификатор для сохранения состояния бага
@export var unique_bug_id: String = ""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not unique_bug_id.is_empty():
		if GameManager.has_bug_removed(unique_bug_id):
			queue_free()
			return

func remove() -> void:
	if not unique_bug_id.is_empty():
		GameManager.mark_bug_removed(unique_bug_id)
		queue_free()
