extends CharacterBody2D

# ============================================
# НАЗНАЧЕНИЕ:
# Простой предмет подбора оружия с физикой падения и отскока
# Гравитация как у игрока
# ============================================

# ============================================
# НАСТРОЙКИ (видны в редакторе)
# ============================================
const WeaponsType = preload("res://scripts/weapon_types.gd")
@export var weapon_type: WeaponsType.WeaponType = WeaponsType.WeaponType.DEFAULT   # Тип оружия (0-5)
@export var bounce_force: float = -150.0           # Сила отскока от земли
@export var spawn_only_if_player_doesnt_have: bool = false  # Спавнить только если у игрока нет такого оружия

# ============================================
# КОМПОНЕНТЫ
# ============================================
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

# ============================================
# ФИЗИКА
# ============================================
var grav: float = 700.0  # Та же гравитация, что у игрока
var _picked: bool = false

# ============================================
# ИНИЦИАЛИЗАЦИЯ
# ============================================
func _ready() -> void:
	# Проверяем, нужно ли удалить предмет при спавне
	if spawn_only_if_player_doesnt_have:
		_check_and_destroy_if_player_has_weapon()
	
	# Включаем физику
	set_physics_process(true)

func _check_and_destroy_if_player_has_weapon() -> void:
	# Находим менеджер оружия
	var weapon_manager = get_node_or_null("/root/WeaponManager")
	if not weapon_manager:
		return
	
	# Если у игрока уже есть такое оружие, удаляем предмет
	if weapon_manager.current_weapon == weapon_type:
		queue_free()

# ============================================
# ФИЗИКА (CharacterBody2D)
# ============================================
func _physics_process(delta: float) -> void:
	# Применяем гравитацию
	velocity.y += grav * delta
	
	# Двигаем с автоматическим обнаружением столкновений
	move_and_slide()
	
	# Проверяем отскок от земли
	if is_on_floor() and bounce_force < 0:
		velocity.y = bounce_force
		bounce_force *= 0.7
		if bounce_force < -50:
			velocity.x = randf_range(-50, 50)
		else:
			bounce_force = 0
			velocity.x = 0
		move_and_slide()

# ============================================
# ПОДБОР ПРЕДМЕТА
# ============================================
func _on_body_entered(body: Node2D) -> void:
	# Только игрок подбирает
	if not body.is_in_group("player"):
		return
	
	# Защита от двойного подбора
	if _picked:
		return
	
	_picked = true
	body.weapon_picked()
	
	# Находим менеджер оружия
	var weapon_manager = get_node("/root/WeaponManager")
	if not weapon_manager:
		print("WeaponManager не найден!")
		queue_free()
		return
	
	# Логика подбора
	if weapon_manager.current_weapon == weapon_type:
		# То же оружие - улучшаем
		weapon_manager.upgrade_weapon()
	else:
		# Новое оружие
		weapon_manager.change_weapon(weapon_type)
	
	# Эффект подбора
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(0, 0), 0.1)
	
	await tween.finished
	queue_free()
