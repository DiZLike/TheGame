extends CharacterBody2D

const SPEED: float = 100.0
const GRAVITY: float = 700.0
const JUMP_VELOCITY: float = -175.0

enum Direction { LEFT, RIGHT }

@export var move_direction: Direction = Direction.RIGHT
@export var pixel_size: int = 2
@export var explosion_force: float = 50.0
@export var fade_duration: float = 1.5

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var ground_check: RayCast2D = $GroundCheck
@onready var wall_check_area: Area2D = $WallCheckArea
@onready var visible_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

var direction_vector: Vector2:
	get:
		return Vector2.RIGHT if move_direction == Direction.RIGHT else Vector2.LEFT
		
var wall_ahead: bool = false
var _is_exploding: bool = false  	# Флаг для предотвращения повторной обработки
var _is_remove_canceled = true 		# Флаг отмены удаления объекта

func _ready() -> void:
	_setup_ground_check()
	_setup_wall_check()
	_setup_sprite()

func _setup_ground_check() -> void:
	if ground_check:
		ground_check.target_position = Vector2(direction_vector.x * 20, 30)
		ground_check.enabled = true

func _setup_wall_check() -> void:
	if wall_check_area:
		wall_check_area.body_entered.connect(_on_wall_check_area_body_entered)
		wall_check_area.body_exited.connect(_on_wall_check_area_body_exited)
		_update_wall_check_position()

func _setup_sprite() -> void:
	if animated_sprite:
		animated_sprite.play("move")
		animated_sprite.flip_h = (move_direction == Direction.RIGHT)

func _physics_process(delta: float) -> void:
	if _is_exploding:
		return  # Не обрабатываем физику во время взрыва
		
	# Применение гравитации
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	# Горизонтальное движение
	velocity.x = direction_vector.x * SPEED
	
	# Проверка земли впереди
	if is_on_floor() and not _is_ground_ahead():
		velocity.y = JUMP_VELOCITY
	
	# Проверка стены впереди
	if wall_ahead:
		change_direction()
	
	move_and_slide()

func on_hit(damage: int, bullet: String) -> void:
	if bullet == "rocket":
		explosion_force = 350
	elif bullet == "homing":
		explosion_force = 200
	if _is_exploding:
		return  # Предотвращаем повторный взрыв
	_is_exploding = true
	call_deferred("_deferred_explode")

func _deferred_explode() -> void:
	if not is_instance_valid(self) or not is_inside_tree():
		return
	_explode_into_pixels()
	queue_free()

func _explode_into_pixels() -> void:
	if not animated_sprite or not animated_sprite.sprite_frames:
		return
	
	var current_frame_texture = animated_sprite.sprite_frames.get_frame_texture(
		animated_sprite.animation, 
		animated_sprite.frame
	)
	
	if not current_frame_texture:
		return
	
	var image = current_frame_texture.get_image()
	if not image or image.get_size().x <= 0 or image.get_size().y <= 0:
		return
	
	var tex_size = image.get_size()
	var tex_size_int = Vector2i(tex_size)
	
	# Оптимизация: предварительное создание текстур
	var pixel_texture_cache: Dictionary = {}
	
	for x in range(0, tex_size_int.x, pixel_size):
		for y in range(0, tex_size_int.y, pixel_size):
			var pixel_x = mini(x + pixel_size / 2, tex_size_int.x - 1)
			var pixel_y = mini(y + pixel_size / 2, tex_size_int.y - 1)
			var color = image.get_pixel(pixel_x, pixel_y)
			
			if color.a < 0.1:
				continue
			
			# Кэширование текстур для одинаковых цветов
			if not pixel_texture_cache.has(color):
				pixel_texture_cache[color] = _create_pixel_texture(color)
			
			_create_pixel_piece_optimized(pixel_texture_cache[color], color, x, y, tex_size)

func _create_pixel_piece_optimized(texture: ImageTexture, color: Color, x: int, y: int, tex_size: Vector2) -> void:
	var pixel = RigidBody2D.new()
	pixel.collision_layer = 0
	pixel.collision_mask = 0  # Оптимизация: отключаем коллизии для пикселей
	pixel.gravity_scale = 1.0
	
	var sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.centered = true
	sprite.modulate = color
	
	# Оптимизация: добавляем коллизию только если нужно
	var collision = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(pixel_size, pixel_size)
	collision.shape = rect_shape
	
	pixel.add_child(sprite)
	pixel.add_child(collision)
	
	var pixel_pos = Vector2(
		x - tex_size.x / 2 + animated_sprite.offset.x,
		y - tex_size.y / 2 + animated_sprite.offset.y
	)
	pixel.global_position = global_position + pixel_pos
	
	var angle = randf_range(0, TAU)
	var speed = randf_range(explosion_force * 0.5, explosion_force)
	pixel.linear_velocity = Vector2(cos(angle), sin(angle)) * speed
	pixel.angular_velocity = randf_range(-5, 5)
	
	get_tree().root.add_child(pixel)
	_start_fade_animation_optimized(pixel, sprite)

func _start_fade_animation_optimized(pixel: RigidBody2D, sprite: Sprite2D) -> void:
	var tween = create_tween().set_parallel(true)  # Параллельное выполнение
	tween.tween_property(sprite, "modulate:a", 0.0, fade_duration)
	tween.tween_property(pixel, "linear_velocity", Vector2.ZERO, fade_duration * 0.3)
	
	tween.finished.connect(_cleanup_pixel.bind(pixel), CONNECT_ONE_SHOT)

func _cleanup_pixel(pixel: Node) -> void:
	if is_instance_valid(pixel):
		pixel.queue_free()

func _create_pixel_texture(color: Color) -> ImageTexture:
	var image = Image.create(pixel_size, pixel_size, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)

func _on_screen_exited() -> void:
	_is_remove_canceled = false
	await get_tree().create_timer(10).timeout
	if not _is_remove_canceled:
		queue_free()
	
func _on_screen_entered() -> void:
	_is_remove_canceled = true

func _is_ground_ahead() -> bool:
	if not ground_check:
		return true
	
	ground_check.target_position = Vector2(direction_vector.x * 20, 30)
	ground_check.force_raycast_update()
	return ground_check.is_colliding()

func _update_wall_check_position() -> void:
	if not wall_check_area:
		return
	wall_check_area.position = Vector2(5 if move_direction == Direction.RIGHT else -5, 0)

func _on_wall_check_area_body_entered(body: Node2D) -> void:
	wall_ahead = true

func _on_wall_check_area_body_exited(body: Node2D) -> void:
	wall_ahead = false

func set_move_direction(dir: String) -> void:
	move_direction = Direction.LEFT if dir == "left" else Direction.RIGHT
	_update_sprite_flip()
	_update_ground_check()
	_update_wall_check_position()

func change_direction() -> void:
	move_direction = Direction.LEFT if move_direction == Direction.RIGHT else Direction.RIGHT
	_update_sprite_flip()
	_update_ground_check()
	_update_wall_check_position()
	await get_tree().create_timer(0.1).timeout

func _update_sprite_flip() -> void:
	if animated_sprite:
		animated_sprite.flip_h = (move_direction == Direction.RIGHT)

func _update_ground_check() -> void:
	if ground_check:
		ground_check.target_position = Vector2(direction_vector.x * 20, 30)
