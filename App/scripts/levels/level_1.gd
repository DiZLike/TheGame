extends BaseLevel

#region Константы
const ENEMY_SCHOOLBOY: String = "res://scenes/enemy/schoolboy.tscn"
#endregion

#region Жизненный цикл
func _ready() -> void:
	super._ready()
	# Дополнительная инициализация не требуется, 
	# _on_level_specific_ready вызывается в базовом классе
#endregion

#region Переопределённые виртуальные методы
func _on_level_specific_ready() -> void:
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

func weapon_training_enable() -> void:
	GameManager.dialogue_trig["weapon_training_enable"] = true
	_restore_level_music()
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

func _restore_level_music() -> void:
	AudioManager.stop_music()
	if level_music:
		AudioManager.set_music(level_music)
#endregion

#region Обработчики сигналов
func barrier_1_group_destroyed(group_name: String) -> void:
	if group_name == "b1":
		show_dialogue("/level_01/null_hint_barrier_01_destroy", "d1", false)
		$Environment/SpawnersCapsule/CapsuleSpawner6.queue_free()
		$Environment/Bags/Bug.remove()
#endregion
