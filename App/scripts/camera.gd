extends Camera2D
class_name PlayerSideCamera

@onready var border_groupe: Node2D = $"../../CameraBorders"

var borders = {
	"left": null,
	"right": null,
	"top": null,
	"bottom": null
}

func _ready():
	position_smoothing_enabled = true
	position_smoothing_speed = 5.0
	
	find_borders_in_scene()

func _on_borders_ready(left_x, right_x, top_y, bottom_y):
	if left_x != null:
		limit_left = int(left_x)
	if right_x != null:
		limit_right = int(right_x)
	if top_y != null:
		limit_top = int(top_y)
	if bottom_y != null:
		limit_bottom = int(bottom_y)

func find_borders_in_scene():
	var level = get_tree().current_scene
	if not level:
		return
	
	# Ищем узлы с группой в сцене уровня
	var all_borders = border_groupe.get_children()
	
	for border in all_borders:
		var border_name = border.name.to_lower()
		
		if "left" in border_name:
			limit_left = int(border.global_position.x)
		elif "right" in border_name:
			limit_right = int(border.global_position.x)
		elif "top" in border_name:
			limit_top = int(border.global_position.y)
		elif "bottom" in border_name:
			limit_bottom = int(border.global_position.y)
