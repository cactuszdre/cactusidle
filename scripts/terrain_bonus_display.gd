extends Node3D

enum SlotState { EMPTY, PLANTED, GROWING, READY }

@export var fields_root: NodePath

# Data structure:
# _fields_data[field_name] = {
#    "node": Node3D,
#    "config": Dictionary,
#    "slots": [ { "node": Node3D, "state": SlotState, "timer": float, "cactus_mesh": MeshInstance3D, "mound_mesh": MeshInstance3D } ]
# }
var _fields_data: Dictionary = {} 
var _current_field_name: String = ""

@onready var game_manager = get_node_or_null("/root/Main/GameManager")
@onready var field_prompt = get_node_or_null("/root/Main/HUD/FieldPrompt")

const FIELD_CONFIG = {
	"SmallPlot": { "duration": 10.0, "reward": 50 },
	"LargePlot": { "duration": 20.0, "reward": 250 }
}

func _ready() -> void:
	_initialize_fields()
	
	if field_prompt:
		field_prompt.visible = false

func _process(delta: float) -> void:
	# Update growing timers for all slots
	for field_name in _fields_data:
		var field_data = _fields_data[field_name]
		if not field_data.node.visible:
			continue
			
		for slot in field_data.slots:
			if slot.state == SlotState.GROWING:
				slot.timer += delta
				var duration = field_data.config.duration
				var progress = clamp(slot.timer / duration, 0.0, 1.0)
				_update_slot_visuals(slot, progress)
				
				if slot.timer >= duration:
					slot.state = SlotState.READY
					_update_slot_visuals(slot, 1.0)

	# Update prompt based on what the player is looking at
	# Update prompt based on what the player is looking at
	_handle_interaction_prompt()

func _handle_interaction_prompt() -> void:
	if not field_prompt: return
	
	var hovered_slot = _get_hovered_slot()
	if hovered_slot:
		field_prompt.visible = true
		match hovered_slot.state:
			SlotState.EMPTY:
				field_prompt.text = "Clic Gauche: Planter"
			SlotState.GROWING:
				field_prompt.text = "En pousse..."
			SlotState.READY:
				field_prompt.text = "Clic Droit: Récolter"
	else:
		field_prompt.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var hovered_slot = _get_hovered_slot()
		if hovered_slot:
			if event.button_index == MOUSE_BUTTON_LEFT and hovered_slot.state == SlotState.EMPTY:
				plant_slot(hovered_slot)
			elif event.button_index == MOUSE_BUTTON_RIGHT and hovered_slot.state == SlotState.READY:
				harvest_slot(hovered_slot)

func plant_slot(slot: Dictionary) -> void:
	if game_manager and game_manager.cactus_count >= 1:
		game_manager.add_cactus(-1)
		print("🌱 Plantation ! (-1 Cactus)")
		slot.state = SlotState.GROWING
		slot.timer = 0.0
		_update_slot_visuals(slot, 0.0)
	else:
		print("❌ Pas assez de cactus pour planter !")

func harvest_slot(slot: Dictionary) -> void:
	print("🌵 Récolte !")
	# Find which field this slot belongs to for reward calculation
	var reward = 0
	for field_name in _fields_data:
		if slot in _fields_data[field_name].slots:
			reward = _fields_data[field_name].config.reward
			break
			
	if game_manager:
		game_manager.add_cactus(reward)
	
	slot.state = SlotState.EMPTY
	_update_slot_visuals(slot, 0.0)

func get_all_slots() -> Array:
	var all_slots = []
	for field_name in _fields_data:
		var field_data = _fields_data[field_name]
		if field_data.node.visible: # Only return slots from unlocked fields
			all_slots.append_array(field_data.slots)
	return all_slots

