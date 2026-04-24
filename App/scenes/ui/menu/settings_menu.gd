# settings_menu.gd
extends CanvasLayer

enum MenuSection { SLIDERS, BUTTONS }

# UI элементы
@onready var settings_panel: Panel = $MarginContainer/SettingsPanel
@onready var color_rect: TextureRect = $ColorRect

# Слайдеры и значения
@onready var master_label: Label = $MarginContainer/SettingsPanel/PanelMargin/MainVBox/VolumeContainer/MasterContainer/MasterLabel
@onready var master_slider: HSlider = $MarginContainer/SettingsPanel/PanelMargin/MainVBox/VolumeContainer/MasterContainer/MasterHBox/MasterSlider
@onready var master_value: Label = $MarginContainer/SettingsPanel/PanelMargin/MainVBox/VolumeContainer/MasterContainer/MasterHBox/MasterValue

@onready var sfx_label: Label = $MarginContainer/SettingsPanel/PanelMargin/MainVBox/VolumeContainer/SFXContainer/SFXLabel
@onready var sfx_slider: HSlider = $MarginContainer/SettingsPanel/PanelMargin/MainVBox/VolumeContainer/SFXContainer/SFXHBox/SFXSlider
@onready var sfx_value: Label = $MarginContainer/SettingsPanel/PanelMargin/MainVBox/VolumeContainer/SFXContainer/SFXHBox/SFXValue

@onready var music_label: Label = $MarginContainer/SettingsPanel/PanelMargin/MainVBox/VolumeContainer/MusicContainer/MusicLabel
@onready var music_slider: HSlider = $MarginContainer/SettingsPanel/PanelMargin/MainVBox/VolumeContainer/MusicContainer/MusicHBox/MusicSlider
@onready var music_value: Label = $MarginContainer/SettingsPanel/PanelMargin/MainVBox/VolumeContainer/MusicContainer/MusicHBox/MusicValue

# Кнопки
@onready var controls_button: Button = $MarginContainer/SettingsPanel/PanelMargin/MainVBox/ControlsButton
@onready var back_button: Button = $MarginContainer/SettingsPanel/PanelMargin/MainVBox/NavigationButtons/BackButton
@onready var apply_button: Button = $MarginContainer/SettingsPanel/PanelMargin/MainVBox/NavigationButtons/ApplyButton

# Элементы для навигации
var sliders: Array[HSlider] = []
var buttons: Array[Button] = []

var current_section: MenuSection = MenuSection.SLIDERS
var current_slider_index: int = 0
var current_button_index: int = 0

# Временное хранилище настроек (до применения)
var temp_master_volume: float = 0.0
var temp_sfx_volume: float = 0.0
var temp_music_volume: float = 0.0

# Сигналы
signal settings_closed
signal controls_requested


