# SparkEffect.gd
extends Node2D

class_name SparkEffect

# ===== НАСТРОЙКИ ИСКР (можно менять в инспекторе) =====
@export var spark_min_count: int = 15
@export var spark_max_count: int = 30
@export var spark_size: Vector2 = Vector2(2, 2)  # Размер искры
@export var explosion_radius: float = 15.0  # Радиус разлета
@export var min_speed: float = 50.0        # Мин. скорость разлета
@export var max_speed: float = 300.0        # Макс. скорость разлета
@export var speed_factor: float = 2.0       # Множитель скорости
@export var min_lifetime: float = 0.3       # Мин. время жизни
@export var max_lifetime: float = 0.9       # Макс. время жизни
@export var fade_out_time: float = 0.8      # Как быстро исчезают (0-1)
@export var shrink_time: float = 0.8        # Как быстро уменьшаются (0-1)
@export var final_spark_size: Vector2 = Vector2(1, 1)  # Конечный размер

# Цветовые настройки
@export var color_red: float = 1.0
@export var min_green: float = 0.3
@export var max_green: float = 0.8
@export var min_blue: float = 0.0
@export var max_blue: float = 0.2

var _active_sparks: Array = []

func _ready() -> void:
	_create_sparks()
	# Автоматически удаляем сцену после завершения всех анимаций
	await get_tree().create_timer(max_lifetime + 0.1).timeout
	queue_free()

func _create_sparks() -> void:
	for i in range(randi_range(spark_min_count, spark_max_count)):
		var spark = ColorRect.new()
		spark.size = spark_size
		
		# Случайный цвет
		var green = randf_range(min_green, max_green)
		var blue = randf_range(min_blue, max_blue)
		spark.color = Color(color_red, green, blue, 1.0)
		
		# Случайное смещение от центра
		var offset = Vector2(
			randf_range(-explosion_radius, explosion_radius),
			randf_range(-explosion_radius, explosion_radius)
		)
		spark.position = offset - (spark_size / 2)
		
		# Случайное направление
		var angle = randf_range(0, PI * 2)
		
		# Скорость зависит от желаемого радиуса
		# Максимальная скорость, необходимая для достижения радиуса за максимальное время жизни
		var max_speed_for_radius = explosion_radius / max_lifetime
		
		# Выбираем случайную скорость между min_speed и ограниченной скоростью
		var limited_max_speed = min(max_speed, max_speed_for_radius * speed_factor)
		var speed = randf_range(min_speed, limited_max_speed)
		
		var velocity = Vector2(cos(angle), sin(angle)) * speed
		
		add_child(spark)
		_active_sparks.append(spark)
		
		# Анимация искры
		var lifetime = randf_range(min_lifetime, max_lifetime)
		var tween = create_tween()
		
		var end_pos = spark.position + velocity * lifetime
		tween.tween_property(spark, "position", end_pos, lifetime)
		tween.parallel().tween_property(spark, "color:a", 0, lifetime * fade_out_time)
		tween.parallel().tween_property(spark, "size", final_spark_size, lifetime * shrink_time)
		tween.tween_callback(_remove_spark.bind(spark))

func _remove_spark(spark: ColorRect) -> void:
	if is_instance_valid(spark):
		spark.queue_free()
	_active_sparks.erase(spark)
	
	# Если все искры удалены - удаляем эффект
	if _active_sparks.is_empty():
		queue_free()
