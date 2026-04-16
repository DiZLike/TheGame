extends Node

# Список действий
enum InputAction {
	MOVE_LEFT,
	MOVE_RIGHT,
	MOVE_UP,
	MOVE_DOWN,
	JUMP,
	SHOOT,
	MENU
}

enum BindingType { KEYBOARD, GAMEPAD }

# Сигналы для оповещения об изменениях
signal bindings_changed
signal binding_rebinded(action: InputAction, type: BindingType)

# Конфигурационный файл
const CONFIG_PATH = "user://input_settings.cfg"

# Дефолтные значения
const DEFAULT_KEYBOARD = {
	InputAction.MOVE_LEFT: KEY_A,
	InputAction.MOVE_RIGHT: KEY_D,
	InputAction.MOVE_UP: KEY_W,
	InputAction.MOVE_DOWN: KEY_S,
	InputAction.JUMP: KEY_KP_3,
	InputAction.SHOOT: KEY_KP_1,
	InputAction.MENU: KEY_ESCAPE
}

const DEFAULT_GAMEPAD = {
	InputAction.MOVE_LEFT: { "type": "button", "index": JOY_BUTTON_DPAD_LEFT },
	InputAction.MOVE_RIGHT: { "type": "button", "index": JOY_BUTTON_DPAD_RIGHT },
	InputAction.MOVE_UP: { "type": "button", "index": JOY_BUTTON_DPAD_UP },
	InputAction.MOVE_DOWN: { "type": "button", "index": JOY_BUTTON_DPAD_DOWN },
	InputAction.JUMP: { "type": "button", "index": JOY_BUTTON_A },
	InputAction.SHOOT: { "type": "button", "index": JOY_BUTTON_X },
	InputAction.MENU: { "type": "button", "index": JOY_BUTTON_START }
}

# Текущие привязки
var keyboard_bindings: Dictionary = {}
var gamepad_bindings: Dictionary = {}

# Флаг инициализации
var is_initialized: bool = false


func _ready() -> void:
	initialize()


func initialize() -> void:
	if is_initialized:
		return
	
	load_bindings()
	is_initialized = true


func load_bindings() -> void:
	# Пробуем загрузить из конфига
	if load_bindings_from_config():
		apply_bindings_to_input_map()
		return
	
	# Если конфига нет - используем дефолтные значения
	reset_to_defaults()
	apply_bindings_to_input_map()


func load_bindings_from_config() -> bool:
	var config = ConfigFile.new()
	var err = config.load(CONFIG_PATH)
	if err != OK:
		return false
	
	keyboard_bindings.clear()
	gamepad_bindings.clear()
	
	for action in InputAction.values():
		var action_str = InputAction.keys()[action]
		
		# Загружаем клавиатурную привязку
		var keycode = config.get_value("keyboard", action_str, null)
		if keycode != null:
			keyboard_bindings[action] = keycode
		
		# Загружаем геймпадную привязку
		var gamepad_data = config.get_value("gamepad", action_str, null)
		if gamepad_data != null:
			gamepad_bindings[action] = gamepad_data
	
	# Если какие-то привязки отсутствуют, дополняем дефолтными
	for action in InputAction.values():
		if not keyboard_bindings.has(action) and DEFAULT_KEYBOARD.has(action):
			keyboard_bindings[action] = DEFAULT_KEYBOARD[action]
		if not gamepad_bindings.has(action) and DEFAULT_GAMEPAD.has(action):
			gamepad_bindings[action] = DEFAULT_GAMEPAD[action]
	
	return true


func save_bindings() -> void:
	var config = ConfigFile.new()
	
	for action in InputAction.values():
		var action_str = InputAction.keys()[action]
		
		if keyboard_bindings.has(action):
			config.set_value("keyboard", action_str, keyboard_bindings[action])
		
		if gamepad_bindings.has(action):
			config.set_value("gamepad", action_str, gamepad_bindings[action])
	
	config.save(CONFIG_PATH)
	apply_bindings_to_input_map()
	bindings_changed.emit()


func reset_to_defaults() -> void:
	keyboard_bindings = DEFAULT_KEYBOARD.duplicate()
	gamepad_bindings = DEFAULT_GAMEPAD.duplicate()


func reset_keyboard_to_defaults() -> void:
	keyboard_bindings = DEFAULT_KEYBOARD.duplicate()
	bindings_changed.emit()


func reset_gamepad_to_defaults() -> void:
	gamepad_bindings = DEFAULT_GAMEPAD.duplicate()
	bindings_changed.emit()


