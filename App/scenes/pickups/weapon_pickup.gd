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
	# Включаем физику
	set_physics_process(true)

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
	
	# Находим менеджер оружия
	var weapon_manager = get_node("/root/WeaponManager")
	if not weapon_manager:
		print("WeaponManager не найден!")
		queue_free()
		return
	
	# Логика подбора
	if weapon_manager.current_weapon == weapon_type:
		# То же оружие - улучшаем
		if weapon_manager.upgrade_weapon():
			print("Оружие улучшено до уровня ", weapon_manager.get_current_level() + 1)
	else:
		# Новое оружие
		weapon_manager.change_weapon(weapon_type)
		print("Оружие сменено на тип ", weapon_type)
	
	# Эффект подбора
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(0, 0), 0.1)
	
	await tween.finished
	queue_free()
