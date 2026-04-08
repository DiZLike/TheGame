# bullet_manager.gd
extends Node
var player_bullets: int = 0

# ============================================
# Регистрация пули при создании
# ============================================
func register_bullet() -> void:
	player_bullets += 1
	print("Bullet registered. Total: ", player_bullets)  # Для отладки
	
# ============================================
# Удаление пули из учета
# ============================================
func unregister_bullet() -> void:
	player_bullets -= 1
	print("Bullet unregistered. Total: ", player_bullets)  # Для отладки

# ============================================
# Получение количества активных пуль для стрелка
# ============================================
func get_bullet_count() -> int:
	return player_bullets

# ============================================
# Проверка, может ли стрелок выстрелить
# ============================================
func can_shoot(max_bullets: int) -> bool:
	return get_bullet_count() < max_bullets

# ============================================
# Очистка всех данных (например, при смене уровня)
# ============================================
func clear_all() -> void:
	player_bullets = 0
