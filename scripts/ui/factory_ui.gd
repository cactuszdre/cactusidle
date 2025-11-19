extends Control

class_name FactoryUI

signal machine_selected(index: int)

@onready var button_container = %MachineList

var machine_names = ["Convoyeur", "Récolteur", "Processeur", "Vendeur"]
var machine_icons = ["➡️", "🤖", "🏭", "💰"]
var machine_descriptions = [
	"Transporte les objets entre les machines",
	"Récolte automatiquement les cactus mûrs",
	"Transforme 10 cactus en jus de cactus",
	"Vend les objets contre des cactus"
]
var machine_shortcuts = ["1", "2", "3", "4"]

var current_selection: int = 0
var buttons: Array[Button] = []

func _ready():
	_create_buttons()
	_update_selection(0)

func _create_buttons():
	for i in range(machine_names.size()):
		var button_panel = PanelContainer.new()
		button_panel.custom_minimum_size = Vector2(200, 80)
		
		# Style for panel
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.15, 0.15, 0.2, 0.9)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.3, 0.3, 0.4, 1)
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		button_panel.add_theme_stylebox_override("panel", style)
		
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 12)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_right", 12)
		margin.add_theme_constant_override("margin_bottom", 8)
		button_panel.add_child(margin)
		
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 4)
		margin.add_child(vbox)
		
		# Top row: Icon + Name + Shortcut
		var top_row = HBoxContainer.new()
		top_row.add_theme_constant_override("separation", 8)
		vbox.add_child(top_row)
		
		var icon_label = Label.new()
		icon_label.text = machine_icons[i]
		icon_label.add_theme_font_size_override("font_size", 32)
		top_row.add_child(icon_label)
		
		var name_label = Label.new()
		name_label.text = machine_names[i]
		name_label.add_theme_font_size_override("font_size", 18)
		name_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8, 1))
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top_row.add_child(name_label)
		
		var shortcut_label = Label.new()
		shortcut_label.text = "[" + machine_shortcuts[i] + "]"
		shortcut_label.add_theme_font_size_override("font_size", 16)
		shortcut_label.add_theme_color_override("font_color", Color(1, 0.8, 0.4, 1))
		top_row.add_child(shortcut_label)
		
		# Description
		var desc_label = Label.new()
		desc_label.text = machine_descriptions[i]
		desc_label.add_theme_font_size_override("font_size", 12)
		desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(desc_label)
		
		# Make the whole panel clickable
		var button = Button.new()
		button.flat = true
		button.custom_minimum_size = button_panel.custom_minimum_size
		button.pressed.connect(_on_button_pressed.bind(i))
		
		# Store references
		buttons.append(button)
		button_panel.add_child(button)
		button.move_to_front()
		
		button_container.add_child(button_panel)

func _on_button_pressed(index: int):
	_update_selection(index)
	machine_selected.emit(index)

func _update_selection(index: int):
	current_selection = index
	
	# Update visual feedback for all buttons
	for i in range(buttons.size()):
		var panel = button_container.get_child(i) as PanelContainer
		var style = panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		
		if i == current_selection:
			# Highlight selected
			style.border_color = Color(1, 0.8, 0.2, 1)
			style.border_width_left = 4
			style.border_width_top = 4
			style.border_width_right = 4
			style.border_width_bottom = 4
			style.bg_color = Color(0.2, 0.2, 0.3, 0.95)
		else:
			# Normal state
			style.border_color = Color(0.3, 0.3, 0.4, 1)
			style.border_width_left = 2
			style.border_width_top = 2
			style.border_width_right = 2
			style.border_width_bottom = 2
			style.bg_color = Color(0.15, 0.15, 0.2, 0.9)
		
		panel.add_theme_stylebox_override("panel", style)

func select_machine(index: int):
	if index >= 0 and index < machine_names.size():
		_update_selection(index)
