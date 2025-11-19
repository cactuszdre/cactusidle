extends Area3D

signal player_entered_aura
signal player_exited_aura

var player_in_aura: bool = false

# Shader setup
const CACTUS_SHADER = preload("res://shaders/realistic_cactus.gdshader")

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_apply_shader_to_model()

func _apply_shader_to_model():
	# Find the model node
	var model_root = get_node_or_null("../CactusBody/CactusModel")
	if model_root:
		_apply_shader_recursive(model_root)

func _apply_shader_recursive(node: Node):
	if node is MeshInstance3D:
		var material = ShaderMaterial.new()
		material.shader = CACTUS_SHADER
		# Customize parameters if needed
		material.set_shader_parameter("cactus_color", Color(0.2, 0.6, 0.3))
		material.set_shader_parameter("noise_scale", 15.0)
		
		# Apply to geometry
		node.material_override = material
		
	for child in node.get_children():
		_apply_shader_recursive(child)

func _on_body_entered(body):
	if body.is_in_group("Player") or body.name == "Player":
		player_in_aura = true
		player_entered_aura.emit()
		print("✅ Joueur dans l'aura ! Gain de cactus activé !")

func _on_body_exited(body):
	if body.is_in_group("Player") or body.name == "Player":
		player_in_aura = false
		player_exited_aura.emit()
		print("❌ Joueur sorti de l'aura ! Gain de cactus désactivé !")
