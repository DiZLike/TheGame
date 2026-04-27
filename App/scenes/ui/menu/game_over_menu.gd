# game_over_menu.gd - Contra / NES Style
extends CanvasLayer

# UI элементы
@onready var game_over_panel: Panel = $MarginContainer/GameOverPanel
@onready var color_rect: TextureRect = $ColorRect
@onready var background_overlay: ColorRect = $BackgroundOverlay

# Текст
@onready var game_over_title: Label = $MarginContainer/GameOverPanel/PanelMargin/MainVBox/GameOverTitle

# Очки
@onready var score_value: Label = $MarginContainer/GameOverPanel/PanelMargin/MainVBox/ScoreContainer/ScoreBorderBox/ScoreMargin/ScoreGrid/ScoreRow/ScoreValue
@onready var best_score_value: Label = $MarginContainer/GameOverPanel/PanelMargin/MainVBox/ScoreContainer/ScoreBorderBox/ScoreMargin/ScoreGrid/BestRow/BestScoreValue
@onready var new_record_blink: Label = $MarginContainer/GameOverPanel/PanelMargin/MainVBox/ScoreContainer/ScoreBorderBox/ScoreMargin/ScoreGrid/NewRecordBlink

# Кнопки
@onready var continue_button: Button = $MarginContainer/GameOverPanel/PanelMargin/MainVBox/ButtonsContainer/ContinueButton
@onready var load_button: Button = $MarginContainer/GameOverPanel/PanelMargin/MainVBox/ButtonsContainer/LoadButton
@onready var quit_button: Button = $MarginContainer/GameOverPanel/PanelMargin/MainVBox/ButtonsContainer/QuitButton

@onready var level: BaseLevel = $"../.."

var _closing_action: Callable

# Навигация
var buttons: Array[Button] = []
var current_button_index: int = 0

# Данные
var current_score: int = 0
var best_score: int = 0
var is_new_record: bool = false

# Таймеры для анимаций
var flash_timer: float = 0.0
var blink_timer: float = 0.0
var show_title: bool = true
var show_record: bool = true

# Сигналы
signal continue_requested
signal load_requested
signal quit_requested


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Собираем кнопки
	buttons = [continue_button, load_button, quit_button]
	
	# Отключаем встроенный фокус Godot
	_setup_focus_modes()
	
	# Загружаем очки
	_load_scores()
	
	# Подключаем сигналы кнопок
	for i in buttons.size():
		buttons[i].pressed.connect(_on_button_pressed.bind(i))
		buttons[i].mouse_entered.connect(_on_button_hovered.bind(i))
	
	_update_visual_focus()
	
	# Заголовок всегда видим, яркостью управляет _process
	game_over_title.visible = true


func _setup_focus_modes() -> void:
	for button in buttons:
		button.focus_mode = Control.FOCUS_NONE


func _load_scores() -> void:
	# Текущие очки
	current_score = GameManager.get_score()
	
	# Рекорд
	best_score = ScoreManager.record
	
	_update_score_display()


func _update_score_display() -> void:
	score_value.text = "%08d" % current_score
	best_score_value.text = "%08d" % best_score
	
	new_record_blink.visible = is_new_record


func _update_visual_focus() -> void:
	for i in buttons.size():
		var button = buttons[i]
		
		if i == current_button_index:
			# Активная кнопка: жёлтая рамка и золотой текст
			button.add_theme_color_override("font_color", Color(1, 0.84, 0, 1))
			var focus_style = button.get_theme_stylebox("focus")
			if focus_style:
				(focus_style as StyleBoxFlat).border_color = Color(1, 0.84, 0, 1)
				(focus_style as StyleBoxFlat).border_width_left = 3
				(focus_style as StyleBoxFlat).border_width_top = 3
				(focus_style as StyleBoxFlat).border_width_right = 3
				(focus_style as StyleBoxFlat).border_width_bottom = 3
		else:
			# Неактивная: тусклые границы
			button.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
			var normal_style = button.get_theme_stylebox("normal")
			if normal_style:
				(normal_style as StyleBoxFlat).border_color = Color(1, 1, 1, 0.3)
				(normal_style as StyleBoxFlat).border_width_left = 3
				(normal_style as StyleBoxFlat).border_width_top = 3
				(normal_style as StyleBoxFlat).border_width_right = 3
				(normal_style as StyleBoxFlat).border_width_bottom = 3


func _on_button_hovered(index: int) -> void:
	current_button_index = index
	_update_visual_focus()


func _on_button_pressed(index: int) -> void:
	match index:
		0: # Continue
			_closing_action = func():
				level.level_destroy = true
				GameManager.load_cont_player_dala()
				get_tree().change_scene_to_file(GameManager.get_current_level())
			_close_menu()
		1: # Load
			_closing_action = func():
				load_requested.emit()
			_close_menu()
		2: # Quit
			_closing_action = func():
				quit_requested.emit()
				get_tree().quit()
			_close_menu()
	
	GameManager.is_paused = false
	get_tree().paused = false

func _close_menu() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(color_rect, "modulate:a", 0.0, 0.3)
	tween.tween_property(game_over_panel, "modulate:a", 0.0, 0.2)
	tween.tween_property(game_over_panel, "scale", Vector2(0.8, 0.8), 0.2)
	
	await get_tree().create_timer(0.3).timeout
	
	if _closing_action:
		_closing_action.call()
	
	queue_free()


func _process(delta: float) -> void:
	_load_scores()
	# Резкое мигание GAME OVER (яркий/затемнённый)
	flash_timer += delta
	if flash_timer >= 0.4:
		flash_timer = 0.0
		show_title = not show_title
		if show_title:
			game_over_title.modulate = Color(1, 1, 1, 1.0)  # полная яркость
		else:
			game_over_title.modulate = Color(1, 1, 1, 0.1)  # затемнённый, но видимый
	
	# Мигание NEW RECORD
	if is_new_record:
		blink_timer += delta
		if blink_timer >= 0.15:
			blink_timer = 0.0
			show_record = not show_record
			new_record_blink.visible = show_record


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	
	if event.is_action_pressed("move_up"):
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
		
	elif event.is_action_pressed("shoot"):
		buttons[current_button_index].emit_signal("pressed")
		get_viewport().set_input_as_handled()
