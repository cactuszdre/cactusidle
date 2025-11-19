extends Machine

class_name ConveyorBelt

var held_item: Dictionary = {}
var progress: float = 0.0

func tick(_delta: float) -> void:
	if held_item.is_empty():
		return
		
	# Try to move item to next machine
	var target_pos = get_output_world_pos()
	var target_machine = factory_manager.get_closest_machine(target_pos)
	
	if target_machine and target_machine.can_accept_item(held_item, (rotation_dir + 2) % 4):
		target_machine.inject_item(held_item)
		held_item = {}
		progress = 0.0
		_update_visuals()
	else:
		# Stuck
		pass

func can_accept_item(_item: Dictionary, _from_dir: int) -> bool:
	return held_item.is_empty()

func inject_item(item: Dictionary) -> void:
	held_item = item
	progress = 0.0
	_update_visuals()

func _update_visuals() -> void:
	# TODO: Add visual representation of item on belt
	pass
