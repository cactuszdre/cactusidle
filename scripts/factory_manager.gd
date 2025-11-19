extends Node

class_name FactoryManager

# Storage: List of Machine instances
var machines: Array[Node] = []

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
	# Iterate backwards to allow safe removal if needed
	for i in range(machines.size() - 1, -1, -1):
		var machine = machines[i]
		if is_instance_valid(machine):
			if machine.has_method("tick"):
				machine.tick(TICK_RATE)
		else:
			machines.remove_at(i)

func place_machine(machine_scene: PackedScene, position: Vector3, rotation_dir: int) -> bool:
	# Collision check should be done by BuilderController before calling this
	
	var machine_instance = machine_scene.instantiate()
	add_child(machine_instance)
	
	machine_instance.global_position = position
	# We might need to adjust setup to not rely on grid pos if it uses it
	if machine_instance.has_method("setup"):
		# Passing Vector2i.ZERO as dummy grid pos if needed, or update machine scripts
		machine_instance.setup(Vector2i.ZERO, rotation_dir) 
	
	machines.append(machine_instance)
	return true

func remove_machine_at(position: Vector3, radius: float = 1.0) -> void:
	var closest_machine = null
	var min_dist = radius
	
	for machine in machines:
		if is_instance_valid(machine):
			var dist = machine.global_position.distance_to(position)
			if dist < min_dist:
				min_dist = dist
				closest_machine = machine
	
	if closest_machine:
		machines.erase(closest_machine)
		closest_machine.queue_free()

func get_machines_of_type(type_name: String) -> Array:
	var result = []
	for machine in machines:
		if is_instance_valid(machine) and machine.name.begins_with(type_name): # Simple check, or use is_class/groups
			result.append(machine)
	return result

func get_all_machines() -> Array:
	return machines

func get_closest_machine(position: Vector3, radius: float = 1.5) -> Node:
	var closest_machine = null
	var min_dist = radius
	
	for machine in machines:
		if is_instance_valid(machine):
			var dist = machine.global_position.distance_to(position)
			if dist < min_dist:
				min_dist = dist
				closest_machine = machine
	return closest_machine

