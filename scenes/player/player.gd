extends CharacterBody2D

# ============================================
# Константы движения
# ============================================
const SPEED: float = 100.0
const GRAVITY: float = 700.0
const JUMP_VELOCITY: float = -300.0

# ============================================
# Ссылки на узлы
# ============================================
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var damage_collision: CollisionShape2D = $DamageDetector/CollisionShape2D
@onready var damage_detector: Area2D = $DamageDetector
@onready var shoot_point: Marker2D = $ShootPoint

# ============================================
# Состояния персонажа
# ============================================
var is_jumping: bool = false
var is_crouching: bool = false
var is_shooting: bool = false

# ============================================
# Состояния диалога и безопасности
# ============================================
var can_move: bool = true           # Может ли игрок двигаться
var is_invincible: bool = false     # Неуязвим ли игрок
var shield_effect: Node2D = null    # Визуальный эффект щита
var original_modulate: Color        # Оригинальный цвет спрайта

# ============================================
# Параметры коллайдера
# ============================================
@onready var default_collider_pos: Vector2 = collision_shape.position
@onready var default_collider_scale: Vector2 = collision_shape.scale

const CROUCH_COLLIDER_POS: Vector2 = Vector2(0, 16)
const CROUCH_COLLIDER_SCALE: Vector2 = Vector2(1.7, 0.35)
const JUMP_COLLIDER_POS: Vector2 = Vector2(0, 14)
const JUMP_COLLIDER_SCALE: Vector2 = Vector2(0, 0.5)

const LEFT_BULLET_POS: Vector2 = Vector2(-14, 1)
const RIGHT_BULLET_POS: Vector2 = Vector2(14, 1)
const TOP1_BULLET_POS: Vector2 = Vector2(2, -23)
const TOP2_BULLET_POS: Vector2 = Vector2(-2, -23)
const TOP_LEFT_BULLET_POS: Vector2 = Vector2(-14, -12)
const TOP_RIGHT_BULLET_POS: Vector2 = Vector2(14, -12)
const BOTTOM_LEFT_BULLET_POS: Vector2 = Vector2(-14, 9)
const BOTTOM_RIGHT_BULLET_POS: Vector2 = Vector2(14, 9)

const LEFT_CROUCH_BULLET_POS: Vector2 = Vector2(-15, 14)
const RIGHT_CROUCH_BULLET_POS: Vector2 = Vector2(15, 14)

const LEFT_JUMP_BULLET_POS: Vector2 = Vector2(-9, 11)
const LEFT_TOP_JUMP_BULLET_POS: Vector2 = Vector2(-10, 3)
const LEFT_DOWN_JUMP_BULLET_POS: Vector2 = Vector2(-10, 22)
const RIGHT_JUMP_BULLET_POS: Vector2 = Vector2(9, 11)
const RIGHT_TOP_JUMP_BULLET_POS: Vector2 = Vector2(10, 3)
const RIGHT_DOWN_JUMP_BULLET_POS: Vector2 = Vector2(10, 22)
const TOP_JUMP_BULLET_POS: Vector2 = Vector2(0, 3)
const BOTTOM_JUMP_BULLET_POS: Vector2 = Vector2(0, 22)

func _ready():
	original_modulate = modulate

# ============================================
# Управление диалогом и безопасностью
# ============================================
# Забрать управление и сделать неуязвимым
func take_control_away(use_shield: bool = false):
	can_move = false
	is_invincible = true
	
	if use_shield:
		create_shield_effect()
	else:
		# Визуальный эффект без щита (мигание)
		modulate = Color(0.7, 0.7, 1.0, 1.0)

# Вернуть управление и снять неуязвимость
func restore_control():
	can_move = true
	is_invincible = false
	
	# Убираем визуальные эффекты
	if shield_effect:
		if shield_effect.has_method("fade_out"):
			shield_effect.fade_out()
		else:
			shield_effect.queue_free()
		shield_effect = null
	
	modulate = original_modulate

# Создать визуальный эффект щита
func create_shield_effect():
	# Удаляем старый щит, если есть
	if shield_effect:
		shield_effect.queue_free()
	
	shield_effect = Node2D.new()
	
	# Основной круг щита
	var shield_sprite = Sprite2D.new()
	shield_sprite.texture = _create_shield_texture()
	shield_sprite.modulate = Color(0.3, 0.5, 1.0, 0.4)
	shield_sprite.scale = Vector2(0.5, 0.5)
	
	# Добавляем свечение (опционально)
	var glow = Sprite2D.new()
	glow.texture = _create_glow_texture()
	glow.modulate = Color(0.067, 0.178, 0.403, 0.945)
	glow.scale = Vector2(1.2, 1.2)
	shield_sprite.add_child(glow)
	
	shield_effect.add_child(shield_sprite)
	
	# Запускаем пульсацию с помощью рекурсивного вызова
	_pulse_shield(shield_sprite)
	
	add_child(shield_effect)

