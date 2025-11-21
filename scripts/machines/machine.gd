extends Node3D

class_name Machine

# Properties
var rotation_dir: int = 0 # 0: North (-Z), 1: East (+X), 2: South (+Z), 3: West (-X)

# References
var factory_manager: FactoryManager

func setup(_dummy_pos: Vector2i, rot: int) -> void:
	# _dummy_pos is ignored, kept for compatibility if needed or removed
	rotation_dir = rot
	factory_manager = get_parent() as FactoryManager
	
	# Visual rotation
	rotation_degrees.y = -90 * rot

func tick(_delta: float) -> void:
	pass

func can_accept_item(_item: Dictionary, _from_dir: int) -> bool:
	return false

func inject_item(_item: Dictionary) -> void:
	pass

# Helper to get the world position "in front" based on rotation
func get_output_world_pos() -> Vector3:
	var dir = Vector3.ZERO
	match rotation_dir:
		0: dir = Vector3(0, 0, -1) # North
		1: dir = Vector3(1, 0, 0)  # East
		2: dir = Vector3(0, 0, 1)  # South
		3: dir = Vector3(-1, 0, 0) # West
	
	# Assuming standard spacing of 2.0 units
	return global_position + (dir * 2.0)

# Helper to get the world position "behind" (input)
func get_input_world_pos() -> Vector3:
	var dir = Vector3.ZERO
	match rotation_dir:
		0: dir = Vector3(0, 0, 1)  # South is behind North
		1: dir = Vector3(-1, 0, 0) # West is behind East
		2: dir = Vector3(0, 0, -1) # North is behind South
		3: dir = Vector3(1, 0, 0)  # East is behind West
	
	return global_position + (dir * 2.0)
