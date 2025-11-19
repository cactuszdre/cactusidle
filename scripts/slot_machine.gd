extends Node3D

@export var spin_cost: int = 50
@onready var game_manager = get_node_or_null("/root/Main/GameManager")
@onready var screen_mesh = $Screen
@onready var label = $Label3D
@onready var particles = $WinParticles

var is_spinning: bool = false
var is_player_near: bool = false

func _ready():
	$InteractionArea.body_entered.connect(_on_body_entered)
	$InteractionArea.body_exited.connect(_on_body_exited)
	_reset()

func _process(_delta):
	if is_player_near and not is_spinning and Input.is_key_pressed(KEY_E): # 'E' key
		interact()

func interact():
	if is_spinning: return
	
	if game_manager and game_manager.cactus_count >= spin_cost:
		game_manager.add_cactus(-spin_cost)
		_spin()
	else:
		label.text = "Pas assez de cactus !"
		label.modulate = Color.RED
		await get_tree().create_timer(1.0).timeout
		_reset()

func _spin():
	is_spinning = true
	label.text = "..."
	label.modulate = Color.WHITE
	
	# Visual spin effect
	for i in range(10):
		var random_color = Color(randf(), randf(), randf())
		_set_screen_color(random_color)
		await get_tree().create_timer(0.1).timeout
	
	# Result
	var roll = randf()
	if roll > 0.95: # Jackpot
		_win(500, Color.GOLD, "JACKPOT !!")
	elif roll > 0.6: # Win
		_win(100, Color.GREEN, "GAGNÉ !")
	else: # Loss
		_set_screen_color(Color.RED)
		label.text = "PERDU..."
		await get_tree().create_timer(1.0).timeout
		_reset()

func _win(amount: int, color: Color, text: String):
	_set_screen_color(color)
	label.text = text + "\n+" + str(amount)
	if game_manager:
		game_manager.add_cactus(amount)
	
	if particles:
		particles.emitting = true
		
	await get_tree().create_timer(2.0).timeout
	_reset()

func _reset():
	is_spinning = false
	_set_screen_color(Color(0.2, 0.2, 0.2))
	label.text = "JOUER\n" + str(spin_cost) + " 🌵"
	label.modulate = Color.WHITE
	if is_player_near:
		label.text += "\n[E]"

func _set_screen_color(col: Color):
	var mat = screen_mesh.get_active_material(0)
	if mat:
		mat.albedo_color = col
		mat.emission = col

func _on_body_entered(body):
	if body.is_in_group("Player"):
		is_player_near = true
		if not is_spinning:
			label.text = "JOUER\n" + str(spin_cost) + " 🌵\n[E]"

func _on_body_exited(body):
	if body.is_in_group("Player"):
		is_player_near = false
		if not is_spinning:
			label.text = "JOUER\n" + str(spin_cost) + " 🌵"

