extends CanvasLayer

const WeaponsType = preload("res://scripts/weapon_types.gd")
const D_WEAPON = preload("res://scenes/ui/weapon/d_weapon.tscn")
const M_WEAPON = preload("res://scenes/ui/weapon/m_weapon.tscn")
const S_WEAPON = preload("res://scenes/ui/weapon/s_weapon.tscn")
const H_WEAPON = preload("res://scenes/ui/weapon/h_weapon.tscn")
const R_WEAPON = preload("res://scenes/ui/weapon/r_weapon.tscn")
const L_WEAPON = preload("res://scenes/ui/weapon/l_weapon.tscn")

@onready var score_label: Label = $ScorePanel/ScoreLabel
@onready var medal1: AnimatedSprite2D = $LivesPanel/Medal1
@onready var medal2: AnimatedSprite2D = $LivesPanel/Medal2
@onready var medal3: AnimatedSprite2D = $LivesPanel/Medal3
@onready var medal4: AnimatedSprite2D = $LivesPanel/Medal4
@onready var weapon_panel: Panel = $WeaponPanel
@onready var current_weapon: AnimatedSprite2D = $WeaponPanel/CurrentWeapon

@onready var current_level: Label = $WeaponPanel/CurrentLevel
@onready var current_ammo_label: Label = $WeaponPanel/CurrentAmmo
@onready var max_ammo_label: Label = $WeaponPanel/MagazineSize

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ScoreManager.connect("score_changed", update_score_display)
	GameManager.connect("lives_changed", _on_lives_changed)
	WeaponManager.connect("weapon_changed", _on_weapon_changed)
	WeaponManager.connect("weapon_upgraded", _on_weapon_upgraded)
	WeaponManager.connect("ammo_changed", on_ammo_changed)
	
	update_lives_display(GameManager.get_lives())
	update_score_display(ScoreManager.get_score())
	update_weapon_display(GameManager.get_current_weapon(), GameManager.get_current_weapon_level())
	update_ammo_display(WeaponManager.get_current_ammo(), WeaponManager.get_max_ammo())
	GameManager.register_lives_panel(self)

func _on_lives_changed(new_lives: int, old_lives: int):
	update_lives_display(new_lives)

func _on_score_changed(new_score: int):
	update_score_display(new_score)
	
func _on_weapon_changed(weapon_type: WeaponsType.WeaponType, level: int):
	update_weapon_display(weapon_type, level)

func _on_weapon_upgraded(weapon_type: WeaponsType.WeaponType, new_level: int):
	current_level.text = str(new_level + 1)
	
func on_ammo_changed(current_ammo: int, max_ammo: int):
	update_ammo_display(current_ammo, max_ammo)

func update_lives_display(lives: int) -> void:
	medal1.visible = lives >= 1
	medal2.visible = lives >= 2
	medal3.visible = lives >= 3
	medal4.visible = lives >= 4

func update_score_display(new_score: int):
	score_label.text = str(new_score).pad_zeros(7)
	
func update_weapon_display(weapon_type: WeaponsType.WeaponType, level: int) -> void:
	# Сохраняем позицию старого оружия
	var old_position = Vector2(25, 25)  # позиция по умолчанию
	if is_instance_valid(current_weapon):
		old_position = current_weapon.position
		current_weapon.queue_free()
		current_weapon = null
	
	# Создаём новое оружие
	match weapon_type:
		WeaponsType.WeaponType.DEFAULT:
			current_weapon = D_WEAPON.instantiate()
		WeaponsType.WeaponType.MACHINEGUN:
			current_weapon = M_WEAPON.instantiate()
		WeaponsType.WeaponType.SPREADGUN:
			current_weapon = S_WEAPON.instantiate()
		WeaponsType.WeaponType.HOMING:
			current_weapon = H_WEAPON.instantiate()
		WeaponsType.WeaponType.ROCKET:
			current_weapon = R_WEAPON.instantiate()
		WeaponsType.WeaponType.LASER:
			current_weapon = L_WEAPON.instantiate()
		_:
			return
	current_level.text = str(level + 1)
	# Добавляем в панель и ставим на ту же позицию
	weapon_panel.add_child(current_weapon)
	current_weapon.position = old_position
	current_weapon.visible = true

func update_ammo_display(current_ammo: int, max_ammo: int) -> void:
	current_ammo_label.text = str(current_ammo)
	max_ammo_label.text = str(max_ammo)
