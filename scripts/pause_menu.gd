extends Control

@onready var resume_button: Button = %ResumeButton
@onready var quit_button: Button = %QuitButton
@onready var sensitivity_slider: HSlider = %SensitivitySlider
@onready var sensitivity_value_label: Label = %SensitivityValue
@onready var music_volume_slider: HSlider = %MusicVolumeSlider
@onready var music_volume_value_label: Label = %MusicVolumeValue
@onready var keybind_container: VBoxContainer = %KeybindContainer

var is_paused: bool = false
var previous_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_VISIBLE
var player: Node = null
var audio_manager: Node = null

# Keybinds configuration
var actions_to_bind = ["avancer", "reculer", "aller_gauche", "aller_droite"]
var action_names = {
	"avancer": "Avancer",
	"reculer": "Reculer",
	"aller_gauche": "Gauche",
	"aller_droite": "Droite"
}
var waiting_for_input: String = ""
var active_button: Button = null
var fullscreen_checkbox: CheckBox = null

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS # Ensure this menu works when game is paused

	resume_button.pressed.connect(toggle_pause)
	quit_button.pressed.connect(quit_game)
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	music_volume_slider.value_changed.connect(_on_music_volume_changed)
	
	_setup_fullscreen_toggle()
	_setup_keybinds()
	
	# Find player to set initial sensitivity
	player = get_tree().get_first_node_in_group("Player")
	if player:
		sensitivity_slider.value = player.mouse_sensitivity
		_update_sensitivity_label(player.mouse_sensitivity)
	
	# Find audio manager and set initial volume
	audio_manager = get_node_or_null("/root/Main/AudioManager")
	if audio_manager:
		var current_volume = audio_manager.get_music_volume()
		music_volume_slider.value = current_volume
		_update_music_volume_label(current_volume)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F11:
		_toggle_fullscreen_mode()
		get_viewport().set_input_as_handled()

	if waiting_for_input != "":
		if event is InputEventKey and event.pressed:
			_remap_key(waiting_for_input, event)
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
		get_viewport().set_input_as_handled()

func toggle_pause() -> void:
	is_paused = not is_paused
	visible = is_paused
	get_tree().paused = is_paused
	
	if is_paused:
		previous_mouse_mode = Input.mouse_mode
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func quit_game() -> void:
	get_tree().quit()

func _on_sensitivity_changed(value: float) -> void:
	if player:
		player.mouse_sensitivity = value
	_update_sensitivity_label(value)

func _update_sensitivity_label(value: float) -> void:
	sensitivity_value_label.text = "%.3f" % value

func _setup_keybinds() -> void:
	# Clear existing children if any (for safety)
	for child in keybind_container.get_children():
		child.queue_free()
		
	for action in actions_to_bind:
		var hbox = HBoxContainer.new()
		keybind_container.add_child(hbox)
		
		var label = Label.new()
		label.text = action_names.get(action, action)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(label)
		
		var button = Button.new()
		button.custom_minimum_size = Vector2(100, 0)
		button.text = _get_key_text(action)
		button.pressed.connect(_on_keybind_pressed.bind(action, button))
		hbox.add_child(button)

func _get_key_text(action: String) -> String:
	var events = InputMap.action_get_events(action)
	if events.size() > 0:
		var event = events[0]
		if event is InputEventKey:
			return OS.get_keycode_string(event.physical_keycode)
	return "None"

func _on_keybind_pressed(action: String, button: Button) -> void:
	waiting_for_input = action
	active_button = button
	button.text = "..."

func _remap_key(action: String, event: InputEventKey) -> void:
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)
	
	if active_button:
		active_button.text = OS.get_keycode_string(event.physical_keycode)
	
	waiting_for_input = ""
	active_button = null

func _setup_fullscreen_toggle() -> void:
	fullscreen_checkbox = CheckBox.new()
	fullscreen_checkbox.text = "Plein écran (F11)"
	fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)
	
	var window = get_window()
	var mode = window.mode
	fullscreen_checkbox.button_pressed = (mode == Window.MODE_FULLSCREEN or mode == Window.MODE_EXCLUSIVE_FULLSCREEN)
	
	# Add to the same container as the buttons if possible
	if quit_button and quit_button.get_parent():
		quit_button.get_parent().add_child(fullscreen_checkbox)
		# Move it before the quit button
		quit_button.get_parent().move_child(fullscreen_checkbox, quit_button.get_index())

func _on_fullscreen_toggled(is_fullscreen: bool) -> void:
	var window = get_window()
	if is_fullscreen:
		window.mode = Window.MODE_FULLSCREEN
	else:
		window.mode = Window.MODE_WINDOWED

func _toggle_fullscreen_mode() -> void:
	var window = get_window()
	var current_mode = window.mode
	var is_fullscreen = (current_mode == Window.MODE_FULLSCREEN or current_mode == Window.MODE_EXCLUSIVE_FULLSCREEN)
	
	if is_fullscreen:
		window.mode = Window.MODE_WINDOWED
	else:
		window.mode = Window.MODE_FULLSCREEN
	
	if fullscreen_checkbox:
		fullscreen_checkbox.set_pressed_no_signal(not is_fullscreen)

func _on_music_volume_changed(value: float) -> void:
	if audio_manager:
		audio_manager.set_music_volume(value)
		audio_manager.save_settings()
	_update_music_volume_label(value)

func _update_music_volume_label(value: float) -> void:
	music_volume_value_label.text = "%.0f%%" % value
