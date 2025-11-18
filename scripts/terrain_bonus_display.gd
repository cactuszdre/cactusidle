extends Node3D

@export var fields_root: NodePath
@export var label_node_name: String = "Label"

var _fields: Dictionary = {}

func _ready() -> void:
	_cache_fields()
	_set_all_visible(false)

func show_bonus(option_name: String, description: String, field_type: String = "") -> void:
	if _fields.is_empty():
		_cache_fields()
	var field: Node3D = _fields.get(option_name, null)
	if field == null:
		return
	field.visible = true
	_apply_description(field, description)

func _cache_fields() -> void:
	_fields.clear()
	if fields_root.is_empty():
		return
	var root := get_node_or_null(fields_root)
	if root:
		for child in root.get_children():
			if child is Node3D:
				_fields[child.name] = child

func _set_all_visible(state: bool) -> void:
	for field in _fields.values():
		field.visible = state

func _apply_description(field: Node3D, description: String) -> void:
	if description.is_empty() or label_node_name.is_empty():
		return
	if field.has_node(label_node_name):
		var label := field.get_node(label_node_name)
		if label is Label3D:
			label.text = description
