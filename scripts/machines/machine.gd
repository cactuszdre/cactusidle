extends Node3D

class_name Machine

# Properties
var grid_pos: Vector2i
var rotation_dir: int = 0 # 0: North (-Z), 1: East (+X), 2: South (+Z), 3: West (-X)

# References
var factory_manager: FactoryManager

func setup(pos: Vector2i, rot: int) -> void:
	grid_pos = pos
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

# Helper to get the grid position "in front" based on rotation
func get_output_pos() -> Vector2i:
	var dir = Vector2i.ZERO
	match rotation_dir:
		0: dir = Vector2i(0, -1) # North
		1: dir = Vector2i(1, 0)  # East
		2: dir = Vector2i(0, 1)  # South
		3: dir = Vector2i(-1, 0) # West
	return grid_pos + dir

# Helper to get the grid position "behind" (input)
func get_input_pos() -> Vector2i:
	var dir = Vector2i.ZERO
	match rotation_dir:
		0: dir = Vector2i(0, 1)  # South is behind North
		1: dir = Vector2i(-1, 0) # West is behind East
		2: dir = Vector2i(0, -1) # North is behind South
		3: dir = Vector2i(1, 0)  # East is behind West
	return grid_pos + dir
