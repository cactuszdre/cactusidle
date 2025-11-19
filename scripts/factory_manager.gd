extends Node

class_name FactoryManager

# Grid Configuration
const CELL_SIZE: float = 2.0
const GRID_SIZE: int = 100

# Storage: Vector2i -> Machine
var grid: Dictionary = {}

# Tick System
var tick_timer: float = 0.0
const TICK_RATE: float = 0.5 # 2 ticks per second

@onready var game_manager = get_node("/root/Main/GameManager")

func _process(delta: float) -> void:
	tick_timer += delta
	if tick_timer >= TICK_RATE:
		tick_timer -= TICK_RATE
		_tick_machines()

func _tick_machines() -> void:
	# We duplicate keys to avoid issues if machines are removed during iteration
	var coords = grid.keys()
	for coord in coords:
		if grid.has(coord):
			var machine = grid[coord]
			if is_instance_valid(machine):
				machine.tick(TICK_RATE)
			else:
				grid.erase(coord)

func place_machine(machine_scene: PackedScene, grid_pos: Vector2i, rotation_dir: int) -> bool:
	if grid.has(grid_pos):
		return false # Occupied
		
	var machine_instance = machine_scene.instantiate()
	add_child(machine_instance)
	
	machine_instance.global_position = grid_to_world(grid_pos)
	machine_instance.setup(grid_pos, rotation_dir)
	
	grid[grid_pos] = machine_instance
	return true

func remove_machine(grid_pos: Vector2i) -> void:
	if grid.has(grid_pos):
		var machine = grid[grid_pos]
		if is_instance_valid(machine):
			machine.queue_free()
		grid.erase(grid_pos)

func get_machine_at(grid_pos: Vector2i) -> Node:
	return grid.get(grid_pos)

func grid_to_world(grid_pos: Vector2i) -> Vector3:
	return Vector3(grid_pos.x * CELL_SIZE, 0, grid_pos.y * CELL_SIZE)

func world_to_grid(world_pos: Vector3) -> Vector2i:
	return Vector2i(round(world_pos.x / CELL_SIZE), round(world_pos.z / CELL_SIZE))
