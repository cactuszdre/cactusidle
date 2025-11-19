extends Machine

class_name Seller

@onready var game_manager = get_node_or_null("/root/Main/GameManager")

const PRICES = {
	"cactus": 1,
	"cactus_juice": 10
}

func can_accept_item(_item: Dictionary, _from_dir: int) -> bool:
	return true # Always accepts items to sell

func inject_item(item: Dictionary) -> void:
	var type = item.get("type", "cactus")
	var amount = item.get("amount", 1)
	var price = PRICES.get(type, 1)
	
	var total_value = price * amount
	
	if game_manager:
		game_manager.add_cactus(total_value)
		print("💰 Seller: Sold ", amount, " ", type, " for ", total_value)
	
	# Visual feedback could go here
