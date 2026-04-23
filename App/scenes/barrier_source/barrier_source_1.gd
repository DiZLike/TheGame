# barrier_source.gd
extends Area2D

class_name Source

## Активен ли источник
@export var enable: bool = true

## Название группы, к которой принадлежит источник
@export var group_name: String = "barrier_1"

## Допустимая задержка уничтожения в секундах
@export var tolerance: float = 0.2

## Сила взрыва при уничтожении
@export var explosion_force: float = 500.0

# === РЕСУРСЫ ===
var pixel_explosion_scene: PackedScene = preload("res://scenes/effects/pixel_explosion.tscn")
var sound_destroy: AudioStream = preload("res://data/audio/sounds/enemy/source_destroy.wav")
var animated_sprite: AnimatedSprite2D


func _ready():
	# Находим спрайт для взрыва
	if has_node("AnimatedSprite2D"):
		animated_sprite = $AnimatedSprite2D
	
	if enable:
		set_enable()
	else:
		set_disable()
	
	BarrierSourceManager.register_source(group_name, name, global_position, get_parent(), tolerance)
	save_properties_to_manager()
	
	tree_exiting.connect(_on_destroyed)


func save_properties_to_manager():
	var properties = {
		"group": group_name,
		"enable": enable,
		"tolerance": tolerance,
		"position": global_position
	}
	BarrierSourceManager.update_source_properties(group_name, name, properties)


func set_disable():
	monitoring = false
	monitorable = false
	
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.disabled = true
	
	if animated_sprite:
		animated_sprite.visible = false
		animated_sprite.stop()
	
	enable = false
	save_properties_to_manager()

func set_enable():
	monitoring = true
	monitorable = true
	
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.disabled = false
	
	if animated_sprite:
		animated_sprite.visible = true
		animated_sprite.play()
	
	enable = true
	save_properties_to_manager()

func _on_area_entered(area: Area2D):
	if not enable:
		return
	
	var damage = area.get("damage") if "damage" in area else 1.0
	
	call_deferred("die")
	area.queue_free()


func die():
	# Создаем взрыв
	if pixel_explosion_scene:
		var explosion = pixel_explosion_scene.instantiate()
		get_tree().root.add_child(explosion)
		
		# Запускаем взрыв от спрайта источника
		if animated_sprite:
			explosion.explode_from_animated_sprite(animated_sprite, global_position, explosion_force)
		else:
			explosion.explode_from_animated_sprite(null, global_position, explosion_force)
	
	# Отключаем коллизию и скрываем
	monitoring = false
	monitorable = false
	
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.disabled = true
	
	if animated_sprite:
		animated_sprite.visible = false
		animated_sprite.stop()
	
	# Удаляем через небольшую задержку, чтобы взрыв успел проиграться
	queue_free()


func _on_destroyed():
	BarrierSourceManager.report_death(group_name, name)
	AudioManager.play_sfx(sound_destroy, 1, global_position)

func get_status() -> Dictionary:
	return {
		"name": name,
		"group": group_name,
		"enabled": enable,
		"position": global_position
	}
