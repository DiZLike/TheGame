extends Node2D

@export var pixel_size: int = 2
@export var explosion_force: float = 350.0
@export var fade_duration: float = 1.5
@export var gravity_scale: float = 1.0
@export var bounce: float = 0.3
@export var linear_damp: float = 0.5

var screenshot_path: String = "user://explosion_screenshots/"
# Создает взрыв из текстуры спрайта
func explode_from_sprite(sprite: Sprite2D, position: Vector2, base_force: float = 350.0) -> void:
	#save_sprite_to_file(sprite)
	var texture = sprite.texture
	if not texture:
		return
	
	var image = texture.get_image()
	if not image or image.get_size().x <= 0 or image.get_size().y <= 0:
		return
	
	var tex_size = image.get_size()
	var tex_size_int = Vector2i(tex_size)
	
	# Используем переданную силу или значение по умолчанию
	var final_force = base_force if base_force > 0 else explosion_force
	
	# Кэш текстур для одинаковых цветов
	var pixel_texture_cache: Dictionary = {}
	
	# Добавляем случайное смещение для более естественного взрыва
	var random_offset = randf_range(-0.5, 0.5)
	
	for x in range(0, tex_size_int.x, pixel_size):
		for y in range(0, tex_size_int.y, pixel_size):
			var pixel_x = mini(x + pixel_size / 2, tex_size_int.x - 1)
			var pixel_y = mini(y + pixel_size / 2, tex_size_int.y - 1)
			var color = image.get_pixel(pixel_x, pixel_y)
			
			if color.a < 0.1:
				continue
			
			if not pixel_texture_cache.has(color):
				pixel_texture_cache[color] = _create_pixel_texture(color)
			
			_create_pixel_piece(
				pixel_texture_cache[color],
				color,
				Vector2(x + random_offset, y + random_offset),
				tex_size,
				sprite.offset,
				position,
				final_force
			)
	
	# Автоматически удалить сцену после завершения анимации всех пикселей
	await get_tree().create_timer(fade_duration + 0.5).timeout
	queue_free()
	
func save_sprite_to_file(sprite: Sprite2D) -> void:
	var texture = sprite.texture
	if not texture:
		return
	
	# Создаем уникальное имя файла с временной меткой
	var timestamp = Time.get_unix_time_from_system()
	var filename = "explosion_%d.png" % timestamp
	
	# Создаем директорию если её нет
	DirAccess.make_dir_recursive_absolute(screenshot_path)
	
	var full_path = screenshot_path + filename
	
	# Сохраняем текстуру
	var image = texture.get_image()
	if image:
		var error = image.save_png(full_path)
		if error == OK:
			print("Sprite saved to: ", ProjectSettings.globalize_path(full_path))
		else:
			print("Failed to save sprite: ", error)

# Альтернативный метод для AnimatedSprite2D
func explode_from_animated_sprite(animated_sprite: AnimatedSprite2D, position: Vector2, base_force: float = 350.0) -> void:
	if not animated_sprite or not animated_sprite.sprite_frames:
		return
	
	var current_frame_texture = animated_sprite.sprite_frames.get_frame_texture(
		animated_sprite.animation,
		animated_sprite.frame
	)
	
	if not current_frame_texture:
		return
	
	# Создаем временный Sprite2D для получения текстуры
	var temp_sprite = Sprite2D.new()
	temp_sprite.texture = current_frame_texture
	temp_sprite.offset = animated_sprite.offset
	temp_sprite.centered = true
	
	explode_from_sprite(temp_sprite, position, base_force)
	temp_sprite.queue_free()

func _create_pixel_piece(texture: ImageTexture, color: Color, pixel_pos: Vector2, tex_size: Vector2, sprite_offset: Vector2, global_pos: Vector2, force: float) -> void:
	var pixel = RigidBody2D.new()
	pixel.collision_layer = 0  # Слой для столкновений
	pixel.collision_mask = 0  # С чем может сталкиваться
	pixel.gravity_scale = gravity_scale
	pixel.linear_damp = linear_damp
	pixel.angular_damp = 0.8
	
	var sprite_node = Sprite2D.new()
	sprite_node.texture = texture
	sprite_node.centered = true
	sprite_node.modulate = color
	
	# Добавляем тень для объема
	var shadow = Sprite2D.new()
	shadow.texture = texture
	shadow.centered = true
	shadow.modulate = Color(0, 0, 0, 0.3)
	shadow.position = Vector2(1, 1)
	sprite_node.add_child(shadow)
	
	var collision = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(pixel_size, pixel_size)
	collision.shape = rect_shape
	
	# Настройка физических материалов
	var physics_material = PhysicsMaterial.new()
	physics_material.bounce = bounce
	physics_material.friction = 0.5
	pixel.physics_material_override = physics_material
	
	pixel.add_child(sprite_node)
	pixel.add_child(collision)
	
	var final_pos = Vector2(
		pixel_pos.x - tex_size.x / 2 + sprite_offset.x,
		pixel_pos.y - tex_size.y / 2 + sprite_offset.y
	)
	pixel.global_position = global_pos + final_pos
	
	# Направление взрыва - от центра к краям + случайная составляющая
	var center_offset = final_pos
	var direction = center_offset.normalized()
	
	# Добавляем случайность в направление
	var random_angle = randf_range(-0.5, 0.5)
	var final_direction = direction.rotated(random_angle)
	
	# Скорость зависит от расстояния от центра
	var distance_factor = clamp(center_offset.length() / 100.0, 0.3, 1.5)
	var speed = randf_range(force * 0.5, force) * distance_factor
	
	pixel.linear_velocity = final_direction * speed
	pixel.angular_velocity = randf_range(-10, 10)
	
	# ИСПРАВЛЕНО: Используем call_deferred для безопасного добавления
	call_deferred("add_child", pixel)
	
	_start_fade_animation(pixel, sprite_node)

func _start_fade_animation(pixel: RigidBody2D, sprite_node: Sprite2D) -> void:
	var tween = create_tween().set_parallel(true)
	
	# Плавное затухание
	tween.tween_property(sprite_node, "modulate:a", 0.0, fade_duration)
	
	# Уменьшение размера при затухании
	tween.tween_property(sprite_node, "scale", Vector2(0.5, 0.5), fade_duration)
	
	# Добавляем случайную задержку перед удалением
	await get_tree().create_timer(fade_duration + randf_range(0, 0.3)).timeout
	_cleanup_pixel(pixel)

func _cleanup_pixel(pixel: Node) -> void:
	if is_instance_valid(pixel):
		pixel.queue_free()

func _create_pixel_texture(color: Color) -> ImageTexture:
	var image = Image.create(pixel_size, pixel_size, false, Image.FORMAT_RGBA8)
	image.fill(color)
	
	return ImageTexture.create_from_image(image)
