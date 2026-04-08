extends CharacterBody2D

@export var pickup: PackedScene
@export var speed: float = 200.0
@export var amplitude: float = 50.0
@export var frequency: float = 2.0
@export var direction: int = 1  # 1 = вправо, -1 = влево

var time: float = 0.0
var base_y: float

func _ready():
	base_y = position.y

func _physics_process(delta):
	time += delta
	
	# Создаем вектор движения
	var velocity_x = speed * direction
	
	# Вычисляем смещение по Y
	var y_offset = sin(time * frequency * TAU) * amplitude
	
	# Устанавливаем velocity
	velocity.x = velocity_x
	velocity.y = 0
	
	# Перемещаем объект
	move_and_slide()
	
	# Применяем синусоидальное смещение по Y
	position.y = base_y + y_offset

func pickup_spawn():
	var pic = pickup.instantiate()
	pic.global_position = global_position
	get_tree().current_scene.add_child(pic)

func _on_area_2d_area_entered(area: Area2D) -> void:
	pass # Replace with function body.
