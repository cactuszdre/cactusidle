extends Node3D

@onready var game_manager = get_node_or_null("/root/Main/GameManager")
@onready var terrain_display = get_node_or_null("/root/Main/TerrainBonusDisplay")

enum State { IDLE, MOVING, WORKING }
var current_state: State = State.IDLE

var target_slot: Dictionary = {}
var move_speed: float = 5.0
var work_timer: float = 0.0
const WORK_DURATION: float = 1.0

func _process(delta: float) -> void:
	if not game_manager or not game_manager.has_farmer:
		visible = false
		return
	
	visible = true
	
	match current_state:
		State.IDLE:
			_find_new_task()
		State.MOVING:
			_move_to_target(delta)
		State.WORKING:
			_perform_work(delta)

func _find_new_task() -> void:
	if not terrain_display: return
	
	var all_slots = terrain_display.get_all_slots()
	if all_slots.is_empty(): return
	
	# Priority 1: Harvest (Find closest ready slot)
	var best_slot = {}
	var min_dist = INF
	
	for slot in all_slots:
		if slot.state == terrain_display.SlotState.READY:
			var dist = global_position.distance_to(slot.node.global_position)
			if dist < min_dist:
				min_dist = dist
				best_slot = slot
	
	if not best_slot.is_empty():
		target_slot = best_slot
		current_state = State.MOVING
		return
			
	# Priority 2: Plant (Find closest empty slot)
	if game_manager.cactus_count >= 1:
		min_dist = INF
		for slot in all_slots:
			if slot.state == terrain_display.SlotState.EMPTY:
				var dist = global_position.distance_to(slot.node.global_position)
				if dist < min_dist:
					min_dist = dist
					best_slot = slot
		
		if not best_slot.is_empty():
			target_slot = best_slot
			current_state = State.MOVING
			return

func _move_to_target(delta: float) -> void:
	if target_slot.is_empty() or not is_instance_valid(target_slot.node):
		current_state = State.IDLE
		return
		
	var target_pos = target_slot.node.global_position
	# Keep same height
	target_pos.y = global_position.y
	
	# Rotate to face target
	look_at(target_pos, Vector3.UP)
	
	# Move
	global_position = global_position.move_toward(target_pos, move_speed * delta)
	
	# Check if arrived (within small threshold)
	if global_position.distance_to(target_pos) < 0.1:
		current_state = State.WORKING
		work_timer = 0.0

func _perform_work(delta: float) -> void:
	work_timer += delta
	if work_timer >= WORK_DURATION:
		# Do the actual action
		if target_slot.state == terrain_display.SlotState.READY:
			print("👨‍🌾 Fermier: Récolte terminée !")
			terrain_display.harvest_slot(target_slot)
		elif target_slot.state == terrain_display.SlotState.EMPTY:
			if game_manager.cactus_count >= 1:
				print("👨‍🌾 Fermier: Plantation terminée !")
				terrain_display.plant_slot(target_slot)
		
		current_state = State.IDLE
		target_slot = {}
