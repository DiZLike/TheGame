# item.gd
extends Resource
class_name Item

@export var id: String = ""
@export var name: String = "Unknown Item"
@export var description: String = ""
@export var icon: Texture2D
@export var max_stack: int = 99
@export var item_type: ItemType = ItemType.MISC

enum ItemType {
	WEAPON,
	ARMOR,
	CONSUMABLE,
	QUEST,
	MISC
}

@export var heal_amount: int = 0
@export var damage_amount: int = 0

# Загрузка имени и описания из одного txt файла
func load_info_from_txt(file_path: String) -> void:
	if not FileAccess.file_exists(file_path):
		push_warning("File not found: ", file_path)
		return
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	
	var parts = content.split("===", false, 1)
	if parts.size() >= 2:
		name = parts[0].strip_edges()
		description = parts[1].strip_edges()
	else:
		# Если нет разделителя, весь текст - название
		name = content.strip_edges()
		description = ""


func can_stack() -> bool:
	return max_stack > 1


func use() -> Dictionary:
	var result = {
		"success": false,
		"message": ""
	}
	
	match item_type:
		ItemType.CONSUMABLE:
			result.success = true
			result.message = "Used %s" % name
		_:
			result.message = "Cannot use this item"
	
	return result