# Рекурсивная пульсация щита
func _pulse_shield(shield_sprite: Sprite2D, scale_up: bool = true):
	if not shield_sprite or not is_instance_valid(shield_sprite):
		return
	
	var tween = create_tween()
	var target_scale = Vector2(1, 1) if scale_up else Vector2(0.5, 0.5)
	tween.tween_property(shield_sprite, "scale", target_scale, 0.5)
	
	await tween.finished
	
	# Продолжаем пульсацию только если щит всё ещё существует
	if shield_sprite and is_instance_valid(shield_sprite):
		_pulse_shield(shield_sprite, not scale_up)

# Создать текстуру щита программно
func _create_shield_texture() -> Texture2D:
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	var center = Vector2(32, 32)
	var radius = 28
	
	for x in range(64):
		for y in range(64):
			var pos = Vector2(x, y)
			var dist = center.distance_to(pos)
			var alpha = 0.0
			
			if dist < radius and dist > radius - 4:
				alpha = 0.8
			elif dist < radius - 2 and dist > radius - 6:
				alpha = 0.3
			elif dist < radius - 6:
				alpha = 0.1
			
			if alpha > 0:
				image.set_pixel(x, y, Color(0.3, 0.5, 1.0, alpha))
	
	return ImageTexture.create_from_image(image)

# Создать текстуру свечения
func _create_glow_texture() -> Texture2D:
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	var center = Vector2(32, 32)
	
	for x in range(64):
		for y in range(64):
			var dist = center.distance_to(Vector2(x, y))
			if dist < 35 and dist > 28:
				var alpha = 0.4 * (1.0 - (dist - 28) / 7.0)
				image.set_pixel(x, y, Color(0.5, 0.7, 1.0, alpha))
	
	return ImageTexture.create_from_image(image)

# ============================================
# Основной цикл физики
# ============================================
func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_crouch_input()
	_handle_jump_input()
	_handle_movement()
	_handle_shoot_input()
	_update_animation_and_sprite()
	move_and_slide()
	_reset_jump_flag()

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

func _handle_crouch_input() -> void:
	# Блокируем приседание во время диалога
	if not can_move:
		return
	
	var is_crouch_pressed: bool = Input.is_action_pressed("move_down") and Input.get_axis("move_left", "move_right") == 0
	
	if is_crouch_pressed and is_on_floor() and not is_jumping:
		if not is_crouching:
			_start_crouch()
	elif is_crouching:
		_stop_crouch()

func _handle_jump_input() -> void:
	# Блокируем прыжок во время диалога
	if not can_move:
		return
	
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_crouching:
		velocity.y = JUMP_VELOCITY
		is_jumping = true

func _handle_movement() -> void:
	# Блокируем движение во время диалога
	if not can_move:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		return
	
	var direction: float = Input.get_axis("move_left", "move_right")
	
	if not is_crouching and direction != 0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	if direction != 0:
		animated_sprite.flip_h = direction < 0

func _handle_shoot_input() -> void:
	if not can_move:
		return
	
	if Input.is_action_pressed("shoot") and not is_shooting:
		is_shooting = true
		
		var shoot_direction = _get_shoot_direction()
		_update_shoot_point_position()
		
		# Вызов WeaponManager
		WeaponManager.try_shoot(self, shoot_point, shoot_direction)
		
		await get_tree().create_timer(0.05).timeout
		is_shooting = false

func _get_shoot_direction() -> Vector2:
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if (is_crouching):
		input_dir.y = 0
	# Если есть движение по клавишам
	if input_dir != Vector2.ZERO:
		return input_dir.normalized()
	
	# Иначе стреляем по горизонтали в сторону взгляда
	return Vector2.RIGHT if not animated_sprite.flip_h else Vector2.LEFT

