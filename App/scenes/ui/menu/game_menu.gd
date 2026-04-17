# game_menu.gd (с разделением на оружие и прочее, оба в GridContainer)
extends CanvasLayer

@onready var buttons_container: VBoxContainer = $CenterContainer/MarginContainer/MainPanel/PanelMargin/MainLayout/LeftPanel/ButtonsContainer
@onready var weapon_grid: GridContainer = $CenterContainer/MarginContainer/MainPanel/PanelMargin/MainLayout/InventoryPanel/WeaponSection/WeaponGrid
@onready var items_grid: GridContainer = $CenterContainer/MarginContainer/MainPanel/PanelMargin/MainLayout/InventoryPanel/ItemsSection/ItemsGrid
@onready var item_name_label: Label = $CenterContainer/MarginContainer/MainPanel/PanelMargin/MainLayout/ItemInfoPanel/ItemInfoPanelBg/ItemInfoMargin/ItemInfoVBox/ItemNameLabel
@onready var item_description_label: RichTextLabel = $CenterContainer/MarginContainer/MainPanel/PanelMargin/MainLayout/ItemInfoPanel/ItemInfoPanelBg/ItemInfoMargin/ItemInfoVBox/ItemDescription

var settings_menu_scene = preload("res://scenes/ui/menu/settings_menu.tscn")

enum MenuSection { BUTTONS, WEAPON, ITEMS }

var buttons: Array[Button] = []
var weapon_slots: Array[Control] = []  # Слоты оружия (только один, но в массиве для единообразия)
var item_slots: Array[Control] = []    # Слоты прочих предметов (индексы 1-9)
var current_section: MenuSection = MenuSection.BUTTONS
var current_button_index: int = 0
var current_weapon_index: int = 0  # Всегда 0
var current_item_index: int = 0    # Индекс в item_slots (0-8)

const WEAPON_SLOT_INDEX: int = 0  # Оружие всегда в слоте 0


func _ready() -> void:
	# Собираем кнопки
	for child in buttons_container.get_children():
		if child is Button:
			buttons.append(child)
			child.focus_mode = Control.FOCUS_NONE
			# Подключаем наведение мыши
			child.mouse_entered.connect(_on_button_hovered.bind(buttons.size() - 1))
	
	# Настраиваем сетку оружия (1 колонка)
	weapon_grid.columns = 1
	
	# Создаём слоты
	_setup_weapon_slots()
	_setup_item_slots()
	
	# Подключаем сигналы инвентаря
	if InventoryManager.has_signal("inventory_updated"):
		InventoryManager.inventory_updated.connect(_on_inventory_updated)
	
	# Визуальное выделение первого элемента
	_update_visual_focus()
	
	# Обновляем отображение инвентаря
	refresh_inventory()


func _create_slot() -> Control:
	var slot = Panel.new()
	slot.custom_minimum_size = Vector2(64, 64)
	slot.size = Vector2(64, 64)
	
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
	
	var icon = TextureRect.new()
	icon.name = "Icon"
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.size = Vector2(48, 48)
	icon.position = Vector2(8, 8)
	slot.add_child(icon)
	
	var count_label = Label.new()
	count_label.name = "Count"
	count_label.position = Vector2(4, 44)
	count_label.size = Vector2(56, 16)
	count_label.add_theme_font_size_override("font_size", 12)
	count_label.add_theme_color_override("font_color", Color.WHITE)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	slot.add_child(count_label)
	
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


func _setup_weapon_slots() -> void:
	# Очищаем существующие слоты
	for child in weapon_grid.get_children():
		child.queue_free()
	weapon_slots.clear()
	
	# Создаём один слот для оружия
	var slot = _create_slot()
	weapon_grid.add_child(slot)
	weapon_slots.append(slot)
	
	# Подключаем наведение мыши
	slot.mouse_entered.connect(_on_weapon_slot_hovered.bind(0))


