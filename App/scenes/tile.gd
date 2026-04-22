extends Node2D
class_name Tile

@onready var sprite_2d: Sprite2D = $Sprite2D

# === РЕСУРСЫ ===
var pixel_explosion_scene: PackedScene = preload("res://scenes/effects/pixel_explosion.tscn")


# ============================================
# РАЗРУШЕНИЕ ТАЙЛА
# ============================================
func destroy(bullet_type: String = "default") -> void:
	"""
	Разрушает тайл с эффектом разлетающихся пикселей.
	
	Параметры:
	- explosion_force: сила разлёта пикселей
	"""
	# Создаем взрыв
	var explosion = pixel_explosion_scene.instantiate()
	get_tree().root.add_child(explosion)
	
	# Запускаем взрыв от спрайта
	var force: float = _calculate_explosion_force(bullet_type)
	explosion.explode_from_sprite(sprite_2d, global_position, force)
	
	# Удаляем тайл
	queue_free()
	
func _calculate_explosion_force(bullet_type: String) -> float:
	"""
	Вычисляет силу взрыва в зависимости от типа пули.
	Переопределяется в дочерних классах если нужна другая логика.
	"""
	match bullet_type:
		"rocket":
			return 800.0
		"homing":
			return 500.0
		_:
			return 250

# ============================================
# НАСТРОЙКА
# ============================================
func set_sprite(sprite: Sprite2D) -> void:
	"""
	Устанавливает текстуру тайла из другого спрайта.
	"""
	sprite_2d.texture = sprite.texture
