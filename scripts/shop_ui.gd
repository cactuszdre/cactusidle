extends Control

var is_open: bool = false
var previous_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_VISIBLE
var purchased_options: Dictionary = {}

@onready var close_button: Button = %CloseButton
@onready var terrain_list: VBoxContainer = %TerrainList
@onready var game_manager: Node = get_node_or_null("/root/Main/GameManager")
@onready var bonus_display: Node = get_node_or_null("/root/Main/TerrainBonusDisplay")

# Prix des terrains
const TERRAIN_PRICES: Dictionary = {
	"SmallPlot": 150,
	"LargePlot": 600
}

const TERRAIN_BONUS_DATA: Dictionary = {
	"SmallPlot": {
		"label": "Parcelle fertile +2/s",
		"cps": 2.0,
		"instant": 0,
		"field_type": "small"
	},
	"LargePlot": {
		"label": "Dune luxuriante +10/s",
		"cps": 10.0,
		"instant": 0,
		"field_type": "large"
	}
}

const BUY_BUTTON_PATH := "Content/HBox/PriceSection/BuyButton"

func _ready():
	close_button.pressed.connect(close_menu)
	_wire_buy_buttons()
	visible = false

func _wire_buy_buttons():
	for option in terrain_list.get_children():
		if option.has_node(BUY_BUTTON_PATH):
			var button := option.get_node(BUY_BUTTON_PATH) as Button
			if button:
				button.pressed.connect(_on_buy_pressed.bind(option.name))

func open_menu():
	if is_open:
		return
	is_open = true
	previous_mouse_mode = Input.mouse_mode
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_update_button_states()

func close_menu():
	if not is_open:
		return
	is_open = false
	visible = false
	Input.set_mouse_mode(previous_mouse_mode)

func toggle_menu():
	if is_open:
		close_menu()
	else:
		open_menu()

func _process(_delta: float) -> void:
	if is_open:
		_update_button_states()

func _on_buy_pressed(option_name: String):
	if purchased_options.has(option_name):
		return

	var price: int = TERRAIN_PRICES.get(option_name, 0)
	if game_manager and game_manager.cactus_count >= price:
		game_manager.add_cactus(-price)
		print("🎉 Achat réussi:", option_name)
		var bonus_data: Dictionary = TERRAIN_BONUS_DATA.get(option_name, {})
		var bonus_label: String = bonus_data.get("label", "Bonus débloqué")
		if not bonus_data.is_empty() and game_manager.has_method("apply_terrain_bonus"):
			game_manager.apply_terrain_bonus(option_name, bonus_data)
		var field_type: String = bonus_data.get("field_type", "small")
		if bonus_display and bonus_display.has_method("show_bonus"):
			bonus_display.show_bonus(option_name, bonus_label, field_type)
		_handle_option_purchased(option_name)
		_update_button_states()
	else:
		print("❌ Pas assez de cactus pour:", option_name)

func _update_button_states() -> void:
	if not game_manager:
		return
	
	for option in terrain_list.get_children():
		if purchased_options.has(option.name):
			option.queue_free()
			continue
		if option.has_node(BUY_BUTTON_PATH):
			var button := option.get_node(BUY_BUTTON_PATH) as Button
			var price: int = TERRAIN_PRICES.get(option.name, 0)
			var can_afford: bool = game_manager.cactus_count >= price
			
			button.disabled = not can_afford
			button.modulate = Color(1, 1, 1, 1.0 if can_afford else 0.4)

func _handle_option_purchased(option_name: String) -> void:
	purchased_options[option_name] = true
	_remove_option_from_ui(option_name)

func _remove_option_from_ui(option_name: String) -> void:
	for option in terrain_list.get_children():
		if option.name == option_name:
			option.queue_free()
			return
