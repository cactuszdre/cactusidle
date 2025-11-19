extends Node

# Ressources
var cactus_count: int = 0
var base_cactus_per_second: float = 100.0
var purchased_bonuses: Dictionary = {}
var has_farmer: bool = false

const AURA_BONUS_MULTIPLIER := 10

# Références
@onready var cactus_label = get_node("../HUD/CactusCounter")
@onready var aura = get_node("../CactusGiant/Aura")
@onready var terrain_display = get_node_or_null("../TerrainBonusDisplay")

# Timer
var accumulator: float = 0.0

func _ready():
	update_ui()
	
	# Connecter les signaux de l'aura
	if aura:
		aura.player_entered_aura.connect(_on_player_entered_aura)
		aura.player_exited_aura.connect(_on_player_exited_aura)

func _process(delta):
	accumulator += delta
	if accumulator >= 1.0:
		accumulator -= 1.0
		var gain := 0.0
		var in_aura: bool = aura != null and aura.player_in_aura
		if in_aura:
			gain += base_cactus_per_second
			gain *= AURA_BONUS_MULTIPLIER
		if gain > 0:
			add_cactus(int(gain))

func add_cactus(amount: int):
	cactus_count += amount
	update_ui()

func update_ui():
	if cactus_label:
		cactus_label.text = "🌵 Cactus: " + str(cactus_count)

func unlock_terrain(option_name: String) -> void:
	if purchased_bonuses.has(option_name):
		return

	purchased_bonuses[option_name] = true
	
	if option_name == "Farmer":
		has_farmer = true
		print("👨‍🌾 Fermier débloqué !")
	elif option_name == "FactoryLicense":
		print("🏭 Usine débloquée ! Appuyez sur B pour construire.")
		# Unlock logic is handled by checking purchased_bonuses in BuilderController
	elif terrain_display:
		terrain_display.unlock_field(option_name)
	
	update_ui()

func _on_player_entered_aura():
	print("💰 Début du gain de cactus !")

func _on_player_exited_aura():
	print("⏸️ Gain de cactus en pause")
	accumulator = 0.0
