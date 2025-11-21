extends Area3D

@export var target_scene_path: String = "res://scenes/casino.tscn"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		call_deferred("_change_scene")

func _change_scene() -> void:
	get_tree().change_scene_to_file(target_scene_path)