func _setup_item_slots() -> void:
	# Очищаем существующие слоты
	for child in items_grid.get_children():
		child.queue_free()
	item_slots.clear()
	
	# Создаём 9 слотов для прочих предметов (индексы 1-9 в инвентаре)
	for i in range(1, 10):  # InventoryManager.inventory_size если доступен
		var slot = _create_slot()
		items_grid.add_child(slot)
		item_slots.append(slot)
		
		# Подключаем наведение мыши
		var slot_index = item_slots.size() - 1
		slot.mouse_entered.connect(_on_item_slot_hovered.bind(slot_index))


func _update_slot_display(slot: Control, inventory_index: int, show_count: bool = true) -> void:
	var icon = slot.get_node("Icon") as TextureRect
	var count_label = slot.get_node("Count") as Label
	
	var item = InventoryManager.get_item(inventory_index)
	var quantity = InventoryManager.get_quantity(inventory_index)
	
	if item and quantity > 0:
		icon.texture = item.icon if item.icon else null
		if show_count and quantity > 1:
			count_label.text = str(quantity)
			count_label.visible = true
		else:
			count_label.visible = false
	else:
		icon.texture = null
		count_label.text = ""
		count_label.visible = false


func _update_highlight() -> void:
	# Подсветка кнопок
	for i in buttons.size():
		var button = buttons[i]
		if i == current_button_index and current_section == MenuSection.BUTTONS:
			button.add_theme_color_override("font_color", Color(1, 0.8, 0))
		else:
			button.add_theme_color_override("font_color", Color.WHITE)
	
	# Подсветка слотов оружия
	for i in weapon_slots.size():
		var highlight = weapon_slots[i].get_node("Highlight")
		if i == current_weapon_index and current_section == MenuSection.WEAPON:
			highlight.show()
		else:
			highlight.hide()
	
	# Подсветка слотов предметов
	for i in item_slots.size():
		var highlight = item_slots[i].get_node("Highlight")
		if i == current_item_index and current_section == MenuSection.ITEMS:
			highlight.show()
		else:
			highlight.hide()


func _update_visual_focus() -> void:
	_update_highlight()
	_update_item_info()


func _update_item_info() -> void:
	match current_section:
		MenuSection.WEAPON:
			var item = InventoryManager.get_item(WEAPON_SLOT_INDEX)
			var quantity = InventoryManager.get_quantity(WEAPON_SLOT_INDEX)
			if item and quantity > 0:
				item_name_label.text = item.name
				item_description_label.text = item.description
			else:
				item_name_label.text = "Слот оружия"
				item_description_label.text = "Здесь можно экипировать оружие"
		
		MenuSection.ITEMS:
			var inventory_index = current_item_index + 1
			var item = InventoryManager.get_item(inventory_index)
			var quantity = InventoryManager.get_quantity(inventory_index)
			if item and quantity > 0:
				item_name_label.text = "%s x%s" % [item.name, quantity] if quantity > 1 else item.name
				item_description_label.text = item.description
			else:
				item_name_label.text = "Пустой слот"
				item_description_label.text = "Нет предмета"
		
		_:
			item_name_label.text = ""
			item_description_label.text = ""

func _on_button_hovered(index: int) -> void:
	current_section = MenuSection.BUTTONS
	current_button_index = index
	_update_visual_focus()


func _on_weapon_slot_hovered(index: int) -> void:
	current_section = MenuSection.WEAPON
	current_weapon_index = index
	_update_visual_focus()


func _on_item_slot_hovered(index: int) -> void:
	current_section = MenuSection.ITEMS
	current_item_index = index
	_update_visual_focus()


