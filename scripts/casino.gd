extends Node3D

@export var entry_price: int = 500
@onready var game_manager = get_node_or_null("/root/Main/GameManager")
@onready var prompt_label = $PromptLabel
@onready var door_anim = $DoorAnim

var is_player_near: bool = false
var is_unlocked: bool = false

func _ready():
	$EntranceArea.body_entered.connect(_on_body_entered)
	$EntranceArea.body_exited.connect(_on_body_exited)
	_update_prompt()

func _process(_delta):
	if is_player_near and Input.is_key_pressed(KEY_E): # 'E' key
		if not is_unlocked:
			_try_pay_entry()
		else:
			_enter_casino()

func _try_pay_entry():
	if game_manager and game_manager.cactus_count >= entry_price:
		game_manager.add_cactus(-entry_price)
		is_unlocked = true
		print("🎰 Accès au Casino débloqué !")
		_update_prompt()
		
		# Visual feedback: Open the door and move guard
		var tween = create_tween().set_parallel(true)
		tween.tween_property($Bodyguard, "position:x", 4.0, 1.5).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property($BigDoor, "position:y", 8.0, 2.0).set_trans(Tween.TRANS_BOUNCE) # Lift door up
	else:
		print("⛔ Pas assez de cactus ! Prix: ", entry_price)
		# Shake prompt or something
		var tween = create_tween()
		tween.tween_property(prompt_label, "position:x", prompt_label.position.x + 0.1, 0.05).set_trans(Tween.TRANS_SINE)
		tween.tween_property(prompt_label, "position:x", prompt_label.position.x - 0.1, 0.05).set_trans(Tween.TRANS_SINE)
		tween.tween_property(prompt_label, "position:x", 0.0, 0.05)

func _enter_casino():
	print("🎰 Bienvenue au Casino ! (Fonctionnalité à venir)")
	# TODO: Load casino scene or show UI

func _on_body_entered(body):
	if body.is_in_group("Player"):
		is_player_near = true
		prompt_label.visible = true
		_update_prompt()

func _on_body_exited(body):
	if body.is_in_group("Player"):
		is_player_near = false
		prompt_label.visible = false

func _update_prompt():
	if is_unlocked:
		prompt_label.text = "[E] Entrer au Casino"
		prompt_label.modulate = Color.GREEN
	else:
		prompt_label.text = "Garde: \"Halte ! L'entrée est de " + str(entry_price) + " cactus.\"\n[E] Payer l'entrée"
		prompt_label.modulate = Color.RED
