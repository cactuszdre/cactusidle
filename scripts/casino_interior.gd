extends Node3D

@onready var teleport_manager = get_node("/root/Main/TeleportManager")
@onready var exit_prompt = $ExitPrompt

var is_player_near_exit: bool = false

func _ready() -> void:
	if teleport_manager:
		teleport_manager.interior_spawn_point = $SpawnPoint
		
	$ExitArea.body_entered.connect(_on_exit_entered)
	$ExitArea.body_exited.connect(_on_exit_exited)
	exit_prompt.visible = false

func _process(_delta: float) -> void:
	if is_player_near_exit and Input.is_action_just_pressed("interact"): # Assuming 'interact' is E, or check KEY_E
		_exit_casino()
	elif is_player_near_exit and Input.is_key_pressed(KEY_E):
		_exit_casino()

func _exit_casino() -> void:
	if teleport_manager:
		teleport_manager.teleport_to_exterior()

func _on_exit_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		is_player_near_exit = true
		exit_prompt.visible = true

func _on_exit_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		is_player_near_exit = false
		exit_prompt.visible = false
