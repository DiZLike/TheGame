# inventory_manager.gd
extends Node

signal inventory_updated(slot_index: int)
signal item_used(slot_index: int, item: Item)

const SAVE_KEY = "player_inventory"
const ITEMS_PATH = "res://items/"
const ITEMS_DATA_PATH = "res://data/items/"
const WEAPON_SLOT_INDEX: int = 0

var inventory_size: int = 11
var slots: Array[InventorySlot] = []
var item_cache: Dictionary = {}


func _ready() -> void:
	_setup_inventory()
	_preload_items()


func _setup_inventory() -> void:
	slots.clear()
	for i in range(inventory_size):
		slots.append(InventorySlot.new())


func _preload_items() -> void:
	var item_files = [
		"weapon_d",
		"weapon_m",
		"weapon_s",
		"weapon_r",
		"weapon_h",
		"weapon_l",
		"coin"
	]
	
	for item_id in item_files:
		var path = ITEMS_PATH + item_id + ".tres"
		var item: Item
		
		if ResourceLoader.exists(path):
			# Загружаем .tres (с иконкой и остальными настройками)
			item = load(path).duplicate()  # duplicate() чтобы не изменять оригинальный ресурс
		else:
			# Если .tres нет, создаём новый
			item = Item.new()
			item.id = item_id
			item.max_stack = 1
			item.item_type = Item.ItemType.WEAPON
			push_warning("Item resource not found, creating new: ", item_id)
		
		# Всегда загружаем имя и описание из txt (перезаписываем)
		var txt_path = ITEMS_DATA_PATH + item_id + ".txt"
		if FileAccess.file_exists(txt_path):
			item.load_info_from_txt(txt_path)
		else:
			push_warning("Text file not found: ", txt_path)
		
		item_cache[item_id] = item
		print("Loaded item: ", item_id, " - ", item.name)


func get_item_by_id(item_id: String) -> Item:
	return item_cache.get(item_id, null)


# ============ ОСНОВНЫЕ МЕТОДЫ ============

func add_item_by_id(item_id: String, quantity: int = 1) -> bool:
	var item = get_item_by_id(item_id)
	if item:
		return add_item(item, quantity)
	return false


func add_item(item: Item, quantity: int = 1) -> bool:
	if item == null or quantity <= 0:
		return false
	
	if item.item_type == Item.ItemType.WEAPON:
		return _add_weapon(item)
	
	return _add_regular_item(item, quantity)


func _add_weapon(new_weapon: Item) -> bool:
	if not slots[WEAPON_SLOT_INDEX].is_empty():
		slots[WEAPON_SLOT_INDEX].clear()
	
	slots[WEAPON_SLOT_INDEX].set_item(new_weapon, 1)
	inventory_updated.emit(WEAPON_SLOT_INDEX)
	return true
	
func add_item_to_slot(slot_index: int, item: Item, quantity: int = 1) -> bool:
	if slot_index < 0 or slot_index >= slots.size():
		push_error("Invalid slot index: ", slot_index)
		return false
	
	if item == null or quantity <= 0:
		return false
	
	var target_slot = slots[slot_index]
	
	# Если слот пустой - просто добавляем
	if target_slot.is_empty():
		var to_add = min(quantity, item.max_stack)
		target_slot.set_item(item, to_add)
		inventory_updated.emit(slot_index)
		return true
	
	# Если в слоте такой же предмет и есть место для стака
	if target_slot.item.id == item.id:
		if target_slot.quantity >= item.max_stack:
			return false  # Стак уже полный
		
		var space_left = item.max_stack - target_slot.quantity
		var to_add = min(quantity, space_left)
		target_slot.add_quantity(to_add)
		inventory_updated.emit(slot_index)
		return true
	
	# Если в слоте другой предмет
	return false


func add_item_by_id_to_slot(slot_index: int, item_id: String, quantity: int = 1) -> bool:
	var item = get_item_by_id(item_id)
	if item == null:
		push_error("Item not found: ", item_id)
		return false
	
	return add_item_to_slot(slot_index, item, quantity)


func _add_regular_item(item: Item, quantity: int) -> bool:
	var remaining = quantity
	
	for i in range(1, slots.size()):
		if not slots[i].is_empty() and slots[i].item == item and slots[i].quantity < item.max_stack:
			var added = slots[i].add_quantity(remaining)
			remaining -= added
			inventory_updated.emit(i)
			if remaining <= 0:
				return true
	
	for i in range(1, slots.size()):
		if slots[i].is_empty():
			var max_in_slot = item.max_stack if item.max_stack > 0 else remaining
			var new_quantity = min(remaining, max_in_slot)
			slots[i].set_item(item, new_quantity)
			remaining -= new_quantity
			inventory_updated.emit(i)
			if remaining <= 0:
				return true
	
	return remaining <= 0


func remove_item(slot_index: int, quantity: int = 1) -> bool:
	if slot_index < 0 or slot_index >= slots.size():
		return false
	
	var removed = slots[slot_index].remove_quantity(quantity)
	if removed > 0:
		inventory_updated.emit(slot_index)
		return true
	return false


func use_item(slot_index: int) -> Dictionary:
	if slot_index < 0 or slot_index >= slots.size():
		return {"success": false, "message": "Invalid slot"}
	
	var slot = slots[slot_index]
	if slot.is_empty():
		return {"success": false, "message": "Slot is empty"}
	
	var result = slot.item.use()
	
	if result.success and slot.item.item_type == Item.ItemType.CONSUMABLE:
		remove_item(slot_index, 1)
		item_used.emit(slot_index, slot.item)
	
	return result


# ============ GETTERS ============

func get_item(slot_index: int) -> Item:
	if slot_index < 0 or slot_index >= slots.size():
		return null
	return slots[slot_index].item


func get_quantity(slot_index: int) -> int:
	if slot_index < 0 or slot_index >= slots.size():
		return 0
	return slots[slot_index].quantity


func is_slot_empty(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= slots.size():
		return true
	return slots[slot_index].is_empty()


# ============ СОХРАНЕНИЕ / ЗАГРУЗКА ============

func save_inventory() -> Dictionary:
	var inventory_data = {
		"inventory_size": inventory_size,
		"items": []
	}
	
	for i in range(slots.size()):
		var slot = slots[i]
		if not slot.is_empty():
			inventory_data["items"].append({
				"slot": i,
				"item_id": slot.item.id,
				"quantity": slot.quantity
			})
	
	return inventory_data


func load_inventory(inventory_data: Dictionary) -> void:
	if inventory_data.is_empty():
		return
	
	_setup_inventory()
	
	if inventory_data.has("items"):
		for item_data in inventory_data["items"]:
			var item = get_item_by_id(item_data["item_id"])
			if item:
				var slot_index = item_data["slot"]
				if slot_index >= 0 and slot_index < slots.size():
					slots[slot_index].set_item(item, item_data["quantity"])
					inventory_updated.emit(slot_index)
