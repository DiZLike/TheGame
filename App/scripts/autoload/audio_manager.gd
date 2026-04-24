# AudioManager.gd - автозагрузка (синглтон)
extends Node

## Синглтон для управления звуком с независимыми каналами

# === НАСТРОЙКИ ПО УМОЛЧАНИЮ ===
const DEFAULT_MASTER_VOLUME: float = 0.8
const DEFAULT_SFX_VOLUME: float = 0.8
const DEFAULT_MUSIC_VOLUME: float = 0.8
const SFX_POOL_SIZE: int = 16

# === ШИНЫ ===
const MASTER_BUS: String = "Master"
const MUSIC_BUS: String = "Music"
const SFX_BUS: String = "SFX"
const UI_BUS: String = "UI"

# === ПЛЕЕРЫ ===
var music_player: AudioStreamPlayer
var sfx_pool: Array[AudioStreamPlayer2D] = []
var ui_player: AudioStreamPlayer  # Отдельный плеер для UI звуков

var current_music_volume: float = 0

# === ТЕКУЩИЕ ЗНАЧЕНИЯ ГРОМКОСТИ (0.0 - 1.0) ===
var master_volume: float = DEFAULT_MASTER_VOLUME:
	set(value):
		master_volume = clamp(value, 0.0, 1.0)
		_update_master_volume()

var sfx_volume: float = DEFAULT_SFX_VOLUME:
	set(value):
		sfx_volume = clamp(value, 0.0, 1.0)
		_update_sfx_volume()

var music_volume: float = DEFAULT_MUSIC_VOLUME:
	set(value):
		music_volume = clamp(value, 0.0, 1.0)
		_update_music_volume()

# === СОСТОЯНИЕ ===
var current_music: AudioStream = null
var is_music_fading: bool = false

# === СИГНАЛЫ ===
signal master_volume_changed(new_volume: float)
signal sfx_volume_changed(new_volume: float)
signal music_volume_changed(new_volume: float)


func _ready() -> void:
	# Настройка процесса
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Создание плееров
	_setup_players()
	
	# Загрузка сохраненных настроек
	load_from_file()
	
	print("AudioManager инициализирован")
	print("  Master: {master_volume * 100}%")
	print("  SFX: {sfx_volume * 100}%")
	print("  Music: {music_volume * 100}%")


func _setup_players() -> void:
	# Музыкальный плеер
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = MUSIC_BUS
	music_player.finished.connect(_on_music_finished)
	add_child(music_player)
	
	# UI плеер (отдельный, чтобы не конфликтовал с SFX)
	ui_player = AudioStreamPlayer.new()
	ui_player.name = "UIPlayer"
	ui_player.bus = UI_BUS
	add_child(ui_player)
	
	# Создание пула SFX плееров
	for i in range(SFX_POOL_SIZE):
		var player = AudioStreamPlayer2D.new()
		player.name = "SFXPlayer_%d" % i
		player.bus = SFX_BUS
		add_child(player)
		sfx_pool.append(player)

func _on_music_finished() -> void:
	if music_player.stream and current_music:
		music_player.play()

# === ВНУТРЕННИЕ МЕТОДЫ ОБНОВЛЕНИЯ ГРОМКОСТИ ===

func _update_master_volume() -> void:
	# Обновляем громкость мастер-шины
	var master_bus_index = AudioServer.get_bus_index(MASTER_BUS)
	if master_bus_index >= 0:
		AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(master_volume))
	
	# Сигнал об изменении
	master_volume_changed.emit(master_volume)


func _update_sfx_volume() -> void:
	# Обновляем громкость SFX шины
	var sfx_bus_index = AudioServer.get_bus_index(SFX_BUS)
	if sfx_bus_index >= 0:
		AudioServer.set_bus_volume_db(sfx_bus_index, linear_to_db(sfx_volume * master_volume))
	
	# Сигнал об изменении
	sfx_volume_changed.emit(sfx_volume)


func _update_music_volume() -> void:
	# Обновляем громкость Music шины
	var music_bus_index = AudioServer.get_bus_index(MUSIC_BUS)
	if music_bus_index >= 0:
		AudioServer.set_bus_volume_db(music_bus_index, linear_to_db(music_volume * master_volume))
	
	# Если музыка играет, обновляем громкость плеера
	if music_player.playing and not is_music_fading:
		music_player.volume_db = linear_to_db(music_volume * master_volume)
	
	# Сигнал об изменении
	music_volume_changed.emit(music_volume)


