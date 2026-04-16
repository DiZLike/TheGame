extends CanvasLayer

enum MenuSection { ACTIONS, BOTTOM_BUTTONS }

class BindingItem:
	var action: InputManager.InputAction
	var display_name: String
	
	var name_label: Label
	var key_value_label: Label
	var gamepad_value_label: Label
	var row_container: HBoxContainer
	
	func _init(p_action: InputManager.InputAction, p_display: String):
		action = p_action
		display_name = p_display

# UI элементы
@onready var controls_panel: Panel = $MarginContainer/ControlsPanel
@onready var color_rect: ColorRect = $ColorRect
@onready var actions_list: VBoxContainer = $MarginContainer/ControlsPanel/PanelMargin/MainVBox/ActionsList

@onready var reset_keyboard_button: Button = $MarginContainer/ControlsPanel/PanelMargin/MainVBox/BottomActions/ResetKeyboardButton
@onready var reset_gamepad_button: Button = $MarginContainer/ControlsPanel/PanelMargin/MainVBox/BottomActions/ResetGamepadButton
@onready var back_button: Button = $MarginContainer/ControlsPanel/PanelMargin/MainVBox/NavigationButtons/BackButton
@onready var apply_button: Button = $MarginContainer/ControlsPanel/PanelMargin/MainVBox/NavigationButtons/ApplyButton

# Данные
var binding_items: Array[BindingItem] = []
var current_section: MenuSection = MenuSection.ACTIONS
var current_action_index: int = 0
var current_binding_column: int = 0  # 0 - клавиатура, 1 - геймпад
var current_bottom_index: int = 0

var is_rebinding: bool = false
var rebind_action: InputManager.InputAction
var rebind_type: InputManager.BindingType

# Временное хранилище (для отмены изменений)
var temp_keyboard_bindings: Dictionary = {}
var temp_gamepad_bindings: Dictionary = {}

# Кнопки нижней панели
var bottom_buttons: Array[Button] = []

# Сигналы
signal controls_closed


func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	bottom_buttons = [reset_keyboard_button, reset_gamepad_button, back_button, apply_button]
	
	_create_action_items()
	_setup_focus_modes()
	_load_temp_bindings()
	
	reset_keyboard_button.pressed.connect(_on_reset_keyboard_pressed)
	reset_gamepad_button.pressed.connect(_on_reset_gamepad_pressed)
	back_button.pressed.connect(_on_back_pressed)
	apply_button.pressed.connect(_on_apply_pressed)
	
	_setup_hover_connections()
	
	_update_all_display_names()
	_update_visual_focus()
	
	# Подписываемся на изменения в InputManager
	InputManager.bindings_changed.connect(_on_input_manager_changed)


func _create_action_items() -> void:
	var actions = [
		InputManager.InputAction.MOVE_LEFT,
		InputManager.InputAction.MOVE_RIGHT,
		InputManager.InputAction.MOVE_UP,
		InputManager.InputAction.MOVE_DOWN,
		InputManager.InputAction.JUMP,
		InputManager.InputAction.SHOOT,
		InputManager.InputAction.MENU
	]
	
	var font = load("res://data/fonts/PressStart2P-Regular.ttf")
	
	for action in actions:
		var display_name = InputManager.get_action_display_name(action)
		var item = BindingItem.new(action, display_name)
		
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)
		item.row_container = hbox
		
		# Название действия
		var name_label = Label.new()
		name_label.text = item.display_name
		name_label.add_theme_font_override("font", font)
		name_label.add_theme_font_size_override("font_size", 14)
		name_label.add_theme_color_override("font_color", Color.WHITE)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		item.name_label = name_label
		
		# Спейсер
		var spacer = Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND
		
		# Панель для клавиши
		var key_panel = _create_binding_panel(font)
		var key_value_label = key_panel.get_child(0)
		key_value_label.add_theme_color_override("font_color", Color(1, 0.8, 0))
		item.key_value_label = key_value_label
		
		# Панель для геймпада
		var gamepad_panel = _create_binding_panel(font)
		var gamepad_value_label = gamepad_panel.get_child(0)
		gamepad_value_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1))
		item.gamepad_value_label = gamepad_value_label
		
		hbox.add_child(name_label)
		hbox.add_child(spacer)
		hbox.add_child(key_panel)
		hbox.add_child(gamepad_panel)
		
		actions_list.add_child(hbox)
		binding_items.append(item)


func _create_binding_panel(font: Font) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(130, 38)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.2, 0.2, 0.2, 1)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.5, 0.5, 0.5, 1)
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_right = 4
	panel_style.corner_radius_bottom_left = 4
	panel.add_theme_stylebox_override("panel", panel_style)
	
	var value_label = Label.new()
	value_label.add_theme_font_override("font", font)
	value_label.add_theme_font_size_override("font_size", 12)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.clip_text = true
	panel.add_child(value_label)
	
	return panel


func _setup_focus_modes() -> void:
	for btn in bottom_buttons:
		btn.focus_mode = Control.FOCUS_NONE


