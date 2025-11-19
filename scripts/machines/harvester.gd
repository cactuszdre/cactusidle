extends Machine

class_name AutoHarvester

@onready var terrain_display = get_node_or_null("/root/Main/TerrainBonusDisplay")

@onready var visual_cactus = get_node_or_null("VisualCactus")

var output_buffer: Dictionary = {}

func tick(_delta: float) -> void:
	# Update visuals
	if visual_cactus:
		visual_cactus.visible = not output_buffer.is_empty()

	# 1. Try to output if we have something
	if not output_buffer.is_empty():
		var target_pos = get_input_world_pos() # Output to the back
		var target_machine = factory_manager.get_closest_machine(target_pos)
		
		if target_machine and target_machine.can_accept_item(output_buffer, (rotation_dir + 2) % 4):
			target_machine.inject_item(output_buffer)
			output_buffer = {}
		return

	# 2. Try to harvest
	if terrain_display:
		# Check the tile in front
		var target_world_pos = get_output_world_pos()
		var slot = _find_slot_at(target_world_pos)
		
		if not slot.is_empty() and slot.state == 3: # READY
			terrain_display.harvest_slot(slot)
			output_buffer = { "type": "cactus", "amount": 1 }
			print("🤖 Harvester: Collected Cactus")

func _find_slot_at(pos: Vector3) -> Dictionary:
	# This is a bit hacky, ideally TerrainBonusDisplay would have a spatial lookup
	# For now, we iterate (slow but works for small scale)
	var all_slots = terrain_display.get_all_slots()
	for slot in all_slots:
		if slot.node.global_position.distance_to(pos) < 1.5:
			return slot
	return {}
