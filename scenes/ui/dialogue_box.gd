# ui/DialogueBox.gd
extends CanvasLayer

# Сигналы
signal dialogue_started
signal dialogue_finished
signal line_changed(line_id)
signal method_executed(method_name, success)

# Ссылки на узлы
@onready var panel = $Panel
@onready var text_label = $Panel/TextLabel
@onready var name_label = $Panel/NameLabel
@onready var portrait = $Panel/Portrait
@onready var portrait_container = $Panel/Portrait
@onready var continue_label = $Panel/ContinueLabel
@onready var audio_player = $Panel/AudioStreamPlayer2D
@onready var glitch_node = $Panel/Portrait/Glitch

# Настройки текста
@export var text_speed: float = 25.0
@export var auto_advance_time: float = 0.0
@export var typing_sound: AudioStream
@export var typing_pitch_variation: float = 0.1
@export var skip_typing_on_empty_chars: bool = true
@export var sound_frequency: int = 1

# Настройки анимаций
@export var animation_duration: float = 0.3
@export var cursor_blink_speed: float = 0.5
@export var glitch_transition_duration: float = 0.2

# Настройки портретов
@export var default_portrait: Texture2D
@export var hide_portrait_when_empty: bool = true
@export var portrait_fade_duration: float = 0.25
@export var portrait_scale_animation: bool = true
@export var portrait_scale_on_show: float = 0.8

# Внутренние переменные
var current_filename: String = ""
var current_dialogue: Array = []
var current_index: int = 0
var is_typing: bool = false
var is_hiding: bool = false
var auto_advance_timer: Timer = null
var current_line_text: String = ""
var current_char_index: int = 0
var typing_timer: Timer = null
var is_showing: bool = false
var blink_tween: Tween = null
var current_scene: Node = null
var current_portrait_texture: Texture2D = null
var is_portrait_animating: bool = false

# UI элементы для анимаций
var original_panel_scale: Vector2
var original_panel_modulate: Color
var original_portrait_scale: Vector2

func _ready():
	# Инициализируем оригинальные значения
	original_panel_scale = panel.scale
	original_panel_modulate = panel.modulate
	
	if portrait_container:
		original_portrait_scale = portrait_container.scale
	
	# Скрываем окно при старте
	panel.visible = false
	panel.modulate = Color.TRANSPARENT
	panel.scale = Vector2.ZERO
	continue_label.visible = false
	continue_label.modulate = Color.TRANSPARENT
	
	# Скрываем портрет
	_hide_portrait_instant()
	
	# Скрываем glitch-эффект
	if glitch_node:
		glitch_node.visible = false
		if glitch_node.has_method("set_enabled"):
			glitch_node.set_enabled(false)
	
	# Создаем таймер для авто-продолжения
	if auto_advance_time > 0:
		auto_advance_timer = Timer.new()
		auto_advance_timer.wait_time = auto_advance_time
		auto_advance_timer.one_shot = true
		add_child(auto_advance_timer)
		auto_advance_timer.timeout.connect(_on_auto_advance_timeout)
	
	process_mode = Node.PROCESS_MODE_ALWAYS
	current_scene = get_tree().current_scene

# ============ ПОРТРЕТЫ ============

func _hide_portrait_instant():
	if not portrait_container:
		return
	portrait_container.visible = false
	portrait_container.modulate = Color.TRANSPARENT
	if portrait:
		portrait.texture = null
	portrait_container.scale = Vector2.ONE
	current_portrait_texture = null
	is_portrait_animating = false

func _stop_portrait_animations():
	if portrait_container.get_meta("tween", null):
		var old_tween = portrait_container.get_meta("tween")
		if old_tween and old_tween.is_valid():
			old_tween.kill()
			portrait_container.remove_meta("tween")