func _update_shoot_point_position() -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var is_flipped := animated_sprite.flip_h
	var dir_key := Vector2(sign(input_dir.x), sign(input_dir.y))
	
	const JUMP_POSITIONS := {
		Vector2(1, -1): RIGHT_TOP_JUMP_BULLET_POS,
		Vector2(-1, -1): LEFT_TOP_JUMP_BULLET_POS,
		Vector2(1, 1): RIGHT_DOWN_JUMP_BULLET_POS,
		Vector2(-1, 1): LEFT_DOWN_JUMP_BULLET_POS,
		Vector2(0, -1): TOP_JUMP_BULLET_POS,
		Vector2(0, 1): BOTTOM_JUMP_BULLET_POS,
	}
	
	const MOVE_POSITIONS := {
		Vector2(1, -1): TOP_RIGHT_BULLET_POS,
		Vector2(-1, -1): TOP_LEFT_BULLET_POS,
		Vector2(1, 1): BOTTOM_RIGHT_BULLET_POS,
		Vector2(-1, 1): BOTTOM_LEFT_BULLET_POS,
	}
	
	var shoot_pos: Vector2
	
	if is_crouching:
		shoot_pos = RIGHT_CROUCH_BULLET_POS if not is_flipped else LEFT_CROUCH_BULLET_POS
	elif not is_jumping:
		if MOVE_POSITIONS.has(dir_key):
			shoot_pos = MOVE_POSITIONS[dir_key]
		elif input_dir.y < 0:
			shoot_pos = TOP1_BULLET_POS if not is_flipped else TOP2_BULLET_POS
		else:
			shoot_pos = RIGHT_BULLET_POS if not is_flipped else LEFT_BULLET_POS
	else:
		if JUMP_POSITIONS.has(dir_key):
			shoot_pos = JUMP_POSITIONS[dir_key]
		else:
			shoot_pos = RIGHT_JUMP_BULLET_POS if not is_flipped else LEFT_JUMP_BULLET_POS
	
	shoot_point.position = shoot_pos

# ============================================
# Управление анимациями
# ============================================
func _update_animation_and_sprite() -> void:
	if not can_move:
		animated_sprite.play("idle")
		return
	if is_crouching:
		animated_sprite.play("down")
		return
	
	if is_on_floor():
		_handle_ground_animation()
	else:
		_handle_air_animation()

func _handle_ground_animation() -> void:
	if not can_move:
		animated_sprite.play("idle")
		return
	var direction_x: float = Input.get_axis("move_left", "move_right")
	var direction_y: float = Input.get_axis("move_down", "move_up")
	_reset_collider()
	
	if direction_y > 0 and  direction_x == 0:
		animated_sprite.play("up")
		return
	elif direction_y > 0 and direction_x != 0:
		animated_sprite.play("shootUp")
		return
	elif direction_y < 0 and direction_x != 0:
		animated_sprite.play("shootDown")
		return
		
	if is_shooting:
		if direction_x != 0 and direction_y == 0:
			animated_sprite.play("shootLine")
		else:
			animated_sprite.play("shoot")
		return
	if not is_shooting:
		animated_sprite.play("move" if direction_x != 0 else "idle")

func _handle_air_animation() -> void:
	if is_jumping:
		animated_sprite.play("jump")
		_update_collider(JUMP_COLLIDER_POS, JUMP_COLLIDER_SCALE)
	else:
		animated_sprite.play("fall")
		_reset_collider()

# ============================================
# Управление коллайдером
# ============================================
func _start_crouch() -> void:
	is_crouching = true
	_update_collider(CROUCH_COLLIDER_POS, CROUCH_COLLIDER_SCALE)

func _stop_crouch() -> void:
	is_crouching = false
	_reset_collider()

func _update_collider(pos: Vector2, scl: Vector2) -> void:
	if scl.x != 0:
		collision_shape.scale.x = scl.x
		damage_collision.scale.x = scl.x
	if scl.y != 0:
		collision_shape.scale.y = scl.y
		damage_collision.scale.y = scl.y
	if pos.x != 0:
		collision_shape.position.x = pos.x
		damage_collision.position.x = pos.x
	if pos.y != 0:
		collision_shape.position.y = pos.y
		damage_collision.position.y = pos.y

func _reset_collider() -> void:
	collision_shape.position = default_collider_pos
	collision_shape.scale = default_collider_scale
	damage_collision.position = default_collider_pos
	damage_collision.scale = default_collider_scale

func _reset_jump_flag() -> void:
	if is_on_floor() and is_jumping:
		is_jumping = false

# ============================================
# Обработка урона
# ============================================
func _on_area_2d_body_entered(body: Node2D) -> void:
	print("Игрок столкнулся с телом: ", body.name)
	
	if body.is_in_group("enemy"):
		if is_invincible:
			print("Урон заблокирован (режим диалога)")
			return
		
		print("Игрок получил урон")