func set_keyboard_binding(action: InputAction, keycode: Key) -> void:
	keyboard_bindings[action] = keycode
	binding_rebinded.emit(action, BindingType.KEYBOARD)


func set_gamepad_binding(action: InputAction, binding: Dictionary) -> void:
	gamepad_bindings[action] = binding
	binding_rebinded.emit(action, BindingType.GAMEPAD)


func get_keyboard_binding(action: InputAction) -> Key:
	return keyboard_bindings.get(action, KEY_UNKNOWN)


func get_gamepad_binding(action: InputAction) -> Dictionary:
	return gamepad_bindings.get(action, {})


func apply_bindings_to_input_map() -> void:
	for action in InputAction.values():
		var action_name = InputAction.keys()[action].to_lower()
		
		# Очищаем старые привязки
		InputMap.action_erase_events(action_name)
		
		# Добавляем клавиатурную привязку
		if keyboard_bindings.has(action):
			var key_event = InputEventKey.new()
			key_event.keycode = keyboard_bindings[action]
			InputMap.action_add_event(action_name, key_event)
		
		# Добавляем геймпадную привязку
		if gamepad_bindings.has(action):
			var binding = gamepad_bindings[action]
			if binding.type == "button":
				var joy_event = InputEventJoypadButton.new()
				joy_event.button_index = binding.index
				InputMap.action_add_event(action_name, joy_event)
			else:
				var joy_event = InputEventJoypadMotion.new()
				joy_event.axis = binding.axis
				joy_event.axis_value = binding.direction
				InputMap.action_add_event(action_name, joy_event)


func get_keycode_string(keycode: Key) -> String:
	return OS.get_keycode_string(keycode)


func get_gamepad_button_name(button_index: int) -> String:
	var button_names = {
		JOY_BUTTON_A: "A",
		JOY_BUTTON_B: "B",
		JOY_BUTTON_X: "X",
		JOY_BUTTON_Y: "Y",
		JOY_BUTTON_LEFT_SHOULDER: "LB",
		JOY_BUTTON_RIGHT_SHOULDER: "RB",
		JOY_BUTTON_START: "START",
		JOY_BUTTON_BACK: "SELECT",
		JOY_BUTTON_DPAD_UP: "D-PAD ↑",
		JOY_BUTTON_DPAD_DOWN: "D-PAD ↓",
		JOY_BUTTON_DPAD_LEFT: "D-PAD ←",
		JOY_BUTTON_DPAD_RIGHT: "D-PAD →",
		JOY_BUTTON_LEFT_STICK: "L3",
		JOY_BUTTON_RIGHT_STICK: "R3",
		JOY_BUTTON_GUIDE: "HOME",
		JOY_BUTTON_MISC1: "SHARE"
	}
	
	# Для триггеров
	if button_index == 6:
		return "LT"
	elif button_index == 7:
		return "RT"
	
	return button_names.get(button_index, "BTN " + str(button_index))


func get_gamepad_axis_name(axis: int, direction: int) -> String:
	var axis_names = {
		JOY_AXIS_LEFT_X: "L-STICK",
		JOY_AXIS_LEFT_Y: "L-STICK",
		JOY_AXIS_RIGHT_X: "R-STICK",
		JOY_AXIS_RIGHT_Y: "R-STICK"
	}
	var base_name = axis_names.get(axis, "AXIS " + str(axis))
	var dir_str = ""
	
	if axis == JOY_AXIS_LEFT_X or axis == JOY_AXIS_RIGHT_X:
		dir_str = "→" if direction > 0 else "←"
	elif axis == JOY_AXIS_LEFT_Y or axis == JOY_AXIS_RIGHT_Y:
		dir_str = "↓" if direction > 0 else "↑"
	
	return base_name + " " + dir_str


func get_gamepad_binding_string(binding: Dictionary) -> String:
	if binding.is_empty():
		return "—"
	
	if binding.type == "button":
		return get_gamepad_button_name(binding.index)
	else:
		return get_gamepad_axis_name(binding.axis, binding.direction)


func get_action_display_name(action: InputAction) -> String:
	var names = {
		InputAction.MOVE_LEFT: "ВЛЕВО",
		InputAction.MOVE_RIGHT: "ВПРАВО",
		InputAction.MOVE_UP: "ВВЕРХ",
		InputAction.MOVE_DOWN: "ВНИЗ",
		InputAction.JUMP: "ПРЫЖОК",
		InputAction.SHOOT: "ВЫСТРЕЛ",
		InputAction.MENU: "ПАУЗА"
	}
	return names.get(action, "UNKNOWN")