func _setup_hover_connections() -> void:
	for i in binding_items.size():
		var item = binding_items[i]
		item.key_value_label.get_parent().mouse_entered.connect(_on_action_hovered.bind(i, 0))
		item.gamepad_value_label.get_parent().mouse_entered.connect(_on_action_hovered.bind(i, 1))
	
	for i in bottom_buttons.size():
		bottom_buttons[i].mouse_entered.connect(_on_bottom_hovered.bind(i))


func _load_temp_bindings() -> void:
	for item in binding_items:
		temp_keyboard_bindings[item.action] = InputManager.get_keyboard_binding(item.action)
		temp_gamepad_bindings[item.action] = InputManager.get_gamepad_binding(item.action)


func _update_all_display_names() -> void:
	for item in binding_items:
		# Клавиатура
		if temp_keyboard_bindings.has(item.action):
			item.key_value_label.text = InputManager.get_keycode_string(temp_keyboard_bindings[item.action])
		else:
			item.key_value_label.text = "—"
		
		# Геймпад
		if temp_gamepad_bindings.has(item.action):
			item.gamepad_value_label.text = InputManager.get_gamepad_binding_string(temp_gamepad_bindings[item.action])
		else:
			item.gamepad_value_label.text = "—"


func _update_visual_focus() -> void:
	# Сбрасываем цвета всех названий действий
	for item in binding_items:
		item.name_label.add_theme_color_override("font_color", Color.WHITE)
		var key_panel = item.key_value_label.get_parent()
		var gamepad_panel = item.gamepad_value_label.get_parent()
		key_panel.get("theme_override_styles/panel").border_color = Color(0.5, 0.5, 0.5, 1)
		gamepad_panel.get("theme_override_styles/panel").border_color = Color(0.5, 0.5, 0.5, 1)
	
	# Сбрасываем цвета кнопок нижней панели
	for btn in bottom_buttons:
		btn.add_theme_color_override("font_color", Color.WHITE)
	
	match current_section:
		MenuSection.ACTIONS:
			var item = binding_items[current_action_index]
			item.name_label.add_theme_color_override("font_color", Color(1, 0.8, 0))
			
			if current_binding_column == 0:
				var panel = item.key_value_label.get_parent()
				panel.get("theme_override_styles/panel").border_color = Color(1, 0.8, 0, 1)
			else:
				var panel = item.gamepad_value_label.get_parent()
				panel.get("theme_override_styles/panel").border_color = Color(0.4, 0.8, 1, 1)
		
		MenuSection.BOTTOM_BUTTONS:
			bottom_buttons[current_bottom_index].add_theme_color_override("font_color", Color(1, 0.8, 0))


func _on_action_hovered(action_idx: int, column: int) -> void:
	if is_rebinding:
		return
	current_section = MenuSection.ACTIONS
	current_action_index = action_idx
	current_binding_column = column
	_update_visual_focus()


func _on_bottom_hovered(btn_idx: int) -> void:
	if is_rebinding:
		return
	current_section = MenuSection.BOTTOM_BUTTONS
	current_bottom_index = btn_idx
	_update_visual_focus()


func _start_rebind(action: InputManager.InputAction, type: InputManager.BindingType) -> void:
	if is_rebinding:
		return
	
	is_rebinding = true
	rebind_action = action
	rebind_type = type
	
	var item = _get_item_by_action(action)
	if type == InputManager.BindingType.KEYBOARD:
		item.key_value_label.text = "НАЖМИТЕ КЛАВИШУ..."
		item.key_value_label.add_theme_color_override("font_color", Color(1, 1, 0))
	else:
		item.gamepad_value_label.text = "НАЖМИТЕ КНОПКУ..."
		item.gamepad_value_label.add_theme_color_override("font_color", Color(1, 1, 0))


func _get_item_by_action(action: InputManager.InputAction) -> BindingItem:
	for item in binding_items:
		if item.action == action:
			return item
	return null


func _on_reset_keyboard_pressed() -> void:
	for item in binding_items:
		temp_keyboard_bindings[item.action] = InputManager.DEFAULT_KEYBOARD[item.action]
	_update_all_display_names()


func _on_reset_gamepad_pressed() -> void:
	for item in binding_items:
		temp_gamepad_bindings[item.action] = InputManager.DEFAULT_GAMEPAD[item.action]
	_update_all_display_names()


func _on_back_pressed() -> void:
	_close_menu()


func _on_apply_pressed() -> void:
	# Сохраняем временные привязки в InputManager
	for item in binding_items:
		if temp_keyboard_bindings.has(item.action):
			InputManager.set_keyboard_binding(item.action, temp_keyboard_bindings[item.action])
		if temp_gamepad_bindings.has(item.action):
			InputManager.set_gamepad_binding(item.action, temp_gamepad_bindings[item.action])
	
	InputManager.save_bindings()
	_close_menu()


