# loot_entry.gd
class_name LootEntry
extends Resource

@export var item_scene: PackedScene  # Сцена предмета
@export var weight: float = 1.0       # Вес вероятности
