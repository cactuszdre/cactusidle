extends Node

# Ressources
var cactus_count: int = 0
var cactus_per_second: float = 100.0

# Références
@onready var cactus_label = get_node("../HUD/CactusCounter")
@onready var aura = get_node("../CactusGiant/Aura")

# Timer
var accumulator: float = 0.0

func _ready():
	update_ui()
	
	# Connecter les signaux de l'aura
	if aura:
		aura.player_entered_aura.connect(_on_player_entered_aura)
		aura.player_exited_aura.connect(_on_player_exited_aura)

func _process(delta):
	# Gain de cactus UNIQUEMENT si le joueur est dans l'aura
	if aura and aura.player_in_aura:
		accumulator += delta
		
		if accumulator >= 1.0:
			add_cactus(int(cactus_per_second))
			accumulator -= 1.0

func add_cactus(amount: int):
	cactus_count += amount
	update_ui()

func update_ui():
	if cactus_label:
		cactus_label.text = "🌵 Cactus: " + str(cactus_count)

func _on_player_entered_aura():
	print("💰 Début du gain de cactus !")

func _on_player_exited_aura():
	print("⏸️ Gain de cactus en pause")
	accumulator = 0.0