func _get_hovered_slot() -> Dictionary:
	var camera = get_viewport().get_camera_3d()
	if not camera: 
		return {}
	
	# Use the center of the viewport for raycasting (crosshair position)
	var center_pos = get_viewport().get_visible_rect().size / 2.0
	
	var from = camera.project_ray_origin(center_pos)
	var to = from + camera.project_ray_normal(center_pos) * 100.0 # Increased range for interaction
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_bodies = true
	query.collide_with_areas = false # Disable area collision to avoid hitting the field trigger
	
	# Exclude the player itself from the raycast
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		query.exclude = [player.get_rid()]
	
	var result = space_state.intersect_ray(query)
	if result:
		var collider = result.collider
		# Check if this collider belongs to any slot in ANY unlocked field
		for field_name in _fields_data:
			var field_data = _fields_data[field_name]
			if not field_data.node.visible: continue
			
			for slot in field_data.slots:
				if slot.collider == collider:
					return slot
	return {}

func unlock_field(option_name: String) -> void:
	if _fields_data.is_empty():
		_initialize_fields()
		
	if _fields_data.has(option_name):
		var data = _fields_data[option_name]
		data.node.visible = true
		# Enable collision shapes
		for slot in data.slots:
			if slot.collider and slot.collider.get_child_count() > 0:
				slot.collider.get_child(0).disabled = false

func _initialize_fields() -> void:
	if not _fields_data.is_empty(): 
		return
	if fields_root.is_empty(): 
		return
	
	var root = get_node_or_null(fields_root)
	if not root: 
		return
	
	for child in root.get_children():
		if not child is Node3D: continue

		
		var config = FIELD_CONFIG.get(child.name, FIELD_CONFIG["SmallPlot"])
		var slots_data = []
		
		# Find "Slots" container
		var slots_node = child.get_node_or_null("Slots")
		if slots_node:
			for slot_node in slots_node.get_children():
				var cactus = slot_node.get_node_or_null("Cactus")
				var mound = slot_node.get_node_or_null("Mound")
				var sb = slot_node.get_node_or_null("StaticBody3D")
				
				if cactus and sb:
					var original_scale = cactus.scale
					slots_data.append({
						"node": slot_node,
						"state": SlotState.EMPTY,
						"timer": 0.0,
						"cactus_mesh": cactus,
						"mound_mesh": mound,
						"collider": sb,
						"original_scale": original_scale
					})
					# Duplicate material for unique color control
					if mound.material_override:
						mound.material_override = mound.material_override.duplicate()
					
					# Hide cactus initially
					cactus.visible = false
					# Disable collider initially (until unlocked)
					if sb.get_child_count() > 0:
						sb.get_child(0).disabled = true
		
		# Setup Area3D for the whole field (for entering "Farm Mode")
		var area = child.get_node_or_null("Area3D")
		if area:
			area.body_entered.connect(_on_field_entered.bind(child.name))
			area.body_exited.connect(_on_field_exited.bind(child.name))
		
		_fields_data[child.name] = {
			"node": child,
			"config": config,
			"slots": slots_data
		}
		
		child.visible = false

func _on_field_entered(body: Node, field_name: String) -> void:
	if body.is_in_group("Player"):
		if _fields_data[field_name].node.visible:
			print("Entered field: ", field_name)
			_current_field_name = field_name

func _on_field_exited(body: Node, field_name: String) -> void:
	if body.is_in_group("Player"):
		if _current_field_name == field_name:
			print("Exited field: ", field_name)
			_current_field_name = ""
			if field_prompt: field_prompt.visible = false

func _update_slot_visuals(slot: Dictionary, progress: float) -> void:
	match slot.state:
		SlotState.EMPTY:
			slot.cactus_mesh.visible = false
			if slot.mound_mesh and slot.mound_mesh.material_override:
				slot.mound_mesh.material_override.albedo_color = Color(0.25, 0.18, 0.12) # Dry soil
		SlotState.GROWING:
			slot.cactus_mesh.visible = true
			slot.cactus_mesh.scale = slot.original_scale * lerp(0.1, 1.0, progress)
			if slot.mound_mesh and slot.mound_mesh.material_override:
				slot.mound_mesh.material_override.albedo_color = Color(0.15, 0.1, 0.05) # Wet soil
		SlotState.READY:
			slot.cactus_mesh.visible = true
			slot.cactus_mesh.scale = slot.original_scale
			if slot.mound_mesh and slot.mound_mesh.material_override:
				slot.mound_mesh.material_override.albedo_color = Color(0.15, 0.1, 0.05)
