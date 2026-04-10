# autoload/DialogueLoader.gd
extends Node

# Константы
const DIALOGUES_PATH = "res://data/dialogues/"
var dialogues_cache = {}

# Структура одной реплики
class DialogueLine:
	var id: String
	var speaker: String
	var text: String
	var portrait_path: String
	var sound_path: String
	var next_id: String
	var choices: Array  # Для ветвлений (опционально)
	var on_start_methods: Array  # Методы для выполнения в начале реплики
	var on_end_methods: Array    # Методы для выполнения в конце реплики
	var glitch_enabled: bool = false  # Флаг включения glitch-эффекта
	
	func _init(data: Dictionary):
		id = data.get("Id", "")
		speaker = data.get("Speaker", "")
		text = data.get("Text", "")
		portrait_path = data.get("Portrait", "")
		sound_path = data.get("Sound", "")
		next_id = data.get("Next", "")
		choices = data.get("Choices", [])
		glitch_enabled = data.get("GlitchEnabled", false)
		
		# Поддерживаем два формата: строка или массив строк
		var start_methods = data.get("OnStartMethods", "")
		if typeof(start_methods) == TYPE_STRING:
			on_start_methods = [start_methods] if not start_methods.is_empty() else []
		
		var end_methods = data.get("OnEndMethods", "")
		if typeof(end_methods) == TYPE_STRING:
			on_end_methods = [end_methods] if not end_methods.is_empty() else []

# Загрузка всего диалога из JSON файла
func load_dialogue(filename: String) -> Array:
	# Убираем расширение, если оно есть
	filename = filename.trim_suffix(".json")
	var full_path = DIALOGUES_PATH + filename + ".json"
	
	# Проверяем кэш
	if dialogues_cache.has(full_path):
		return dialogues_cache[full_path]
	
	# Проверяем существование файла
	if not FileAccess.file_exists(full_path):
		push_error("[DialogueLoader] Файл не найден: ", full_path)
		return []
	
	# Читаем файл
	var file = FileAccess.open(full_path, FileAccess.READ)
	if file == null:
		push_error("[DialogueLoader] Не удалось открыть файл: ", full_path)
		return []
	
	var json_text = file.get_as_text()
	file.close()
	
	# Парсим JSON
	var json = JSON.new()
	var error = json.parse(json_text)
	
	if error != OK:
		push_error("[DialogueLoader] Ошибка парсинга JSON: ", json.get_error_message())
		push_error("[DialogueLoader] В файле: ", full_path)
		return []
	
	var data = json.get_data()
	
	# Проверяем структуру данных
	if not data.has("Dialogues"):
		push_error("[DialogueLoader] В файле отсутствует ключ 'dialogues': ", full_path)
		return []
	
	# Конвертируем в массив объектов DialogueLine
	var result = []
	for d in data["Dialogues"]:
		var line = DialogueLine.new(d)
		result.append(line)
	
	# Сохраняем в кэш
	dialogues_cache[full_path] = result
	
	print("[DialogueLoader] Загружено ", result.size(), " реплик из: ", filename)
	return result

# Получение конкретной реплики по ID
func get_dialogue_by_id(filename: String, dialogue_id: String) -> Dictionary:
	var dialogues = load_dialogue(filename)
	for d in dialogues:
		if d.id == dialogue_id:
			# Возвращаем как словарь для удобства
			return {
				"Id": d.id,
				"Speaker": d.speaker,
				"Text": d.text,
				"Portrait_path": d.portrait_path,
				"Sound_path": d.sound_path,
				"Next_id": d.next_id,
				"Choices": d.choices,
				"OnStartMethods": d.on_start_methods,
				"OnEndMethods": d.on_end_methods,
				"GlitchEnabled": d.glitch_enabled
			}
	return {}

# Очистка кэша (если нужно перезагрузить диалоги)
func clear_cache():
	dialogues_cache.clear()
	print("[DialogueLoader] Кэш очищен")