# === ПОЛУЧЕНИЕ СВОБОДНОГО SFX ПЛЕЕРА ===

func _get_free_sfx_player() -> AudioStreamPlayer2D:
	# Ищем свободный плеер
	for player in sfx_pool:
		if not player.playing:
			return player
	
	# Если все заняты, используем самый старый (перезаписываем)
	return sfx_pool[0]


# === УПРАВЛЕНИЕ SFX ===

## Воспроизвести SFX звук
## @param sfx: AudioStream - звуковой ресурс
## @param pitch_scale: float - изменение высоты тона (1.0 = нормально)
## @param position: Vector2 - позиция для 2D звука
func play_sfx(sfx: AudioStream, volume: float = 1.0, pitch_scale: float = 1.0, position: Vector2 = Vector2.ZERO) -> void:
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
	player.volume_db = linear_to_db(sfx_volume * master_volume * volume)  # Добавили volume
	
	# 2D позиция
	if position != Vector2.ZERO:
		player.position = position
	else:
		# Ставим звук на позицию слушателя (камеры)
		var camera = get_viewport().get_camera_2d()
		if camera:
			player.position = camera.global_position
		else:
			player.position = Vector2.ZERO
	
	player.play()


## Воспроизвести SFX со случайным питчем (для разнообразия)
func play_sfx_varied(sfx: AudioStream, pitch_min: float = 0.9, pitch_max: float = 1.1) -> void:
	var pitch = randf_range(pitch_min, pitch_max)
	play_sfx(sfx, pitch)


## Воспроизвести UI звук (на отдельной шине)
func play_ui_sound(sfx: AudioStream) -> void:
	if not sfx:
		return
	
	ui_player.stream = sfx
	ui_player.volume_db = linear_to_db(DEFAULT_MASTER_VOLUME * master_volume)  # UI звуки не зависят от SFX
	ui_player.play()


## Остановить все SFX звуки
func stop_all_sfx() -> void:
	for player in sfx_pool:
		if player.playing:
			player.stop()


## Проверить, играет ли какой-либо SFX
func is_any_sfx_playing() -> bool:
	for player in sfx_pool:
		if player.playing:
			return true
	return false


# === УПРАВЛЕНИЕ МУЗЫКОЙ ===

## Установить фоновую музыку
# === УПРАВЛЕНИЕ МУЗЫКОЙ (исправленная версия) ===

## Установить фоновую музыку
func set_music(music: AudioStream, fade_in_time: float = 0.0) -> void:
	if not music:
		return
	
	if music == current_music and music_player.playing:
		return
	
	# Если уже играет другая музыка, делаем кроссфейд
	if music_player.playing and current_music:
		_crossfade_music(music, fade_in_time)
		return
	
	current_music = music
	music_player.bus = MUSIC_BUS
	
	if fade_in_time > 0:
		# Сохраняем целевую громкость
		var target_volume_db = linear_to_db(music_volume * master_volume)
		
		# Начинаем с нулевой громкости
		music_player.volume_db = linear_to_db(0.001)  # -60 dB, практически тишина
		music_player.stream = music
		music_player.play()
		
		is_music_fading = true
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", target_volume_db, fade_in_time)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_trans(Tween.TRANS_SINE)
		await tween.finished
		is_music_fading = false
	else:
		music_player.stream = music
		music_player.volume_db = linear_to_db(music_volume * master_volume)
		music_player.play()


## Остановить музыку с затуханием
func stop_music(fade_out_time: float = 0.0) -> void:
	if not music_player.playing:
		current_music = null
		return
	
	if fade_out_time > 0:
		# Сохраняем текущую громкость для восстановления
		var saved_volume_db = music_player.volume_db
		
		is_music_fading = true
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", linear_to_db(0.001), fade_out_time)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_trans(Tween.TRANS_SINE)
		await tween.finished
		
		# Останавливаем и восстанавливаем громкость
		music_player.stop()
		music_player.volume_db = saved_volume_db
		is_music_fading = false
	else:
		music_player.stop()
	
	current_music = null


