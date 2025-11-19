extends Node

class_name BuilderController

@export var factory_manager_path: NodePath
@onready var factory_manager = get_node(factory_manager_path)

@onready var factory_ui = get_node_or_null("../HUD/FactoryUI")

# Building State
var is_building_mode: bool = false
var current_machine_idx: int = 0
var current_rotation: int = 0

# Ghost
var ghost_instance: Node3D
var ghost_valid: bool = false

# Available Machines
var machine_scenes = [
	preload("res://scenes/machines/conveyor.tscn"),
	preload("res://scenes/machines/harvester.tscn"),
	preload("res://scenes/machines/processor.tscn"),
	preload("res://scenes/machines/seller.tscn")
]
var machine_names = ["Conveyor", "Harvester", "Processor", "Seller"]

@onready var build_hint = get_node_or_null("../HUD/BuildModeHint")

func _ready():
	if factory_ui:
		factory_ui.machine_selected.connect(_on_machine_selected)
	_check_license_visibility()

func _process(_delta: float) -> void:
	_check_license_visibility()
	
	if Input.is_action_just_pressed("toggle_build_mode"): # Bind 'B'
		if factory_manager.game_manager.purchased_bonuses.has("FactoryLicense"):
			toggle_build_mode()
		else:
			print("🔒 Vous devez acheter le Permis de Construire d'abord !")
		
	if not is_building_mode:
		return
		
	_handle_input()
	_update_ghost()

func _input(event: InputEvent) -> void:
	if not is_building_mode:
		return
	
	# Mouse wheel to cycle through machines
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				var new_idx = (current_machine_idx - 1) % machine_scenes.size()
				if new_idx < 0:
					new_idx = machine_scenes.size() - 1
				_select_machine_direct(new_idx)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				var new_idx = (current_machine_idx + 1) % machine_scenes.size()
				_select_machine_direct(new_idx)

func toggle_build_mode() -> void:
	is_building_mode = !is_building_mode
	if is_building_mode:
		print("🔨 Mode Construction Activé")
		if factory_ui: factory_ui.visible = true
		_create_ghost()
		
		# Enable arm override
		var player = get_tree().get_first_node_in_group("Player")
		if player and player.has_node("PlayerModel"):
			player.get_node("PlayerModel").override_right_arm = true
	else:
		print("❌ Mode Construction Désactivé")
		if factory_ui: factory_ui.visible = false
		_destroy_ghost()
		
		# Reset arm
		var player = get_tree().get_first_node_in_group("Player")
		if player and player.has_node("PlayerModel"):
			var model = player.get_node("PlayerModel")
			model.override_right_arm = false
			if model.has_node("ShoulderRight"):
				model.get_node("ShoulderRight").rotation = Vector3.ZERO

func _on_machine_selected(index: int):
	_select_machine_direct(index)

func _create_ghost() -> void:
	_destroy_ghost()
	if machine_scenes.size() > current_machine_idx:
		ghost_instance = machine_scenes[current_machine_idx].instantiate()
		add_child(ghost_instance)
		# Make it transparent
		_set_transparency(ghost_instance, 0.5)

func _destroy_ghost() -> void:
	if ghost_instance:
		ghost_instance.queue_free()
		ghost_instance = null