func _show_portrait_with_animation(texture: Texture2D):
	if not portrait_container or not portrait:
		return
	
	# Если та же текстура и портрет уже виден - не анимируем
	if texture == current_portrait_texture and portrait_container.visible and not is_portrait_animating:
		return
	
	# Останавливаем текущие анимации
	_stop_portrait_animations()
	
	# Если портрет нужно скрыть
	if not texture or (hide_portrait_when_empty and texture == default_portrait and default_portrait == null):
		if portrait_container.visible:
			_hide_portrait_with_animation()
		return
	
	# Сохраняем новую текстуру
	current_portrait_texture = texture
	is_portrait_animating = true
	
	# Устанавливаем текстуру
	portrait.texture = texture
	
	# Если портрет уже виден - делаем кросс-фейд
	if portrait_container.visible:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_trans(Tween.TRANS_SINE)
		
		# Старый портрет исчезает
		var old_modulate = portrait.modulate
		portrait.modulate = Color.WHITE
		
		# Новый портрет появляется с fade
		tween.tween_property(portrait, "modulate", Color.WHITE, portrait_fade_duration)
		
		# Небольшая анимация масштаба при смене
		if portrait_scale_animation:
			portrait_container.scale = Vector2(portrait_scale_on_show, portrait_scale_on_show)
			tween.tween_property(portrait_container, "scale", Vector2.ONE, portrait_fade_duration)
		
		portrait_container.set_meta("tween", tween)
		await tween.finished
	else:
		# Показываем с анимацией появления
		portrait_container.visible = true
		portrait_container.modulate = Color.TRANSPARENT
		portrait.modulate = Color.WHITE
		
		if portrait_scale_animation:
			portrait_container.scale = Vector2(portrait_scale_on_show, portrait_scale_on_show)
		else:
			portrait_container.scale = Vector2.ONE
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		
		# Анимация появления
		tween.tween_property(portrait_container, "modulate", Color.WHITE, portrait_fade_duration)
		
		if portrait_scale_animation:
			tween.tween_property(portrait_container, "scale", Vector2.ONE, portrait_fade_duration)
		
		portrait_container.set_meta("tween", tween)
		await tween.finished
	
	is_portrait_animating = false

func _hide_portrait_with_animation():
	if not portrait_container or not portrait_container.visible:
		return
	
	_stop_portrait_animations()
	is_portrait_animating = true
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_BACK)
	
	# Анимация исчезновения
	tween.tween_property(portrait_container, "modulate", Color.TRANSPARENT, portrait_fade_duration / 1.5)
	
	if portrait_scale_animation:
		tween.tween_property(portrait_container, "scale", Vector2(portrait_scale_on_show, portrait_scale_on_show), portrait_fade_duration / 1.5)
	
	portrait_container.set_meta("tween", tween)
	await tween.finished
	
	portrait_container.visible = false
	portrait.texture = null
	current_portrait_texture = null
	is_portrait_animating = false

# ============ GLITCH ЭФФЕКТ ============

func _set_glitch_effect(enabled: bool):
	if not glitch_node:
		return
	
	if glitch_node.has_method("set_enabled"):
		glitch_node.set_enabled(enabled)
		return
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	
	if enabled:
		glitch_node.visible = true
		if glitch_node.has_method("show_effect"):
			glitch_node.show_effect()
		else:
			glitch_node.modulate = Color.TRANSPARENT
			tween.tween_property(glitch_node, "modulate", Color.WHITE, glitch_transition_duration)
	else:
		if glitch_node.has_method("hide_effect"):
			glitch_node.hide_effect()
			await get_tree().create_timer(glitch_transition_duration).timeout
			glitch_node.visible = false
		else:
			tween.tween_property(glitch_node, "modulate", Color.TRANSPARENT, glitch_transition_duration)
			await tween.finished
			glitch_node.visible = false

# ============ МЕТОДЫ ДИАЛОГА ============

func _execute_methods(methods: Array, is_start: bool = true):
	if methods.is_empty():
		return
	
	print("[DialogueBox] Выполнение ", methods.size(), " методов")
	
	for method_name in methods:
		if method_name is not String or method_name.is_empty():
			continue
		
		var target_node = current_scene
		
		if not target_node:
			push_error("[DialogueBox] Нет целевой сцены для метода: ", method_name)
			method_executed.emit(method_name, false)
			continue
		
		if not target_node.has_method(method_name):
			target_node = _find_global_method(method_name)
			if not target_node:
				push_error("[DialogueBox] Метод не найден: ", method_name)
				method_executed.emit(method_name, false)
				continue
		
		target_node.call(method_name)
		method_executed.emit(method_name, true)

func _find_global_method(method_name: String) -> Node:
	for autoload_name in ProjectSettings.get_property_list():
		if autoload_name.name.begins_with("autoload/"):
			var node_name = autoload_name.name.replace("autoload/", "")
			var autoload_node = get_node_or_null("/root/" + node_name)
			if autoload_node and autoload_node.has_method(method_name):
				return autoload_node
	
	for child in get_tree().root.get_children():
		if child.has_method(method_name):
			return child
	
	return null

