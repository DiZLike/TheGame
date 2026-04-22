# shield_effect.gd
extends Node
class_name ShieldEffect

var shield_node: Node2D = null

@onready var player: CharacterBody2D = $".."

func create_shield():
	remove_shield()
	
	shield_node = Node2D.new()
	var sprite = Sprite2D.new()
	sprite.texture = _create_circle_texture(28, 4, Color(0.3, 0.5, 1.0))
	sprite.modulate.a = 0.4
	sprite.scale = Vector2(0.5, 0.5)
	shield_node.add_child(sprite)
	player.add_child(shield_node)
	_pulse_animation(sprite)

func remove_shield():
	if shield_node:
		shield_node.queue_free()
		shield_node = null

func _pulse_animation(sprite: Sprite2D, growing: bool = true):
	if not is_instance_valid(sprite):
		return
	
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1, 1) if growing else Vector2(0.5, 0.5), 0.5)
	await tween.finished
	
	if is_instance_valid(sprite):
		_pulse_animation(sprite, not growing)

func _create_circle_texture(radius: int, thickness: int, color: Color) -> Texture2D:
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	var center = Vector2(32, 32)
	for x in 64:
		for y in 64:
			var distance = center.distance_to(Vector2(x, y))
			if distance < radius and distance > radius - thickness:
				image.set_pixel(x, y, color)
	
	return ImageTexture.create_from_image(image)
