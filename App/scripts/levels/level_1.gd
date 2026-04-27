extends BaseLevel

#region Константы
const ENEMY_SCHOOLBOY: String = "res://scenes/enemy/schoolboy.tscn"
#endregion

var ambient_jungle: AudioStream = preload("res://data/audio/ambient/jungle.wav")
var ambient_acid: AudioStream = preload("res://data/audio/ambient/acid.ogg")

#region Жизненный цикл
func _ready() -> void:
	print("Загрузка уровня")
	GameManager.set_current_level("res://levels/level_1.scn")
	super._ready()
	# Дополнительная инициализация не требуется, 
	# _on_level_specific_ready вызывается в базовом классе
#endregion

#region Переопределённые виртуальные методы
func _on_level_specific_ready() -> void:
	ambient_music = ambient_jungle
	_setup_barrier_signals()
#endregion

#region Инициализация (private)
func _setup_barrier_signals() -> void:
	if not BarrierSourceManager.group_destroyed.is_connected(barrier_1_group_destroyed):
		BarrierSourceManager.group_destroyed.connect(barrier_1_group_destroyed)
#endregion

#region Методы диалогов (публичные, вызываются из DialogueBox)
func _01_create_glitch_enemy() -> void:
	var enemy: Node2D = _spawn_enemy_at_marker($Environment/Markers/Marker, "left")
	if enemy:
		get_tree().current_scene.add_child(enemy)

func barrier_1_puzzle_activate() -> void:
	$"Environment/BarrierSources/Barrier Source 1".set_enable()
	$"Environment/BarrierSources/Barrier Source 2".set_enable()
	$"Environment/BarrierSources/Barrier Source 3".set_enable()
	$Environment/SpawnersCapsule/CapsuleSpawner6.enable = true

func _01_2_activate() -> void:
	var trig: DialogueTrigger = $Environment/DialogueTriggers/DTrig2
	trig.activate()

func intro_dialogues_completed() -> void:
	GameManager._player_data["game"]["intro_dialogues_completed"] = true
	_play_level_music()
	
func acid_underground_startrd() -> void:
	AudioManager._crossfade_music(ambient_acid, 0.3)
	
func acid_underground_completed() -> void:
	AudioManager._crossfade_music(level_music, 0.3)
#endregion

#region Вспомогательные методы (private)
func _spawn_enemy_at_marker(marker: Node2D, direction: String) -> Node2D:
	if not marker:
		push_error("Marker not found for enemy spawn!")
		return null
	
	var enemy_scene: PackedScene = load(ENEMY_SCHOOLBOY)
	var enemy = enemy_scene.instantiate()
	enemy.global_position = marker.global_position
	
	if enemy.has_method("set_move_direction"):
		enemy.set_move_direction(direction)
	
	return enemy

func _play_level_music() -> void:
	AudioManager._crossfade_music(level_music, 0.3)
#endregion

#region Обработчики сигналов
func barrier_1_group_destroyed(group_name: String) -> void:
	if level_destroy:
		return
	if group_name == "b1":
		var bug = $Environment/Bags/Bug
		var capsule = $Environment/SpawnersCapsule/CapsuleSpawner6
		show_dialogue("/level_01/null_hint_barrier_01_destroy", "d1", false)
		if capsule:
			capsule.queue_free()
		if bug:
			bug.remove()
#endregion