func _on_inventory_updated(slot_index: int) -> void:
	if slot_index == WEAPON_SLOT_INDEX:
		_update_slot_display(weapon_slots[0], WEAPON_SLOT_INDEX, false)
		if current_section == MenuSection.WEAPON:
			_update_item_info()
	elif slot_index > 0 and slot_index <= item_slots.size():
		var item_slots_index = slot_index - 1
		_update_slot_display(item_slots[item_slots_index], slot_index, true)
		if current_section == MenuSection.ITEMS and current_item_index == item_slots_index:
			_update_item_info()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	
	match current_section:
		MenuSection.BUTTONS:
			_handle_buttons_input(event)
		MenuSection.WEAPON:
			_handle_weapon_input(event)
		MenuSection.ITEMS:
			_handle_items_input(event)
	
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
		current_section = MenuSection.WEAPON
		current_weapon_index = 0
		_update_visual_focus()
	elif event.is_action_pressed("jump"):
		_execute_button_action(buttons[current_button_index])
	elif event.is_action_pressed("shoot"):
		_on_resume_pressed()


func _handle_weapon_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		current_section = MenuSection.BUTTONS
		_update_visual_focus()
	elif event.is_action_pressed("ui_right"):
		if item_slots.size() > 0:
			current_section = MenuSection.ITEMS
			current_item_index = 0
			_update_visual_focus()
	elif event.is_action_pressed("ui_down"):
		if item_slots.size() > 0:
			current_section = MenuSection.ITEMS
			current_item_index = 0
			_update_visual_focus()
	elif event.is_action_pressed("jump"):
		var result = InventoryManager.use_item(WEAPON_SLOT_INDEX)
		print(result.message)
		_update_slot_display(weapon_slots[0], WEAPON_SLOT_INDEX, false)
		_update_item_info()
	elif event.is_action_pressed("shoot"):
		current_section = MenuSection.BUTTONS
		_update_visual_focus()


func _handle_items_input(event: InputEvent) -> void:
	var columns = items_grid.columns
	var max_index = item_slots.size() - 1
	
	if event.is_action_pressed("move_up"):
		if current_item_index >= columns:
			current_item_index -= columns
		else:
			current_section = MenuSection.WEAPON
			current_weapon_index = 0
		_update_visual_focus()
		
	elif event.is_action_pressed("move_down"):
		if current_item_index + columns <= max_index:
			current_item_index += columns
		_update_visual_focus()
		
	elif event.is_action_pressed("move_left"):
		if current_item_index % columns == 0:
			current_section = MenuSection.WEAPON
			current_weapon_index = 0
		else:
			current_item_index = max(0, current_item_index - 1)
		_update_visual_focus()
		
	elif event.is_action_pressed("move_right"):
		if (current_item_index + 1) % columns != 0 and current_item_index < max_index:
			current_item_index += 1
		_update_visual_focus()
		
	elif event.is_action_pressed("jump"):
		var inventory_index = current_item_index + 1
		var result = InventoryManager.use_item(inventory_index)
		print(result.message)
		_update_slot_display(item_slots[current_item_index], inventory_index, true)
		_update_item_info()
		
	elif event.is_action_pressed("shoot"):
		current_section = MenuSection.BUTTONS
		_update_visual_focus()


func _execute_button_action(button: Button) -> void:
	match button.name:
		"Resume":
			_on_resume_pressed()
		"Button2":
			print("Загрузка...")
		"SettingsButton":
			_on_settings_pressed()
		"QuitButton":
			get_tree().quit()


func _on_resume_pressed() -> void:
	self.visible = false
	Input.action_release("jump")
	Input.action_release("shoot")
	await get_tree().process_frame
	GameManager.is_paused = false
	get_tree().paused = false

func _on_settings_pressed() -> void:
	hide() # Прячем текущее меню
	
	var settings_menu = settings_menu_scene.instantiate()
	get_tree().root.add_child(settings_menu)
	
	settings_menu.settings_closed.connect(_on_settings_closed)

func _on_settings_closed() -> void:
	show() # Показываем меню обратно

func refresh_inventory() -> void:
	_update_slot_display(weapon_slots[0], WEAPON_SLOT_INDEX, false)
	for i in item_slots.size():
		_update_slot_display(item_slots[i], i + 1, true)
	_update_item_info()
