extends Area3D

signal player_entered_aura
signal player_exited_aura

var player_in_aura: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("Player") or body.name == "Player":
		player_in_aura = true
		player_entered_aura.emit()
		print("✅ Joueur dans l'aura ! Gain de cactus activé !")

func _on_body_exited(body):
	if body.is_in_group("Player") or body.name == "Player":
		player_in_aura = false
		player_exited_aura.emit()
		print("❌ Joueur sorti de l'aura ! Gain de cactus désactivé !")
