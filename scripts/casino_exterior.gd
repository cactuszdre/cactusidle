extends Node3D

@onready var teleport_manager = get_node("/root/Main/TeleportManager")

@export var entry_price: int = 500
@onready var game_manager = get_node_or_null("/root/Main/GameManager")
@onready var prompt_label = $EntranceGroup/PromptLabel
@onready var bodyguard = $EntranceGroup/Bodyguard
@onready var anim_player = $EntranceGroup/Bodyguard/AnimationPlayer

var is_unlocked: bool = false
var is_player_near_guard: bool = false

func _ready() -> void:
	# Register spawn point (where player appears when exiting casino)
	if teleport_manager:
		teleport_manager.exterior_spawn_point = $EntranceGroup/SpawnPoint
	
	# Connect triggers
	$EntranceGroup/TeleportArea.body_entered.connect(_on_teleport_entered)
	$EntranceGroup/InteractionArea.body_entered.connect(_on_interact_entered)
	$EntranceGroup/InteractionArea.body_exited.connect(_on_interact_exited)
	
	_update_prompt()
	_update_animation()
	
	# Generate collision for the casino model
	_generate_casino_collision()

func _generate_casino_collision() -> void:
	var model = $Model
	_add_collision_recursive(model)

func _add_collision_recursive(node: Node) -> void:
	if node is MeshInstance3D:
		node.create_trimesh_collision()
	
	for child in node.get_children():
		_add_collision_recursive(child)

func _process(_delta: float) -> void:
	if is_player_near_guard and not is_unlocked:
		if Input.is_key_pressed(KEY_E):
			_try_pay_entry()

func _try_pay_entry() -> void:
	if game_manager and game_manager.cactus_count >= entry_price:
		game_manager.add_cactus(-entry_price)
		is_unlocked = true
		print("🎰 Accès au Casino débloqué !")
		_update_prompt()
		_update_animation()
		
		# Move bodyguard aside
		var tween = create_tween()
		tween.tween_property(bodyguard, "position:x", 2.5, 1.0).set_trans(Tween.TRANS_CUBIC)
	else:
		print("⛔ Pas assez de cactus ! Prix: ", entry_price)
		# Shake prompt
		var tween = create_tween()
		tween.tween_property(prompt_label, "position:x", prompt_label.position.x + 0.1, 0.05).set_trans(Tween.TRANS_SINE)
		tween.tween_property(prompt_label, "position:x", prompt_label.position.x - 0.1, 0.05).set_trans(Tween.TRANS_SINE)
		tween.tween_property(prompt_label, "position:x", 0.0, 0.05)

func _on_teleport_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		if is_unlocked:
			if teleport_manager:
				teleport_manager.teleport_to_interior()
		else:
			print("⛔ Le garde vous bloque le passage !")
			# Push player back slightly?
			if body.has_method("set_velocity"):
				var dir = (body.global_position - global_position).normalized()
				body.velocity = dir * 5.0

func _on_interact_entered(body: Node3D) -> void:
	if body.is_in_group("Player") and not is_unlocked:
		is_player_near_guard = true
		prompt_label.visible = true
		_update_prompt()
		_update_animation()

func _on_interact_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		is_player_near_guard = false
		prompt_label.visible = false
		_update_animation()

func _update_animation() -> void:
	if is_unlocked:
		anim_player.play("idle") # Or a "welcome" animation if available
	elif is_player_near_guard:
		anim_player.play("halt")
	else:
		anim_player.play("idle")

func _update_prompt() -> void:
	if is_unlocked:
		prompt_label.text = "Bienvenue !"
		prompt_label.modulate = Color.GREEN
		# Hide prompt after a delay if unlocked
		if is_player_near_guard:
			await get_tree().create_timer(2.0).timeout
			prompt_label.visible = false
	else:
		prompt_label.text = "Garde: \"Halte ! Entrée: " + str(entry_price) + " cactus.\"\n[E] Payer"
		prompt_label.modulate = Color.RED
