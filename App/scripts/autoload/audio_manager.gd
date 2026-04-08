# AudioManager.gd (автозагрузка)
extends Node

## Синглтон для управления музыкой и громкостью шин

# Ссылка на музыкальный плеер
var music_player: AudioStreamPlayer

# Пул для SFX плееров
var sfx_pool: Array[AudioStreamPlayer2D] = []
var sfx_pool_size: int = 16  # Максимальное количество одновременных SFX

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
	# Создаем музыкальный плеер
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = MUSIC_BUS
	add_child(music_player)
	
	# Создаем пул SFX плееров
	_create_sfx_pool()
	
	# Делаем персистентным при смене сцены
	process_mode = Node.PROCESS_MODE_ALWAYS

func _create_sfx_pool():
	for i in range(sfx_pool_size):
		var player = AudioStreamPlayer2D.new()
		player.name = "SFXPlayer_%d" % i
		player.bus = SFX_BUS
		add_child(player)
		sfx_pool.append(player)

func _get_free_sfx_player() -> AudioStreamPlayer2D:
	# Ищем свободный плеер
	for player in sfx_pool:
		if not player.playing:
			return player
	
	# Если все заняты, используем первый (оборвем его)
	return sfx_pool[0]

func _set_bus_volume(bus_name: String, volume_linear: float):
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(volume_linear))

# ========== УПРАВЛЕНИЕ SFX ==========

## Воспроизвести SFX звук
## @param sfx: AudioStream - звуковой ресурс
## @param volume_override: float - опциональная перезапись громкости (0.0-1.0), если -1 используется громкость шины
## @param pitch_scale: float - изменение высоты тона (1.0 = нормально)
## @param position: Vector2 - позиция для 2D звука (опционально)
func play_sfx(sfx: AudioStream, volume_override: float = -1.0, pitch_scale: float = 1.0, position: Vector2 = Vector2.ZERO):
	if not sfx:
		return
	
	var player = _get_free_sfx_player()
	if not player:
		return
	
	# Останавливаем если играет
	if player.playing:
		player.stop()
	
	# Настраиваем параметры
	player.stream = sfx
	player.pitch_scale = pitch_scale
	
	# Устанавливаем громкость
	if volume_override >= 0.0:
		player.volume_db = linear_to_db(clamp(volume_override, 0.0, 1.0))
	else:
		player.volume_db = linear_to_db(sfx_volume)
	
	# 2D позиция
	if player is AudioStreamPlayer2D:
		(player as AudioStreamPlayer2D).attenuation = 0.0
		if position != Vector2.ZERO:
			(player as AudioStreamPlayer2D).position = position
		else:
			# Ставим звук туда, где слушатель
			var listener = get_viewport().get_camera_2d()  # или ваш AudioListener2D
			if listener:
				(player as AudioStreamPlayer2D).position = listener.global_position
	
	player.play()

## Воспроизвести SFX со случайным питчем (для разнообразия)
## @param sfx: AudioStream - звуковой ресурс
## @param pitch_min: float - минимальный питч
## @param pitch_max: float - максимальный питч
## @param volume_override: float - опциональная перезапись громкости
func play_sfx_varied(sfx: AudioStream, pitch_min: float = 0.9, pitch_max: float = 1.1, volume_override: float = -1.0):
	var pitch = randf_range(pitch_min, pitch_max)
	play_sfx(sfx, volume_override, pitch)

## Остановить все SFX звуки
func stop_all_sfx():
	for player in sfx_pool:
		if player.playing:
			player.stop()

## Остановить SFX по индексу (если нужно выборочно)
func stop_sfx_at_index(index: int):
	if index >= 0 and index < sfx_pool.size():
		sfx_pool[index].stop()

## Проверить, играет ли какой-либо SFX
func is_any_sfx_playing() -> bool:
	for player in sfx_pool:
		if player.playing:
			return true
	return false

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

# ========== UI ЗВУКИ (удобные обертки) ==========

## Воспроизвести UI звук (на шину UI)
func play_ui_sound(sfx: AudioStream, volume_override: float = -1.0):
	if not sfx:
		return
	
	var player = _get_free_sfx_player()
	if player:
		player.stream = sfx
		player.bus = UI_BUS  # Временно переключаем на UI шину
		
		if volume_override >= 0.0:
			player.volume_db = linear_to_db(clamp(volume_override, 0.0, 1.0))
		else:
			player.volume_db = linear_to_db(ui_volume)
		
		player.play()
		
		# Возвращаем обратно на SFX шину после окончания
		await player.finished
		player.bus = SFX_BUS

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
