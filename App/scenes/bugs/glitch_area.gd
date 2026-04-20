extends Control

@onready var color_rect: ColorRect = $ColorRect

@export_category("VHS Effect Settings")
@export var intensity: float = 0.06:
	set(value):
		intensity = value
		_update_shader_param("intensity", value)

@export var speed: float = 6.0:
	set(value):
		speed = value
		_update_shader_param("speed", value)

@export var block_size: float = 15.0:
	set(value):
		block_size = value
		_update_shader_param("block_size", value)

@export_category("RGB Split")
@export var rgb_split_horizontal: float = 0.01:
	set(value):
		rgb_split_horizontal = value
		_update_shader_param("rgb_split_horizontal", value)

@export var rgb_split_vertical: float = -0.03:
	set(value):
		rgb_split_vertical = value
		_update_shader_param("rgb_split_vertical", value)

@export_category("Alpha Fade (Transparency)")
@export var alpha_fade_top: float = 0.15:
	set(value):
		alpha_fade_top = value
		_update_shader_param("alpha_fade_top", value)

@export var alpha_fade_bottom: float = 0.15:
	set(value):
		alpha_fade_bottom = value
		_update_shader_param("alpha_fade_bottom", value)

@export var alpha_fade_left: float = 0.15:
	set(value):
		alpha_fade_left = value
		_update_shader_param("alpha_fade_left", value)

@export var alpha_fade_right: float = 0.15:
	set(value):
		alpha_fade_right = value
		_update_shader_param("alpha_fade_right", value)

@export_category("Presets")
@export var apply_full_screen: bool = false:
	set(value):
		apply_full_screen = value
		if value:
			_apply_preset_full_screen()

@export var apply_soft_edges: bool = false:
	set(value):
		apply_soft_edges = value
		if value:
			_apply_preset_soft_edges()

@export var apply_strong_vignette: bool = false:
	set(value):
		apply_strong_vignette = value
		if value:
			_apply_preset_strong_vignette()

func _ready():
	if not color_rect:
		push_error("ColorRect not found! Make sure it's a child and named 'ColorRect'")
		return
	
	if color_rect.material:
		color_rect.material = color_rect.material.duplicate()
	
	_update_all_params()

func _update_shader_param(param_name: String, value):
	if color_rect and color_rect.material:
		color_rect.material.set_shader_parameter(param_name, value)

func _update_all_params():
	if not color_rect or not color_rect.material:
		return
	
	color_rect.material.set_shader_parameter("intensity", intensity)
	color_rect.material.set_shader_parameter("speed", speed)
	color_rect.material.set_shader_parameter("block_size", block_size)
	color_rect.material.set_shader_parameter("rgb_split_horizontal", rgb_split_horizontal)
	color_rect.material.set_shader_parameter("rgb_split_vertical", rgb_split_vertical)
	color_rect.material.set_shader_parameter("alpha_fade_top", alpha_fade_top)
	color_rect.material.set_shader_parameter("alpha_fade_bottom", alpha_fade_bottom)
	color_rect.material.set_shader_parameter("alpha_fade_left", alpha_fade_left)
	color_rect.material.set_shader_parameter("alpha_fade_right", alpha_fade_right)

func _apply_preset_full_screen():
	alpha_fade_top = 0.0
	alpha_fade_bottom = 0.0
	alpha_fade_left = 0.0
	alpha_fade_right = 0.0

func _apply_preset_soft_edges():
	alpha_fade_top = 0.15
	alpha_fade_bottom = 0.15
	alpha_fade_left = 0.15
	alpha_fade_right = 0.15

func _apply_preset_strong_vignette():
	alpha_fade_top = 0.3
	alpha_fade_bottom = 0.3
	alpha_fade_left = 0.3
	alpha_fade_right = 0.3

# Публичные методы
func set_alpha_fade(top: float, bottom: float, left: float, right: float):
	alpha_fade_top = clamp(top, 0.0, 1.0)
	alpha_fade_bottom = clamp(bottom, 0.0, 1.0)
	alpha_fade_left = clamp(left, 0.0, 1.0)
	alpha_fade_right = clamp(right, 0.0, 1.0)

func set_alpha_fade_uniform(value: float):
	value = clamp(value, 0.0, 1.0)
	alpha_fade_top = value
	alpha_fade_bottom = value
	alpha_fade_left = value
	alpha_fade_right = value

func set_intensity(value: float):
	intensity = clamp(value, 0.0, 0.15)

func animate_alpha_fade(target: float, duration: float):
	var tween = create_tween()
	tween.tween_method(set_alpha_fade_uniform, alpha_fade_top, target, duration)

func trigger_glitch(duration: float = 0.1):
	var original_intensity = intensity
	intensity = 0.15
	await get_tree().create_timer(duration).timeout
	intensity = original_intensity
