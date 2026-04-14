# inventory_slot.gd
extends Resource
class_name InventorySlot

@export var item: Item = null
@export var quantity: int = 0

func set_item(new_item: Item, new_quantity: int = 1) -> void:
	item = new_item
	quantity = new_quantity

func clear() -> void:
	item = null
	quantity = 0

func is_empty() -> bool:
	return item == null or quantity <= 0

func add_quantity(amount: int) -> int:
	var can_add = amount
	if item and item.max_stack > 0:
		var space_left = item.max_stack - quantity
		can_add = min(amount, space_left)
		quantity += can_add
	return can_add

func remove_quantity(amount: int) -> int:
	var removed = min(amount, quantity)
	quantity -= removed
	if quantity <= 0:
		clear()
	return removed
