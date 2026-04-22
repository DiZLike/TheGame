extends Area2D
class_name Portal

@export var target_portal: Portal
@export var type: String = "enter"

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var glitch: GlitchArea = $GlitchArea

var player_in_portal: bool = false
var player: Player
var is_teleporting: bool = false
var fade_time = 0.7

# Сигналы для связи с уровнем
signal fade_out_requested(duration: float)
signal fade_in_requested(duration: float)

func _ready() -> void:
	# Добавляем портал в группу для автоматического обнаружения
	add_to_group("portals")

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or player_in_portal or is_teleporting:
		return
	
	player = body
	
	if type == "enter" and target_portal:
		enter_portal()
	elif type == "exit":
		exit_portal()

func enter_portal() -> void:
	player_in_portal = true
	is_teleporting = true
	player.take_control_away(false)
	
	anim.play("opening")
	await anim.animation_finished
	
	fade_out_requested.emit(fade_time)
	#await get_tree().create_timer(1.0).timeout
	
	await hide_player()
	
	anim.play("closing")
	await anim.animation_finished
	
	teleport()

func exit_portal() -> void:
	player_in_portal = true
	is_teleporting = true
	
	player.visible = true
	player.global_position = global_position
	
	await get_tree().create_timer(1).timeout
	fade_in_requested.emit(fade_time)
	
	#anim.play("opening")
	#await anim.animation_finished
	
	player.restore_control()
	
	anim.play("closing")
	await anim.animation_finished
	
	await get_tree().create_timer(0.3).timeout
	reset_portal_state()

func hide_player() -> void:
	#glitch.visible = true
	await get_tree().create_timer(0.5).timeout
	#player.visible = false
	#glitch.visible = false

func teleport() -> void:
	if target_portal:
		target_portal.is_teleporting = true
		target_portal.player = player
		target_portal.type = "exit"
		
		player.global_position = target_portal.global_position
		
		reset_portal_state()
		
		target_portal.exit_portal()
	else:
		push_error("Portal: No target portal set!")
		await get_tree().create_timer(0.5).timeout
		if player:
			player.restore_control()
			player.visible = true
		reset_portal_state()

func reset_portal_state() -> void:
	type = "enter"
	player_in_portal = false
	is_teleporting = false

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and not is_teleporting:
		player_in_portal = false
