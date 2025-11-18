extends Area3D

const INTERACT_KEY := KEY_E

@export var shop_ui_path: NodePath
@export var prompt_label_path: NodePath

var player_in_range: bool = false
var shop_ui: Node
var prompt_label: Label

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if shop_ui_path:
		shop_ui = get_node(shop_ui_path)
	if prompt_label_path:
		prompt_label = get_node(prompt_label_path)
	_show_prompt(false)

func _on_body_entered(body):
	if body.is_in_group("Player"):
		player_in_range = true
		_show_prompt(true)

func _on_body_exited(body):
	if body.is_in_group("Player"):
		player_in_range = false
		_show_prompt(false)
		if shop_ui and shop_ui.has_method("close_menu"):
			shop_ui.close_menu()

func _unhandled_input(event):
	if not player_in_range or shop_ui == null:
		return
	if event is InputEventKey and event.keycode == INTERACT_KEY and event.pressed and not event.echo:
		if shop_ui.has_method("toggle_menu"):
			shop_ui.toggle_menu()

func _show_prompt(visible_state: bool):
	if prompt_label:
		prompt_label.visible = visible_state
		if visible_state:
			prompt_label.text = "Appuie sur E pour ouvrir l'échoppe"
