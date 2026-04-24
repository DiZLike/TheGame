# camera_controller.gd
extends Node
class_name CameraController

const CAMERA_OFFSET_AMOUNT: float = 50.0
const CAMERA_TRANSITION_SPEED: float = 50.0
const HOLD_TIME_THRESHOLD: float = 1

var current_offset_y: float = 0.0
var target_offset_y: float = 0.0

@onready var camera: Camera2D = $"../Camera2D"
@onready var player: CharacterBody2D = $".."

func _process(delta: float) -> void:
	if GameManager.is_paused:
		return
	
	if Input.is_action_pressed("look_up") and not Input.is_action_pressed("look_down"):
		target_offset_y = -CAMERA_OFFSET_AMOUNT
	if Input.is_action_pressed("look_down") and not Input.is_action_pressed("look_up"):
		target_offset_y = +CAMERA_OFFSET_AMOUNT
	# Если ни одна кнопка не зажата, возвращаем камеру в исходное положение
	if not Input.is_action_pressed("look_up") and not Input.is_action_pressed("look_down"):
		target_offset_y = 0.0
	
	_smooth_camera_offset(delta)
	
	

func _smooth_camera_offset(delta: float) -> void:
	current_offset_y = move_toward(current_offset_y, target_offset_y, CAMERA_TRANSITION_SPEED * delta)
	camera.offset.y = current_offset_y

func reset_camera():
	target_offset_y = 0.0