func _handle_input() -> void:
	# Rotate
	if Input.is_action_just_pressed("rotate_building"): # Bind 'R'
		current_rotation = (current_rotation + 1) % 4
		if ghost_instance:
			ghost_instance.rotation_degrees.y = -90 * current_rotation
			
	# Switch Machine with Tab
	if Input.is_action_just_pressed("next_machine"): # Bind 'Tab'
		current_machine_idx = (current_machine_idx + 1) % machine_scenes.size()
		print("Selected: ", machine_names[current_machine_idx])
		_create_ghost()
		if factory_ui:
			factory_ui._update_selection(current_machine_idx)
	
	# Keyboard shortcuts 1-4
	if Input.is_key_pressed(KEY_1) and not Input.is_key_pressed(KEY_SHIFT):
		_select_machine_direct(0)
	elif Input.is_key_pressed(KEY_2) and not Input.is_key_pressed(KEY_SHIFT):
		_select_machine_direct(1)
	elif Input.is_key_pressed(KEY_3) and not Input.is_key_pressed(KEY_SHIFT):
		_select_machine_direct(2)
	elif Input.is_key_pressed(KEY_4) and not Input.is_key_pressed(KEY_SHIFT):
		_select_machine_direct(3)
		
	# Place / Remove
	if Input.is_action_just_pressed("build_action"): # Left Click
		if ghost_valid and ghost_instance:
			var grid_pos = factory_manager.world_to_grid(ghost_instance.global_position)
			factory_manager.place_machine(machine_scenes[current_machine_idx], grid_pos, current_rotation)
			
	if Input.is_action_just_pressed("remove_action"): # Right Click
		var grid_pos = _get_grid_pos_under_mouse()
		factory_manager.remove_machine(grid_pos)

func _update_ghost() -> void:
	if not ghost_instance: return
	
	var grid_pos = _get_grid_pos_under_mouse()
	ghost_instance.global_position = factory_manager.grid_to_world(grid_pos)
	
	# Check validity
	if factory_manager.grid.has(grid_pos):
		_set_color(ghost_instance, Color.RED)
		ghost_valid = false
	else:
		_set_color(ghost_instance, Color.GREEN)
		ghost_valid = true
	
	# Point player arm at ghost
	var player = get_tree().get_first_node_in_group("Player")
	if player and player.has_node("PlayerModel/ShoulderRight"):
		var arm = player.get_node("PlayerModel/ShoulderRight")
		# We want the arm to point towards the ghost, but we need to account for the player's rotation
		# and the arm's initial offset.
		# A simple look_at might be enough if the arm's forward vector is correct.
		# Assuming -Z is forward for the arm in its local space (standard in Godot)
		
		# We use global coordinates for look_at
		arm.look_at(ghost_instance.global_position, Vector3.UP)
		
		# Optional: Clamp rotation to avoid weird twisting if needed, 
		# but look_at usually handles it well for simple pointing.
		# We might need to adjust rotation offset if the mesh is not aligned with -Z
		arm.rotate_object_local(Vector3.RIGHT, deg_to_rad(90)) # Adjust if the arm mesh points down by default

func _get_grid_pos_under_mouse() -> Vector2i:
	var camera = get_viewport().get_camera_3d()
	if not camera: return Vector2i.ZERO
	
	# Use screen center instead of mouse position
	var screen_center = get_viewport().get_visible_rect().size / 2.0
	var ray_origin = camera.project_ray_origin(screen_center)
	var ray_direction = camera.project_ray_normal(screen_center)
	
	# Raycast to a plane at y=0
	var plane = Plane(Vector3.UP, 0)
	var intersect = plane.intersects_ray(ray_origin, ray_direction)
	
	if intersect:
		return factory_manager.world_to_grid(intersect)
	return Vector2i.ZERO

func _set_transparency(node: Node, alpha: float) -> void:
	# Recursive helper to set transparency on meshes
	if node is MeshInstance3D:
		node.transparency = alpha # Godot 4 property
	for child in node.get_children():
		_set_transparency(child, alpha)

func _set_color(_node: Node, _color: Color) -> void:
	# Simple visual feedback (requires material override setup, skipping for brevity but good to have)
	pass

func _check_license_visibility() -> void:
	if build_hint:
		var has_license = factory_manager.game_manager.purchased_bonuses.has("FactoryLicense")
		build_hint.visible = has_license and not is_building_mode

func _select_machine_direct(index: int) -> void:
	if index >= 0 and index < machine_scenes.size():
		current_machine_idx = index
		print("Selected: ", machine_names[current_machine_idx])
		if is_building_mode:
			_create_ghost()
		if factory_ui:
			factory_ui._update_selection(index)
