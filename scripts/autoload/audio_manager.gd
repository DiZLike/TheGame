# AudioManager.gd (автозагрузка)
extends Node

## Синглтон для управления музыкой и громкостью шин

# Ссылка на музыкальный плеер
var music_player: AudioStreamPlayer

# Названия шин
const MUSIC_BUS: String = "Music"
const SFX_BUS: String = "SFX"
const UI_BUS: String = "UI"

# Текущая музыка
var current_music: AudioStream = null

# Громкость шин (0.0 - 1.0)
var music_volume: float = 0.8:
	set(value):
		music_volume = clamp(value, 0.0, 1.0)
		_set_bus_volume(MUSIC_BUS, music_volume)

var sfx_volume: float = 0.8:
	set(value):
		sfx_volume = clamp(value, 0.0, 1.0)
		_set_bus_volume(SFX_BUS, sfx_volume)

var ui_volume: float = 0.8:
	set(value):
		ui_volume = clamp(value, 0.0, 1.0)
		_set_bus_volume(UI_BUS, ui_volume)

func _ready():
	# ДИАГНОСТИКА: выводим структуру шин
	print("=== AUDIO BUSES ===")
	for i in range(AudioServer.bus_count):
		print("%d: %s (parent: %s)" % [
			i, 
			AudioServer.get_bus_name(i),
			AudioServer.get_bus_name(AudioServer.get_bus_index(AudioServer.get_bus_name(i)))
			])
	print("==================")
	
	# Создаем музыкальный плеер
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = MUSIC_BUS
	add_child(music_player)
	
	# Устанавливаем начальную громкость шин
	#_set_bus_volume(MUSIC_BUS, music_volume)
	_set_bus_volume(SFX_BUS, sfx_volume)
	_set_bus_volume(UI_BUS, ui_volume)
	
	# Делаем персистентным при смене сцены
	process_mode = Node.PROCESS_MODE_ALWAYS

func _set_bus_volume(bus_name: String, volume_linear: float):
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(volume_linear))

# ========== УПРАВЛЕНИЕ МУЗЫКОЙ ==========

## Установить фоновую музыку
func set_music(music: AudioStream, fade_in_time: float = 0.0):
	if not music:
		return
	
	if music == current_music and music_player.playing:
		return
	
	current_music = music
	
	# Убеждаемся, что плеер использует правильную шину
	music_player.bus = MUSIC_BUS
	
	if fade_in_time > 0:
		# Плавное появление
		var original_volume = music_player.volume_db
		music_player.volume_db = linear_to_db(0.0)
		music_player.stream = music
		music_player.play()
		
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", linear_to_db(music_volume), fade_in_time)
	else:
		music_player.stream = music
		music_player.play()

## Остановить музыку с затуханием
func stop_music(fade_out_time: float = 0.0):
	if fade_out_time > 0:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", linear_to_db(0.0), fade_out_time)
		tween.tween_callback(music_player.stop)
		tween.tween_callback(func(): music_player.volume_db = linear_to_db(music_volume))
	else:
		music_player.stop()
	
	current_music = null

## Поставить на паузу
func pause_music():
	music_player.stream_paused = true

## Продолжить
func resume_music():
	music_player.stream_paused = false

## Проверить, играет ли музыка
func is_music_playing() -> bool:
	return music_player.playing

## Получить текущую музыку
func get_current_music() -> AudioStream:
	return current_music

# ========== УПРАВЛЕНИЕ ГРОМКОСТЬЮ ШИН ==========

## Установить громкость музыки
func set_music_volume(value: float):
	music_volume = value
	# Обновляем громкость текущего плеера, если играет музыка
	if music_player.playing:
		music_player.volume_db = linear_to_db(music_volume)

## Установить громкость SFX
func set_sfx_volume(value: float):
	sfx_volume = value

## Установить громкость UI
func set_ui_volume(value: float):
	ui_volume = value

## Получить громкость музыки
func get_music_volume() -> float:
	return music_volume

## Получить громкость SFX
func get_sfx_volume() -> float:
	return sfx_volume

## Получить громкость UI
func get_ui_volume() -> float:
	return ui_volume

## Установить все громкости сразу
func set_all_volumes(music: float, sfx: float, ui: float):
	set_music_volume(music)
	set_sfx_volume(sfx)
	set_ui_volume(ui)

# ========== РАБОТА С НАСТРОЙКАМИ ==========

## Получить все настройки в виде словаря
func get_settings() -> Dictionary:
	return {
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"ui_volume": ui_volume
	}

## Применить настройки из словаря
func apply_settings(settings: Dictionary):
	if settings.has("music_volume"):
		set_music_volume(settings.music_volume)
	if settings.has("sfx_volume"):
		set_sfx_volume(settings.sfx_volume)
	if settings.has("ui_volume"):
		set_ui_volume(settings.ui_volume)

## Сохранить настройки в файл
func save_to_file(filepath: String = "user://audio_settings.cfg"):
	var config = ConfigFile.new()
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "ui_volume", ui_volume)
	config.save(filepath)

## Загрузить настройки из файла
func load_from_file(filepath: String = "user://audio_settings.cfg"):
	var config = ConfigFile.new()
	if config.load(filepath) == OK:
		apply_settings({
			"music_volume": config.get_value("audio", "music_volume", 0.8),
			"sfx_volume": config.get_value("audio", "sfx_volume", 0.8),
			"ui_volume": config.get_value("audio", "ui_volume", 0.8)
		})
