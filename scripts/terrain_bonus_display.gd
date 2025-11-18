extends Node3D

@export var anchors_root: NodePath
@export var podium_height: float = 0.25

var _anchors: Array[Node3D] = []
var _next_index: int = 0
var _podium_material: StandardMaterial3D
var _crystal_materials: Dictionary = {}

func _ready() -> void:
	_podium_material = _build_podium_material()
	_cache_anchors()

func show_bonus(option_name: String, description: String) -> void:
	if _anchors.is_empty():
		return
	var anchor := _anchors[_next_index % _anchors.size()]
	_next_index += 1
	_spawn_bonus_visual(anchor, option_name, description)

func _cache_anchors() -> void:
	_anchors.clear()
	if anchors_root.is_empty():
		return
	var root := get_node_or_null(anchors_root)
	if root:
		for child in root.get_children():
			if child is Node3D:
				_anchors.append(child)

func _spawn_bonus_visual(anchor: Node3D, option_name: String, description: String) -> void:
	for child in anchor.get_children():
		child.queue_free()
	
	var podium := _create_podium()
	anchor.add_child(podium)
	
	var crystal := _create_crystal(option_name)
	anchor.add_child(crystal)
	
	var label := _create_label(option_name, description)
	anchor.add_child(label)
	
	var light := _create_light(option_name)
	anchor.add_child(light)

func _create_podium() -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.6
	mesh.bottom_radius = 0.6
	mesh.height = podium_height
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _podium_material
	mesh_instance.position = Vector3(0, podium_height * 0.5, 0)
	return mesh_instance

func _create_crystal(option_name: String) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.35
	mesh_instance.mesh = mesh
	mesh_instance.position = Vector3(0, podium_height + 0.45, 0)
	mesh_instance.scale = Vector3(0.8, 1.2, 0.8)
	mesh_instance.material_override = _get_crystal_material(option_name)
	return mesh_instance

func _create_label(option_name: String, description: String) -> Label3D:
	var label := Label3D.new()
	label.text = _format_bonus_text(option_name, description)
	label.position = Vector3(0, podium_height + 1.1, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(0.95, 0.85, 0.6, 1)
	label.outline_modulate = Color(0, 0, 0, 0.7)
	label.outline_size = 6
	label.font_size = 42
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label

func _create_light(option_name: String) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.light_energy = 1.6
	light.light_color = _get_color_for(option_name)
	light.shadow_enabled = false
	light.omni_range = 5.0
	light.position = Vector3(0, podium_height + 0.3, 0)
	return light

func _format_bonus_text(option_name: String, description: String) -> String:
	return "%s\n%s" % [option_name, description]

func _build_podium_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.18, 0.12, 1)
	mat.metallic = 0.1
	mat.roughness = 0.8
	mat.clearcoat = 0.3
	return mat

func _get_crystal_material(option_name: String) -> StandardMaterial3D:
	if _crystal_materials.has(option_name):
		return _crystal_materials[option_name]
	var mat := StandardMaterial3D.new()
	var color := _get_color_for(option_name)
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color * 1.5
	mat.emission_energy = 1.2
	mat.metallic = 0.2
	mat.roughness = 0.25
	_crystal_materials[option_name] = mat
	return mat

func _get_color_for(option_name: String) -> Color:
	match option_name:
		"SmallPlot":
			return Color(0.35, 0.85, 0.55, 1)
		"LargePlot":
			return Color(0.95, 0.65, 0.25, 1)
		_:
			return Color(0.7, 0.8, 1.0, 1)
