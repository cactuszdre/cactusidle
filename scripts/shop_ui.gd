extends Control

var is_open: bool = false
var previous_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_VISIBLE

@onready var close_button: Button = %CloseButton
@onready var terrain_list: VBoxContainer = %TerrainList

func _ready():
	close_button.pressed.connect(close_menu)
	_wire_buy_buttons()
	visible = false

func _wire_buy_buttons():
	for option in terrain_list.get_children():
		if option.has_node("BuyButton"):
			var button := option.get_node("BuyButton")
			if button is Button:
				button.pressed.connect(_on_buy_pressed.bind(option.name))

func open_menu():
	if is_open:
		return
	is_open = true
	previous_mouse_mode = Input.mouse_mode
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

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

func _on_buy_pressed(option_name: String):
	print("📋 Achat simulé pour:", option_name)