func _show_panel_animation():
	is_showing = true
	panel.visible = true
	
	if blink_tween and blink_tween.is_valid():
		blink_tween.kill()
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	
	tween.tween_property(panel, "scale", original_panel_scale, animation_duration)
	tween.tween_property(panel, "modulate", original_panel_modulate, animation_duration)
	
	await tween.finished
	is_showing = false

func _hide_panel_animation():
	if is_hiding:
		return
	
	is_hiding = true
	
	if blink_tween and blink_tween.is_valid():
		blink_tween.kill()
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_BACK)
	
	tween.tween_property(panel, "scale", Vector2.ZERO, animation_duration)
	tween.tween_property(panel, "modulate", Color.TRANSPARENT, animation_duration)
	
	await tween.finished
	panel.visible = false
	is_hiding = false

func _stop_continue_label_animation():
	if blink_tween and blink_tween.is_valid():
		blink_tween.kill()
		await get_tree().process_frame
	
	if continue_label and is_instance_valid(continue_label):
		continue_label.modulate = Color(1, 1, 1, 1)

func _animate_continue_label():
	if not continue_label or not continue_label.visible:
		return
	
	await _stop_continue_label_animation()
	
	if not continue_label or not continue_label.visible or not is_instance_valid(continue_label):
		return
	
	blink_tween = create_tween()
	blink_tween.set_loops()
	blink_tween.set_ease(Tween.EASE_IN_OUT)
	blink_tween.set_trans(Tween.TRANS_SINE)
	
	blink_tween.tween_property(continue_label, "modulate:a", 0.3, cursor_blink_speed)
	blink_tween.tween_property(continue_label, "modulate:a", 1.0, cursor_blink_speed)

func _load_portrait(portrait_path: String) -> Texture2D:
	if portrait_path.is_empty():
		return default_portrait
	
	var texture = load(portrait_path)
	if texture and texture is Texture2D:
		return texture
	else:
		if not portrait_path.is_empty():
			push_warning("[DialogueBox] Не удалось загрузить портрет: ", portrait_path)
		return default_portrait

func start_dialogue(filename: String, start_id: String = ""):
	is_hiding = false
	
	current_filename = filename
	current_dialogue = DialogueLoader.load_dialogue(filename)
	
	if current_dialogue.is_empty():
		push_error("[DialogueBox] Не удалось загрузить диалог: ", filename)
		return
	
	if start_id.is_empty():
		current_index = 0
	else:
		var found = false
		for i in range(current_dialogue.size()):
			if current_dialogue[i].id == start_id:
				current_index = i
				found = true
				break
		if not found:
			push_warning("[DialogueBox] Не найдена реплика с ID: ", start_id)
			current_index = 0
	
	await _show_panel_animation()
	dialogue_started.emit()
	_show_current_line()

func _show_current_line():
	if current_index >= current_dialogue.size():
		_end_dialogue()
		return
	
	var line = current_dialogue[current_index]
	
	_set_glitch_effect(line.glitch_enabled)
	
	var portrait_texture = _load_portrait(line.portrait_path)
	_show_portrait_with_animation(portrait_texture)
	
	_execute_methods(line.on_start_methods, true)
	line_changed.emit(line.id)
	
	# Анимация имени
	var name_tween = create_tween()
	name_tween.set_ease(Tween.EASE_OUT)
	name_tween.set_trans(Tween.TRANS_QUINT)
	name_label.modulate = Color.TRANSPARENT
	name_label.text = line.speaker
	name_tween.tween_property(name_label, "modulate", Color.WHITE, 0.2)
	
	await _stop_continue_label_animation()
	continue_label.visible = false
	continue_label.modulate = Color.TRANSPARENT
	
	current_line_text = line.text
	current_char_index = 0
	text_label.text = ""
	is_typing = true
	
	_start_typing_with_timer()

func _start_typing_with_timer():
	var time_per_char = 1.0 / text_speed
	
	if typing_timer and is_instance_valid(typing_timer):
		typing_timer.queue_free()
	
	typing_timer = Timer.new()
	typing_timer.one_shot = false
	typing_timer.wait_time = time_per_char
	add_child(typing_timer)
	typing_timer.timeout.connect(_on_typing_timer_timeout)
	typing_timer.start()

func _on_typing_timer_timeout():
	if not is_typing:
		return
	
	if current_char_index < current_line_text.length():
		var next_char = current_line_text[current_char_index]
		text_label.text += next_char
		current_char_index += 1
		
		var should_play = (current_char_index - 1) % sound_frequency == 0
		if should_play:
			_play_sound_for_char(next_char)
	else:
		_typing_finished()

