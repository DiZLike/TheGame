extends Control

@onready var buttons_container: VBoxContainer = $CenterContainer/MainLayout/LeftPanel/ButtonsContainer
@onready var slots_grid: GridContainer = $CenterContainer/MainLayout/InventoryPanel/SlotsGrid
@onready var item_name_label: Label = $CenterContainer/MainLayout/ItemInfoPanel/ItemNameLabel
@onready var item_description_label: Label = $CenterContainer/MainLayout/ItemInfoPanel/ItemDescription

enum MenuSection { BUTTONS, INVENTORY }

var buttons: Array[Button] = []
var inventory_slots: Array[Control] = []
var current_section: MenuSection = MenuSection.BUTTONS
var current_button_index: int = 0
var current_slot_index: int = 0

# Сигналы
signal inventory_slot_selected(slot_index: int)
signal inventory_slot_used(slot_index: int)

func _ready() -> void:
	# Собираем кнопки
	for child in buttons_container.get_children():
		if child is Button:
			buttons.append(child)
	
	# Создаём слоты инвентаря
	_setup_inventory_slots()
	
	# Подключаем сигналы для навигации мышью
	_connect_mouse_signals()
	
	# Визуальное выделение первого элемента
	_update_visual_focus()

func _setup_inventory_slots() -> void:
	# Очищаем существующие слоты
	for child in slots_grid.get_children():
		child.queue_free()
	inventory_slots.clear()
	
	# Создаём 10 слотов
	var slot_count = 10
	
	for i in range(slot_count):
		var slot = _create_inventory_slot()
		slots_grid.add_child(slot)
		inventory_slots.append(slot)
		_update_slot_display(i)

func _create_inventory_slot() -> Control:
	var slot = Panel.new()
	slot.custom_minimum_size = Vector2(64, 64)
	slot.size = Vector2(64, 64)
	
	# Стиль слота
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.15, 0.9)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.4, 0.4, 1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	slot.add_theme_stylebox_override("panel", style)
	
	# Иконка предмета
	var icon = TextureRect.new()
	icon.name = "Icon"
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.size = Vector2(48, 48)
	icon.position = Vector2(8, 8)
	slot.add_child(icon)
	
	# Счётчик количества
	var count_label = Label.new()
	count_label.name = "Count"
	count_label.position = Vector2(4, 44)
	count_label.size = Vector2(56, 16)
	count_label.add_theme_font_size_override("font_size", 12)
	count_label.add_theme_color_override("font_color", Color.WHITE)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	slot.add_child(count_label)
	
	# Рамка выделения
	var highlight = Panel.new()
	highlight.name = "Highlight"
	highlight.size = Vector2(64, 64)
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var highlight_style = StyleBoxFlat.new()
	highlight_style.bg_color = Color(1, 0.8, 0, 0.3)
	highlight_style.border_width_left = 3
	highlight_style.border_width_right = 3
	highlight_style.border_width_top = 3
	highlight_style.border_width_bottom = 3
	highlight_style.border_color = Color(1, 0.8, 0, 1)
	highlight_style.corner_radius_top_left = 4
	highlight_style.corner_radius_top_right = 4
	highlight_style.corner_radius_bottom_left = 4
	highlight_style.corner_radius_bottom_right = 4
	highlight.add_theme_stylebox_override("panel", highlight_style)
	highlight.hide()
	slot.add_child(highlight)
	
	return slot

func _update_slot_display(slot_index: int) -> void:
	if slot_index >= inventory_slots.size():
		return
	
	var slot = inventory_slots[slot_index]
	var icon = slot.get_node("Icon") as TextureRect
	var count_label = slot.get_node("Count") as Label
	
	# Здесь будет логика отображения предметов из инвентаря
	icon.texture = null
	count_label.text = ""

func _update_slot_highlight() -> void:
	for i in inventory_slots.size():
		var slot = inventory_slots[i]
		var highlight = slot.get_node("Highlight")
		
		if i == current_slot_index and current_section == MenuSection.INVENTORY:
			highlight.show()
		else:
			highlight.hide()