## Кроссфейд между треками
func _crossfade_music(new_music: AudioStream, fade_time: float) -> void:
	if fade_time <= 0:
		# Без кроссфейда — просто переключаем
		music_player.stream = new_music
		music_player.play()
		current_music = new_music
		return
	
	# Сохраняем громкость текущего трека
	var old_volume_db = music_player.volume_db
	var target_volume_db = linear_to_db(music_volume * master_volume)
	
	# Создаём временный плеер для нового трека
	var new_player = AudioStreamPlayer.new()
	new_player.bus = MUSIC_BUS
	new_player.stream = new_music
	new_player.volume_db = linear_to_db(0.001)  # Почти тишина
	add_child(new_player)
	new_player.play()
	
	is_music_fading = true
	
	# Параллельно уменьшаем старый и увеличиваем новый
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Фейд-аут старого трека
	tween.tween_property(music_player, "volume_db", linear_to_db(0.001), fade_time)
	
	# Фейд-ин нового трека
	tween.tween_property(new_player, "volume_db", target_volume_db, fade_time)
	
	await tween.finished
	
	# Останавливаем старый плеер и восстанавливаем его громкость
	music_player.stop()
	music_player.volume_db = old_volume_db
	
	# Переносим новый трек в основной плеер
	music_player.stream = new_music
	music_player.volume_db = target_volume_db
	music_player.play()
	
	# Удаляем временный плеер
	new_player.stop()
	new_player.queue_free()
	
	current_music = new_music
	is_music_fading = false


## Плавно изменить громкость музыки (для паузы/меню)
func fade_music_volume(target_volume: float, duration: float) -> void:
	if not music_player.playing:
		return
	
	if is_music_fading:
		return
	
	is_music_fading = true
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", linear_to_db(target_volume), duration)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	await tween.finished
	is_music_fading = false


## Восстановить громкость музыки после паузы/меню
func restore_music_volume(duration: float) -> void:
	if not music_player.playing:
		return
	
	if is_music_fading:
		return
	
	var target_volume_db = linear_to_db(music_volume * master_volume)
	
	is_music_fading = true
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", target_volume_db, duration)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	await tween.finished
	is_music_fading = false


## Поставить музыку на паузу
func pause_music() -> void:
	music_player.stream_paused = true


## Продолжить воспроизведение музыки
func resume_music() -> void:
	music_player.stream_paused = false


## Проверить, играет ли музыка
func is_music_playing() -> bool:
	return music_player.playing


## Получить текущую музыку
func get_current_music() -> AudioStream:
	return current_music


# === УПРАВЛЕНИЕ ГРОМКОСТЬЮ ===

## Установить мастер-громкость
func set_master_volume(value: float) -> void:
	master_volume = value


## Установить громкость SFX
func set_sfx_volume(value: float) -> void:
	sfx_volume = value


## Установить громкость музыки
func set_music_volume(value: float) -> void:
	music_volume = value


## Получить мастер-громкость
func get_master_volume() -> float:
	return master_volume


## Получить громкость SFX
func get_sfx_volume() -> float:
	return sfx_volume


## Получить громкость музыки
func get_music_volume() -> float:
	return music_volume


## Установить все громкости сразу
func set_all_volumes(master: float, sfx: float, music: float) -> void:
	set_master_volume(master)
	set_sfx_volume(sfx)
	set_music_volume(music)


# === РАБОТА С НАСТРОЙКАМИ ===

## Сохранить настройки в файл
func save_to_file(filepath: String = "user://audio_settings.cfg") -> void:
	var config = ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.save(filepath)
	print("Настройки звука сохранены в: ", filepath)


## Загрузить настройки из файла
func load_from_file(filepath: String = "user://audio_settings.cfg") -> void:
	var config = ConfigFile.new()
	if config.load(filepath) == OK:
		master_volume = config.get_value("audio", "master_volume", DEFAULT_MASTER_VOLUME)
		sfx_volume = config.get_value("audio", "sfx_volume", DEFAULT_SFX_VOLUME)
		music_volume = config.get_value("audio", "music_volume", DEFAULT_MUSIC_VOLUME)
		print("Настройки звука загружены из: ", filepath)
	else:
		print("Файл настроек не найден, используются значения по умолчанию")