func _play_sound_for_char(char: String):
	var should_play_sound = true
	
	if skip_typing_on_empty_chars:
		if char in [" ", "\n", "\t", ".", ",", "!", "?", ";", ":", "-", "—", "(", ")", "\"", "'"]:
			should_play_sound = false
	
	if should_play_sound:
		_play_typing_sound()

func _play_typing_sound():
	if not typing_sound or not audio_player:
		return
	
	var temp_player = AudioStreamPlayer2D.new()
	temp_player.stream = typing_sound
	temp_player.pitch_scale = 1.0 + randf_range(-typing_pitch_variation, typing_pitch_variation)
	temp_player.volume_db = audio_player.volume_db
	add_child(temp_player)
	temp_player.play()
	
	await temp_player.finished
	if temp_player and is_instance_valid(temp_player):
		temp_player.queue_free()

func _typing_finished():
	is_typing = false
	
	if typing_timer and is_instance_valid(typing_timer):
		typing_timer.queue_free()
		typing_timer = null
	
	if continue_label and is_instance_valid(continue_label):
		continue_label.visible = true
		continue_label.modulate = Color(1, 1, 1, 1)
		_animate_continue_label()
	
	if auto_advance_time > 0 and auto_advance_timer:
		auto_advance_timer.start()

func _skip_typing():
	if is_typing:
		if typing_timer and is_instance_valid(typing_timer):
			typing_timer.queue_free()
			typing_timer = null
		
		text_label.text = current_line_text
		current_char_index = current_line_text.length()
		is_typing = false
		
		if continue_label and is_instance_valid(continue_label):
			continue_label.visible = true
			continue_label.modulate = Color(1, 1, 1, 1)
			_animate_continue_label()
		
		if auto_advance_timer and not auto_advance_timer.is_stopped():
			auto_advance_timer.stop()

func _advance_dialogue():
	if is_hiding or not panel.visible:
		return
	
	if auto_advance_timer and not auto_advance_timer.is_stopped():
		auto_advance_timer.stop()
	
	if current_index >= current_dialogue.size():
		_end_dialogue()
		return
	
	var current_line = current_dialogue[current_index]
	_execute_methods(current_line.on_end_methods, false)
	
	if current_line.choices and current_line.choices.size() > 0:
		_show_choices(current_line.choices)
		return
	
	var next_index = -1
	
	if not current_line.next_id.is_empty():
		for i in range(current_dialogue.size()):
			if current_dialogue[i].id == current_line.next_id:
				next_index = i
				break
	
	if next_index == -1:
		next_index = current_index + 1
	
	if next_index < current_dialogue.size():
		current_index = next_index
		_show_current_line()
	else:
		_end_dialogue()

func _show_choices(choices: Array):
	_stop_continue_label_animation()
	print("Выберите вариант:")
	for i in range(choices.size()):
		print(i + 1, ". ", choices[i].get("text", "???"))

func jump_to_dialogue_by_id(dialogue_id: String):
	for i in range(current_dialogue.size()):
		if current_dialogue[i].id == dialogue_id:
			current_index = i
			_show_current_line()
			return
	
	push_error("[DialogueBox] Не найдена реплика с ID: ", dialogue_id)

func _end_dialogue():
	if is_hiding or not panel.visible:
		return
	
	await _stop_continue_label_animation()
	
	if continue_label and is_instance_valid(continue_label):
		continue_label.visible = false
	
	_set_glitch_effect(false)
	
	# Анимированное скрытие портрета
	if portrait_container and portrait_container.visible:
		await _hide_portrait_with_animation()
	else:
		_hide_portrait_instant()
	
	if is_typing:
		if typing_timer and is_instance_valid(typing_timer):
			typing_timer.queue_free()
			typing_timer = null
		is_typing = false
	
	if auto_advance_timer and not auto_advance_timer.is_stopped():
		auto_advance_timer.stop()
	
	await _hide_panel_animation()
	
	dialogue_finished.emit()
	current_dialogue = []
	current_index = 0

func _input(event):
	if not panel.visible or is_showing or is_hiding:
		return
	
	if event.is_action_pressed("jump"):
		if is_typing:
			_skip_typing()
		else:
			_advance_dialogue()

func _on_auto_advance_timeout():
	if not is_typing and panel.visible and not is_hiding:
		_advance_dialogue()