func _update_button_highlight() -> void:
	for i in buttons.size():
		var button = buttons[i]
		if i == current_button_index and current_section == MenuSection.BUTTONS:
			button.add_theme_color_override("font_color", Color(1, 0.8, 0))
		else:
			button.add_theme_color_override("font_color", Color.WHITE)

func _update_visual_focus() -> void:
	_update_button_highlight()
	_update_slot_highlight()
	_update_item_info()

func _update_item_info() -> void:
	if current_section == MenuSection.INVENTORY and inventory_slots.size() > 0:
		# Здесь будет информация о предмете
		item_name_label.text = "Слот " + str(current_slot_index + 1)
		item_description_label.text = "Здесь может быть предмет"
	else:
		item_name_label.text = ""
		item_description_label.text = ""

func _connect_mouse_signals() -> void:
	for i in buttons.size():
		buttons[i].mouse_entered.connect(_on_button_hovered.bind(i))
	
	for i in inventory_slots.size():
		inventory_slots[i].mouse_entered.connect(_on_slot_hovered.bind(i))

func _on_button_hovered(index: int) -> void:
	current_section = MenuSection.BUTTONS
	current_button_index = index
	_update_visual_focus()

func _on_slot_hovered(index: int) -> void:
	current_section = MenuSection.INVENTORY
	current_slot_index = index
	_update_visual_focus()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	match current_section:
		MenuSection.BUTTONS:
			_handle_buttons_input(event)
		MenuSection.INVENTORY:
			_handle_inventory_input(event)
	
	if event.is_action_pressed("ui_cancel"):
		_on_resume_pressed()

func _handle_buttons_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up"):
		current_button_index = max(0, current_button_index - 1)
		_update_visual_focus()
	elif event.is_action_pressed("ui_down"):
		current_button_index = min(buttons.size() - 1, current_button_index + 1)
		_update_visual_focus()
	elif event.is_action_pressed("ui_right"):
		if inventory_slots.size() > 0:
			current_section = MenuSection.INVENTORY
			_update_visual_focus()
	elif event.is_action_pressed("ui_accept"):
		_execute_button_action(buttons[current_button_index])

func _handle_inventory_input(event: InputEvent) -> void:
	var columns = slots_grid.columns
	var max_index = inventory_slots.size() - 1
	
	if event.is_action_pressed("ui_up"):
		current_slot_index = max(0, current_slot_index - columns)
		_update_visual_focus()
	elif event.is_action_pressed("ui_down"):
		current_slot_index = min(max_index, current_slot_index + columns)
		_update_visual_focus()
	elif event.is_action_pressed("ui_left"):
		if current_slot_index % columns == 0:
			current_section = MenuSection.BUTTONS
		else:
			current_slot_index = max(0, current_slot_index - 1)
		_update_visual_focus()
	elif event.is_action_pressed("ui_right"):
		if (current_slot_index + 1) % columns != 0 and current_slot_index < max_index:
			current_slot_index = min(max_index, current_slot_index + 1)
		_update_visual_focus()
	elif event.is_action_pressed("ui_accept"):
		inventory_slot_used.emit(current_slot_index)
		print("Использован слот: ", current_slot_index)

func _execute_button_action(button: Button) -> void:
	match button.name:
		"Resume":
			_on_resume_pressed()
		"Button2":
			print("Загрузка...")
		"Button3":
			print("Настройки...")
		"QuitButton":
			get_tree().quit()

func _on_resume_pressed() -> void:
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").is_paused = false
	self.visible = false
	get_tree().paused = false

# Публичный метод для обновления инвентаря
func refresh_inventory() -> void:
	for i in inventory_slots.size():
		_update_slot_display(i)
	if current_section == MenuSection.INVENTORY:
		_update_item_info()

# Установка количества колонок в сетке
func set_inventory_columns(columns: int) -> void:
	slots_grid.columns = columns
