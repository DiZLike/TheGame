# main_menu.gd (обновлённый)
extends Node2D

@onready var buttons_container: VBoxContainer = $Panel/MainLayout/LeftPanel/ButtonsContainer
@onready var resume_button: Button = $Panel/MainLayout/LeftPanel/ButtonsContainer/Resume
@onready var new_game_button: Button = $Panel/MainLayout/LeftPanel/ButtonsContainer/NewGame
@onready var settings_button: Button = $Panel/MainLayout/LeftPanel/ButtonsContainer/Settings
@onready var quit_button: Button = $Panel/MainLayout/LeftPanel/ButtonsContainer/QuitButton

var buttons: Array[Button] = []
var current_button_index: int = 0
var settings_menu_scene = preload("res://scenes/ui/menu/settings_menu.tscn")  # Укажите правильный путь


func _ready() -> void:
	# Собираем кнопки
	for child in buttons_container.get_children():
		if child is Button:
			buttons.append(child)
	
	# Активируем кнопку "Продолжить" если есть сохранение
	_update_resume_button_state()
	
	# Подключаем сигналы наведения
	for i in buttons.size():
		var button = buttons[i]
		button.mouse_entered.connect(_on_button_hovered.bind(i))
	
	# Визуальное выделение первого элемента
	_update_visual_focus()


func _update_resume_button_state() -> void:
	# Проверяем наличие сохранения
	var has_save = false #SaveManager.has_save() if SaveManager else false
	resume_button.disabled = not has_save
	if not has_save:
		resume_button.modulate = Color(0.5, 0.5, 0.5, 1)
	else:
		resume_button.modulate = Color.WHITE


func _update_visual_focus() -> void:
	# Подсветка кнопок
	for i in buttons.size():
		var button = buttons[i]
		if i == current_button_index:
			button.add_theme_color_override("font_color", Color(1, 0.8, 0))
		else:
			button.add_theme_color_override("font_color", Color.WHITE)


func _on_button_hovered(index: int) -> void:
	current_button_index = index
	_update_visual_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	
	if event.is_action_pressed("ui_up"):
		current_button_index = max(0, current_button_index - 1)
		_update_visual_focus()
	elif event.is_action_pressed("ui_down"):
		current_button_index = min(buttons.size() - 1, current_button_index + 1)
		_update_visual_focus()
	elif event.is_action_pressed("jump") or event.is_action_pressed("ui_accept"):
		_execute_button_action(buttons[current_button_index])
	elif event.is_action_pressed("ui_cancel"):
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
