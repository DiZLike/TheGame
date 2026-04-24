# main_menu.gd (только клавиатурное управление)
extends CanvasLayer

@onready var buttons_container: VBoxContainer = $Panel/MainLayout/LeftPanel/ButtonsContainer
@onready var resume_button: Button = $Panel/MainLayout/LeftPanel/ButtonsContainer/Resume
@onready var new_game_button: Button = $Panel/MainLayout/LeftPanel/ButtonsContainer/NewGame
@onready var settings_button: Button = $Panel/MainLayout/LeftPanel/ButtonsContainer/Settings
@onready var quit_button: Button = $Panel/MainLayout/LeftPanel/ButtonsContainer/QuitButton

@export var menu_music: AudioStream

var buttons: Array[Button] = []
var current_button_index: int = 0
var settings_menu_scene = preload("res://scenes/ui/menu/settings_menu.tscn")

func _ready() -> void:
	AudioManager.set_music(menu_music)
	# Собираем кнопки
	for child in buttons_container.get_children():
		if child is Button:
			buttons.append(child)
			# Отключаем фокус мыши для кнопок
			child.focus_mode = Control.FOCUS_NONE
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Активируем кнопку "Продолжить" если есть сохранение
	_update_resume_button_state()
	
	# Находим первую активную кнопку для выделения
	_find_first_active_button()
	
	# Визуальное выделение первого элемента
	_update_visual_focus()


func _find_first_active_button() -> void:
	# Ищем первую не заблокированную кнопку
	for i in buttons.size():
		if not buttons[i].disabled:
			current_button_index = i
			return
	
	# Если все кнопки заблокированы (маловероятно), оставляем 0
	current_button_index = 0


func _update_resume_button_state() -> void:
	# Проверяем наличие сохранения
	var has_save = false #SaveManager.has_save() if SaveManager else false
	resume_button.disabled = not has_save
	if not has_save:
		resume_button.modulate = Color(0.5, 0.5, 0.5, 1)
	else:
		resume_button.modulate = Color.WHITE


func _find_next_active_button(direction: int) -> int:
	# direction: -1 для вверх, +1 для вниз
	var new_index = current_button_index
	var attempts = 0
	
	while attempts < buttons.size():
		new_index = (new_index + direction + buttons.size()) % buttons.size()
		if not buttons[new_index].disabled:
			return new_index
		attempts += 1
	
	# Если все кнопки заблокированы, возвращаем текущий индекс
	return current_button_index


func _update_visual_focus() -> void:
	# Подсветка кнопок
	for i in buttons.size():
		var button = buttons[i]
		if i == current_button_index:
			button.add_theme_color_override("font_color", Color(1, 0.8, 0))
		else:
			button.add_theme_color_override("font_color", Color.WHITE)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	
	if event.is_action_pressed("move_up"):
		current_button_index = _find_next_active_button(-1)
		_update_visual_focus()
	elif event.is_action_pressed("move_down"):
		current_button_index = _find_next_active_button(1)
		_update_visual_focus()
	elif event.is_action_pressed("jump") or event.is_action_pressed("accept"):
		# Выполняем действие только если кнопка не заблокирована
		var button = buttons[current_button_index]
		if not button.disabled:
			_execute_button_action(button)
	elif event.is_action_pressed("shoot"):
		# В главном меню Cancel не делает ничего (или можно добавить выход)
		pass


func _execute_button_action(button: Button) -> void:
	match button.name:
		"Resume":
			_on_resume_pressed()
		"NewGame":
			_on_new_game_pressed()
		"Settings":
			_on_settings_pressed()
		"QuitButton":
			_on_quit_pressed()


func _on_resume_pressed() -> void:
	print("Загрузка сохранения...")


func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_file("res://levels/level_1.tscn")


func _on_settings_pressed() -> void:
	# Скрываем главное меню, чтобы оно не мешало вводу
	hide()
	
	var settings_menu = settings_menu_scene.instantiate()
	# Добавляем настройки как отдельный CanvasLayer в корень сцены
	get_tree().root.add_child(settings_menu)
	
	# Подключаем сигнал закрытия
	settings_menu.settings_closed.connect(_on_settings_closed)


func _on_settings_closed() -> void:
	# Показываем главное меню обратно
	show()


func _on_controls_requested() -> void:
	print("Открытие настроек управления...")
	# Здесь можно открыть окно настройки управления


func _on_quit_pressed() -> void:
	print("Выход из игры...")
	get_tree().quit()
