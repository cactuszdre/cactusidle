extends Node

var player: Node3D = null
var exterior_spawn_point: Node3D = null
var interior_spawn_point: Node3D = null

func _ready() -> void:
	# Wait for the player to be ready
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("Player")

func teleport_to_interior() -> void:
	if player and interior_spawn_point:
		player.global_position = interior_spawn_point.global_position
		player.global_rotation = interior_spawn_point.global_rotation
		# Reset velocity if possible to prevent flying out
		if player.has_method("set_velocity"):
			player.velocity = Vector3.ZERO

func teleport_to_exterior() -> void:
	if player and exterior_spawn_point:
		player.global_position = exterior_spawn_point.global_position
		player.global_rotation = exterior_spawn_point.global_rotation
		if player.has_method("set_velocity"):
			player.velocity = Vector3.ZERO
