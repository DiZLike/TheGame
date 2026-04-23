extends SpitterEnemy
class_name AcidSpitter

# ============================================
# ВРАГ - ПЛЕВАТЕЛЬ КИСЛОТОЙ
# ============================================
# Подбрасывает случайное количество капель кислоты вверх.
# Капли летят по дуге и взрываются при касании с землёй.
# ============================================

# === НАСТРОЙКИ ТОЧКИ СПАВНА ===
@export var spawn_offset: Vector2 = Vector2(0, -15)


# ============================================
# НАСТРОЙКА
# ============================================

func _ready() -> void:
	if not projectile_scene:
		projectile_scene = preload("res://scenes/bullets/enemy/acid_drop.tscn")
	
	super._ready()
	
	if animated_sprite and animated_sprite.sprite_frames.has_animation("idle"):
		animated_sprite.play("idle")


# ============================================
# СПАВН
# ============================================

func _get_spawn_position() -> Vector2:
	return global_position + spawn_offset


# ============================================
# АНИМАЦИИ
# ============================================

func _face_player() -> void:
	if not animated_sprite or not is_player_valid():
		return
	
	var direction_to_player = _player.global_position.x - global_position.x
	animated_sprite.flip_h = direction_to_player > 0
