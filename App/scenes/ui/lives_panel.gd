extends CanvasLayer

@onready var score_label: Label = $ScorePanel/ScoreLabel
@onready var medal1: AnimatedSprite2D = $LivesPanel/Medal1
@onready var medal2: AnimatedSprite2D = $LivesPanel/Medal2
@onready var medal3: AnimatedSprite2D = $LivesPanel/Medal3
@onready var medal4: AnimatedSprite2D = $LivesPanel/Medal4

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ScoreManager.connect("score_changed", update_score_display)
	GameManager.connect("lives_changed", _on_lives_changed)
	update_lives_display(GameManager.get_lives())
	update_score_display(ScoreManager.get_score())

func _on_lives_changed(new_lives: int):
	update_lives_display(new_lives)

func _on_score_changed(new_score: int):
	update_score_display(new_score)

func update_lives_display(lives: int) -> void:
	medal1.visible = lives >= 1
	medal2.visible = lives >= 2
	medal3.visible = lives >= 3
	medal4.visible = lives >= 4
func update_score_display(new_score: int):
	score_label.text = str(new_score).pad_zeros(7)