func _on_input_manager_changed() -> void:
	# Обновляем временные привязки из InputManager
	_load_temp_bindings()
	_update_all_display_names()


func _close_menu() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(color_rect, "modulate:a", 0.0, 0.2)
	tween.tween_property(controls_panel, "modulate:a", 0.0, 0.15)
	tween.tween_property(controls_panel, "position:x", controls_panel.position.x - 20, 0.15)
	
	await get_tree().create_timer(0.2).timeout
	controls_closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	
	# Режим переназначения
	if is_rebinding:
		_handle_rebind_input(event)
		return
	
	# Обычная навигация
	match current_section:
		MenuSection.ACTIONS:
			_handle_actions_input(event)
		MenuSection.BOTTOM_BUTTONS:
			_handle_bottom_input(event)
	
	# Кнопка отмены
	if event.is_action_pressed("shoot") or event.is_action_pressed("ui_cancel"):
		if is_rebinding:
			_cancel_rebind()
			get_viewport().set_input_as_handled()
		else:
			_on_back_pressed()
			get_viewport().set_input_as_handled()


func _handle_rebind_input(event: InputEvent) -> void:
	if rebind_type == InputManager.BindingType.KEYBOARD:
		if event is InputEventKey and event.pressed:
			var keycode = event.keycode
			
			# Не позволяем назначить Escape кроме как для MENU
			if keycode != KEY_ESCAPE or rebind_action == InputManager.InputAction.MENU:
				temp_keyboard_bindings[rebind_action] = keycode
			
			_end_rebind()
			get_viewport().set_input_as_handled()
			
		elif event is InputEventJoypadButton and event.pressed:
			if event.button_index == JOY_BUTTON_BACK:
				_cancel_rebind()
				get_viewport().set_input_as_handled()
	
	elif rebind_type == InputManager.BindingType.GAMEPAD:
		if event is InputEventJoypadButton and event.pressed:
			if event.button_index == JOY_BUTTON_BACK:
				_cancel_rebind()
				get_viewport().set_input_as_handled()
			else:
				temp_gamepad_bindings[rebind_action] = { "type": "button", "index": event.button_index }
				_end_rebind()
				get_viewport().set_input_as_handled()
		elif event is InputEventJoypadMotion and abs(event.axis_value) > 0.5:
			temp_gamepad_bindings[rebind_action] = { 
				"type": "axis", 
				"axis": event.axis, 
				"direction": 1 if event.axis_value > 0 else -1 
			}
			_end_rebind()
			get_viewport().set_input_as_handled()


func _cancel_rebind() -> void:
	is_rebinding = false
	_update_all_display_names()
	_update_visual_focus()


func _end_rebind() -> void:
	is_rebinding = false
	_update_all_display_names()
	_update_visual_focus()


func _handle_actions_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		current_action_index = max(0, current_action_index - 1)
		_update_visual_focus()
		get_viewport().set_input_as_handled()
	
	elif event.is_action_pressed("move_down"):
		if current_action_index == binding_items.size() - 1:
			current_section = MenuSection.BOTTOM_BUTTONS
			current_bottom_index = 0
		else:
			current_action_index = min(binding_items.size() - 1, current_action_index + 1)
		_update_visual_focus()
		get_viewport().set_input_as_handled()
	
	elif event.is_action_pressed("move_left"):
		current_binding_column = 0
		_update_visual_focus()
		get_viewport().set_input_as_handled()
	
	elif event.is_action_pressed("move_right"):
		current_binding_column = 1
		_update_visual_focus()
		get_viewport().set_input_as_handled()
	
	elif event.is_action_pressed("jump"):
		var item = binding_items[current_action_index]
		if current_binding_column == 0:
			_start_rebind(item.action, InputManager.BindingType.KEYBOARD)
		else:
			_start_rebind(item.action, InputManager.BindingType.GAMEPAD)
		get_viewport().set_input_as_handled()


func _handle_bottom_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		if current_bottom_index <= 1:
			current_section = MenuSection.ACTIONS
			current_action_index = binding_items.size() - 1
			current_binding_column = 0
		else:
			current_bottom_index = max(0, current_bottom_index - 1)
		_update_visual_focus()
		get_viewport().set_input_as_handled()
	
	elif event.is_action_pressed("move_down"):
		current_bottom_index = min(bottom_buttons.size() - 1, current_bottom_index + 1)
		_update_visual_focus()
		get_viewport().set_input_as_handled()
	
	elif event.is_action_pressed("move_left"):
		current_bottom_index = max(0, current_bottom_index - 1)
		_update_visual_focus()
		get_viewport().set_input_as_handled()
	
	elif event.is_action_pressed("move_right"):
		if current_bottom_index <= 1:
			current_bottom_index = min(bottom_buttons.size() - 1, current_bottom_index + 1)
		_update_visual_focus()
		get_viewport().set_input_as_handled()
	
	elif event.is_action_pressed("jump"):
		bottom_buttons[current_bottom_index].emit_signal("pressed")
		get_viewport().set_input_as_handled()
