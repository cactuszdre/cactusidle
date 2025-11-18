extends Node

# Ressources
var cactus_count: int = 0
var base_cactus_per_second: float = 100.0
var bonus_cactus_per_second: float = 0.0
var purchased_bonuses: Dictionary = {}

const AURA_BONUS_MULTIPLIER := 1

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
	accumulator += delta
	if accumulator >= 1.0:
		accumulator -= 1.0
		var gain := bonus_cactus_per_second
		var in_aura: bool = aura != null and aura.player_in_aura
		if in_aura:
			gain += base_cactus_per_second
			gain *= AURA_BONUS_MULTIPLIER
		add_cactus(int(gain))

func add_cactus(amount: int):
	cactus_count += amount
	update_ui()

func update_ui():
	if cactus_label:
		cactus_label.text = "🌵 Cactus: " + str(cactus_count)

func apply_terrain_bonus(option_name: String, bonus_data: Dictionary) -> void:
	if purchased_bonuses.has(option_name):
		return

	purchased_bonuses[option_name] = true
	var cps_bonus := float(bonus_data.get("cps", 0.0))
	var instant_bonus := int(bonus_data.get("instant", 0))

	if cps_bonus != 0.0:
		bonus_cactus_per_second += cps_bonus

	if instant_bonus != 0:
		add_cactus(instant_bonus)
	else:
		update_ui()

func _on_player_entered_aura():
	print("💰 Début du gain de cactus !")

func _on_player_exited_aura():
	print("⏸️ Gain de cactus en pause")
	accumulator = 0.0