func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Настраиваем фон
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Отключаем встроенный фокус Godot у всех элементов
	_setup_focus_modes()
	
	# Заполняем массивы для навигации
	sliders = [master_slider, sfx_slider, music_slider]
	buttons = [controls_button, back_button, apply_button]
	
	# Загружаем текущие настройки из AudioManager
	_load_settings_to_temp()
	
	# Устанавливаем значения слайдеров (конвертация из 0.0-1.0 в 0-100)
	master_slider.value = temp_master_volume * 100.0
	sfx_slider.value = temp_sfx_volume * 100.0
	music_slider.value = temp_music_volume * 100.0
	
	# Подключаем сигналы слайдеров
	master_slider.value_changed.connect(_on_master_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	
	# Подключаем сигналы кнопок
	controls_button.pressed.connect(_on_controls_pressed)
	back_button.pressed.connect(_on_back_pressed)
	apply_button.pressed.connect(_on_apply_pressed)
	
	# Подключаем наведение мыши
	for i in sliders.size():
		sliders[i].mouse_entered.connect(_on_slider_hovered.bind(i))
	for i in buttons.size():
		buttons[i].mouse_entered.connect(_on_button_hovered.bind(i))
	
	# Обновляем отображение
	_update_value_labels()
	_update_visual_focus()
	
	# Применяем временные настройки (для предпросмотра)
	_apply_temp_settings()


func _setup_focus_modes() -> void:
	# Отключаем фокус у всех элементов, чтобы Godot не вмешивался
	master_slider.focus_mode = Control.FOCUS_NONE
	sfx_slider.focus_mode = Control.FOCUS_NONE
	music_slider.focus_mode = Control.FOCUS_NONE
	controls_button.focus_mode = Control.FOCUS_NONE
	back_button.focus_mode = Control.FOCUS_NONE
	apply_button.focus_mode = Control.FOCUS_NONE


func _load_settings_to_temp() -> void:
	# Загружаем текущие настройки из AudioManager
	temp_master_volume = AudioManager.get_master_volume()
	temp_sfx_volume = AudioManager.get_sfx_volume()
	temp_music_volume = AudioManager.get_music_volume()


func _apply_temp_settings() -> void:
	# Временно применяем настройки для предпросмотра (не сохраняя в файл)
	AudioManager.set_master_volume(temp_master_volume)
	AudioManager.set_sfx_volume(temp_sfx_volume)
	AudioManager.set_music_volume(temp_music_volume)


func _save_settings() -> void:
	# Сохраняем временные настройки в файл через AudioManager
	AudioManager.save_to_file()


func _update_value_labels() -> void:
	master_value.text = str(int(master_slider.value)) + "%"
	sfx_value.text = str(int(sfx_slider.value)) + "%"
	music_value.text = str(int(music_slider.value)) + "%"


func _update_visual_focus() -> void:
	# Сбрасываем цвета всех кнопок
	for button in buttons:
		button.add_theme_color_override("font_color", Color.WHITE)
	
	# Подсвечиваем активный элемент
	match current_section:
		MenuSection.SLIDERS:
			_mark_slider_selected(current_slider_index, true)
			# Сбрасываем подсветку кнопок
			if buttons.size() > current_button_index:
				buttons[current_button_index].add_theme_color_override("font_color", Color.WHITE)
			
		MenuSection.BUTTONS:
			_mark_slider_selected(current_slider_index, false)
			# Подсвечиваем активную кнопку
			if buttons.size() > current_button_index:
				buttons[current_button_index].add_theme_color_override("font_color", Color(1, 0.8, 0))


func _mark_slider_selected(index: int, selected: bool) -> void:
	var labels = [master_label, sfx_label, music_label]
	for i in labels.size():
		if i == index and selected:
			labels[i].add_theme_color_override("font_color", Color(1, 0.8, 0))
		else:
			labels[i].add_theme_color_override("font_color", Color.WHITE)


func _on_slider_hovered(index: int) -> void:
	current_section = MenuSection.SLIDERS
	current_slider_index = index
	_update_visual_focus()


func _on_button_hovered(index: int) -> void:
	current_section = MenuSection.BUTTONS
	current_button_index = index
	_update_visual_focus()


func _on_master_volume_changed(value: float) -> void:
	master_value.text = str(int(value)) + "%"
	temp_master_volume = value / 100.0
	_apply_temp_settings()


func _on_sfx_volume_changed(value: float) -> void:
	sfx_value.text = str(int(value)) + "%"
	temp_sfx_volume = value / 100.0
	_apply_temp_settings()


func _on_music_volume_changed(value: float) -> void:
	music_value.text = str(int(value)) + "%"
	temp_music_volume = value / 100.0
	_apply_temp_settings()

func _on_controls_pressed() -> void:
	# Отправляем сигнал (если кому-то ещё нужно знать)
	controls_requested.emit()
	_open_controls_menu()


func _open_controls_menu() -> void:
	# Загружаем сцену управления
	var controls_menu_scene = load("res://scenes/ui/menu/control/controls_menu.tscn")
	var controls_menu = controls_menu_scene.instantiate()
	
	# Добавляем на сцену
	get_tree().root.add_child(controls_menu)
	
	# Подключаем сигнал закрытия
	controls_menu.controls_closed.connect(_on_controls_closed)
	
	# Скрываем текущее меню настроек
	hide()


func _on_controls_closed() -> void:
	# Показываем меню настроек обратно
	show()


func _close_menu() -> void:
	# Анимация закрытия
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(color_rect, "modulate:a", 0.0, 0.2)
	tween.tween_property(settings_panel, "modulate:a", 0.0, 0.15)
	tween.tween_property(settings_panel, "position:x", settings_panel.position.x - 20, 0.15)
	
	await get_tree().create_timer(0.2).timeout
	settings_closed.emit()
	queue_free()

func _on_back_pressed() -> void:
	# Отмена - восстанавливаем настройки из сохраненного файла
	AudioManager.load_from_file()
	_close_menu()


func _on_apply_pressed() -> void:
	# Применить - сохраняем текущие временные настройки
	_save_settings()
	_close_menu()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	
	# Обработка навигации
	match current_section:
		MenuSection.SLIDERS:
			_handle_sliders_input(event)
		MenuSection.BUTTONS:
			_handle_buttons_input(event)
	
	# Кнопка отмены (Esc или Shoot)
	if event.is_action_pressed("shoot") or event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()


func _handle_sliders_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		current_slider_index = max(0, current_slider_index - 1)
		_update_visual_focus()
		get_viewport().set_input_as_handled()
		
	elif event.is_action_pressed("move_down"):
		if current_slider_index == sliders.size() - 1:
			# Переход на кнопки
			current_section = MenuSection.BUTTONS
			current_button_index = 0
		else:
			current_slider_index = min(sliders.size() - 1, current_slider_index + 1)
		_update_visual_focus()
		get_viewport().set_input_as_handled()
		
	elif event.is_action_pressed("move_left"):
		var slider = sliders[current_slider_index]
		slider.value = max(slider.min_value, slider.value - slider.step)
		get_viewport().set_input_as_handled()
		
	elif event.is_action_pressed("move_right"):
		var slider = sliders[current_slider_index]
		slider.value = min(slider.max_value, slider.value + slider.step)
		get_viewport().set_input_as_handled()
		
	elif event.is_action_pressed("jump") or event.is_action_pressed("accept"):
		# Enter на слайдере — переход к кнопкам
		current_section = MenuSection.BUTTONS
		current_button_index = 0
		_update_visual_focus()
		get_viewport().set_input_as_handled()


func _handle_buttons_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		if current_button_index == 0:
			# Переход обратно на слайдеры
			current_section = MenuSection.SLIDERS
			current_slider_index = sliders.size() - 1
		else:
			current_button_index = max(0, current_button_index - 1)
		_update_visual_focus()
		get_viewport().set_input_as_handled()
		
	elif event.is_action_pressed("move_down"):
		current_button_index = min(buttons.size() - 1, current_button_index + 1)
		_update_visual_focus()
		get_viewport().set_input_as_handled()
		
	elif event.is_action_pressed("jump") or event.is_action_pressed("accept"):
		buttons[current_button_index].emit_signal("pressed")
		get_viewport().set_input_as_handled()
