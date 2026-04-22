# skin_manager.gd
extends Node
class_name SkinManager

var skins = [
	preload("res://sprites/player/default/spritesheet.png"),
	preload("res://sprites/player/skin1/spritesheet.png"),
	preload("res://sprites/player/skin2/spritesheet.png")
]

@onready var animated_sprite: AnimatedSprite2D = $"../AnimatedSprite2D"

func change_skin(index: int) -> void:
	if index < 0 or index >= skins.size():
		return
	
	var new_atlas = skins[index]
	var current_anim = animated_sprite.animation
	var current_frame = animated_sprite.frame
	
	for anim in animated_sprite.sprite_frames.get_animation_names():
		for i in animated_sprite.sprite_frames.get_frame_count(anim):
			var tex = animated_sprite.sprite_frames.get_frame_texture(anim, i)
			if tex is AtlasTexture:
				tex.atlas = new_atlas
	
	animated_sprite.play(current_anim)
	animated_sprite.frame = current_frame
