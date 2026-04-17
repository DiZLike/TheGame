extends ColorRect

@export var update_mode: UpdateMode = UpdateMode.WHEN_CHANGED
@export var update_interval: float = 0.1

# Параметры глитча (теперь экспортируемые)
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

@export var rgb_split_horizontal: float = 0.01:
	set(value):
		rgb_split_horizontal = value
		_update_shader_param("rgb_split_horizontal", value)

@export var rgb_split_vertical: float = -0.03:
	set(value):
		rgb_split_vertical = value
		_update_shader_param("rgb_split_vertical", value)

enum UpdateMode {
	ONCE,
	WHEN_CHANGED,
	CONTINUOUS
}

var _parent: Control
var _last_size: Vector2
var _update_timer: float = 0.0
var _is_capturing: bool = false
var _update_requested: bool = false

func _ready():
	await get_tree().process_frame
	
	_parent = get_parent()
	if not _parent is Control:
		push_error("GlitchEffect должен быть дочерним элементом Control")
		return
	
	size = _parent.size
	_last_size = _parent.size
	position = Vector2.ZERO
	
	# Применяем начальные параметры шейдера
	_apply_all_shader_params()
	
	# Первый захват
	await capture_and_apply()
	
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 0
	
	# Подключаемся к сигналу перерисовки родителя
	if _parent.has_signal("draw"):
		_parent.draw.connect(_on_parent_draw)

func _process(delta):
	if not _parent:
		return
	
	var size_changed = _parent.size != _last_size
	if size_changed:
		size = _parent.size
		position = Vector2.ZERO
		_last_size = _parent.size
	
	match update_mode:
		UpdateMode.ONCE:
			pass
			
		UpdateMode.WHEN_CHANGED:
			if size_changed or _update_requested:
				await capture_and_apply()
				_update_requested = false
				
		UpdateMode.CONTINUOUS:
			_update_timer += delta
			if _update_timer >= update_interval:
				await capture_and_apply()
				_update_timer = 0.0

func _on_parent_draw():
	# Когда родитель перерисовывается, запрашиваем обновление
	if update_mode == UpdateMode.WHEN_CHANGED:
		request_update()

func capture_and_apply():
	if _is_capturing:
		return
	
	_is_capturing = true
	
	var captured_texture = await capture_control_texture(_parent)
	if captured_texture and material:
		material.set_shader_parameter("BASE_TEXTURE", captured_texture)
		_apply_all_shader_params()  # Применяем параметры заново после смены текстуры
	
	_is_capturing = false

func capture_control_texture(control: Control):
	var viewport = SubViewport.new()
	viewport.transparent_bg = true
	viewport.size = control.size
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	
	var duplicate = control.duplicate()
	duplicate.position = Vector2.ZERO
	duplicate.queue_redraw()
	
	viewport.add_child(duplicate)
	add_child(viewport)
	
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	var viewport_texture = viewport.get_texture()
	var captured_image = viewport_texture.get_image()
	var texture = ImageTexture.create_from_image(captured_image)
	
	viewport.queue_free()
	
	return texture

func _update_shader_param(param_name: String, value):
	if material:
		material.set_shader_parameter(param_name, value)

func _apply_all_shader_params():
	if not material:
		return
	
	material.set_shader_parameter("intensity", intensity)
	material.set_shader_parameter("speed", speed)
	material.set_shader_parameter("block_size", block_size)
	material.set_shader_parameter("rgb_split_horizontal", rgb_split_horizontal)
	material.set_shader_parameter("rgb_split_vertical", rgb_split_vertical)

func request_update():
	_update_requested = true

func update_now():
	await capture_and_apply()
