extends Node3D

@export var spin_cost: int = 50
@onready var game_manager = get_node_or_null("/root/Main/GameManager")
@onready var screen_mesh = $Body/Screen
@onready var label = $Body/Label3D
@onready var particles = $Body/WinParticles
@onready var lever = $Body/Lever
@onready var chair = $Chair
@onready var sit_area = $Chair/SitArea
@onready var sit_position = $Chair/SitPosition

var is_spinning: bool = false
var is_player_seated: bool = false
var player_ref = null
var original_player_transform: Transform3D
var original_player_rotation: Vector3
var original_camera_pivot_rotation: Vector3
var original_camera_rotation: Vector3
var original_spring_length: float
var can_sit: bool = false
var sit_prompt: Label3D

func _ready():
	sit_area.body_entered.connect(_on_sit_area_entered)
	sit_area.body_exited.connect(_on_sit_area_exited)
	
	# Create sit prompt
	sit_prompt = Label3D.new()
	sit_prompt.text = "[E] S'asseoir"
	sit_prompt.font_size = 24
	sit_prompt.outline_size = 4
	sit_prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sit_prompt.visible = false
	chair.add_child(sit_prompt)
	sit_prompt.position = Vector3(0, 1.5, 0)
	
	_reset()

func _process(_delta):
	# Sit/Unsit interaction
	if can_sit and not is_player_seated and Input.is_key_pressed(KEY_E):
		_sit_player()
	elif is_player_seated and Input.is_key_pressed(KEY_F): # F to stand up
		_unsit_player()
	
	# Lever interaction via raycast when seated
	if is_player_seated and not is_spinning:
		_check_lever_raycast()

func _check_lever_raycast():
	if not player_ref:
		return
	
	# Get camera from proper path
	var camera_pivot = player_ref.get_node_or_null("CameraPivot")
	var spring_arm = null
	var camera = null
	
	if camera_pivot:
		spring_arm = camera_pivot.get_node_or_null("SpringArm3D")
		if spring_arm:
			camera = spring_arm.get_node_or_null("Camera3D")
	
	if not camera:
		return
	
	# Raycast from camera
	var space_state = get_world_3d().direct_space_state
	var from = camera.global_position
	var to = from + (-camera.global_transform.basis.z * 3.0) # 3 meters forward
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	
	if result and result.collider == $Body/Lever/LeverCollider:
		# Looking at lever
		label.text = "[E] Tirer le levier\n" + str(spin_cost) + " 🌵"
		label.modulate = Color.YELLOW
		
		if Input.is_key_pressed(KEY_E):
			_pull_lever()
	else:
		# Not looking at lever
		if not is_spinning:
			label.text = "Regardez le levier\n[F] Se lever"
			label.modulate = Color.WHITE

func _on_sit_area_entered(body):
	if body.is_in_group("Player") and not is_player_seated:
		can_sit = true
		sit_prompt.visible = true

func _on_sit_area_exited(body):
	if body.is_in_group("Player"):
		can_sit = false
		sit_prompt.visible = false

func _sit_player():
	if not player_ref and can_sit:
		var player = get_tree().get_first_node_in_group("Player")
		if not player:
			return
		
		player_ref = player
		is_player_seated = true
		can_sit = false
		sit_prompt.visible = false
		
		# Save original transforms
		original_player_transform = player.global_transform
		original_player_rotation = player.rotation
		
		# Get camera components
		var camera_pivot = player.get_node_or_null("CameraPivot")
		var spring_arm = null
		var camera = null
		
		if camera_pivot:
			original_camera_pivot_rotation = camera_pivot.rotation
			spring_arm = camera_pivot.get_node_or_null("SpringArm3D")
			if spring_arm:
				original_spring_length = spring_arm.spring_length
				camera = spring_arm.get_node_or_null("Camera3D")
				if camera:
					original_camera_rotation = camera.rotation
		
		# Disable player movement
		player.can_move = false
		
		# Smooth transition to sit position
		var sit_target = sit_position.global_transform
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(player, "global_position", sit_target.origin, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		
		if camera and spring_arm:
			await get_tree().create_timer(0.3).timeout
			
			# Switch to first person by reducing spring arm length
			var arm_tween = create_tween()
			arm_tween.tween_property(spring_arm, "spring_length", 0.0, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
			
			# Point camera at screen
			await arm_tween.finished
			
			# Reset camera local rotation to zero for first-person view
			var cam_tween = create_tween()
			cam_tween.tween_property(camera, "rotation", Vector3.ZERO, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
			
			# Hide player model
			var player_model = player.get_node_or_null("PlayerModel")
			if player_model:
				player_model.visible = false
		
		print("🪑 Assis ! Regardez le levier et appuyez sur E pour jouer. [F] pour se lever.")
		label.text = "Regardez le levier\n[F] Se lever"

func _unsit_player():
	if not is_player_seated or not player_ref:
		return
	
	# Get camera components
	var camera_pivot = player_ref.get_node_or_null("CameraPivot")
	var spring_arm = null
	var camera = null
	
	if camera_pivot:
		spring_arm = camera_pivot.get_node_or_null("SpringArm3D")
		if spring_arm:
			camera = spring_arm.get_node_or_null("Camera3D")
	
	# Show player model first
	var player_model = player_ref.get_node_or_null("PlayerModel")
	if player_model:
		player_model.visible = true
	
	# Restore camera rotation to original state
	if camera:
		var cam_tween = create_tween()
		cam_tween.tween_property(camera, "rotation", original_camera_rotation, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		await cam_tween.finished
	
	# Restore spring arm length
	if spring_arm:
		var arm_tween = create_tween()
		arm_tween.tween_property(spring_arm, "spring_length", original_spring_length, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	# Restore camera pivot rotation
	if camera_pivot:
		var pivot_tween = create_tween()
		pivot_tween.tween_property(camera_pivot, "rotation", original_camera_pivot_rotation, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	# Restore player transform and rotation
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(player_ref, "global_transform", original_player_transform, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(player_ref, "rotation", original_player_rotation, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	await tween.finished
	
	# Update player's yaw and pitch to match restored rotation
	if player_ref and is_instance_valid(player_ref):
		player_ref.yaw = original_player_rotation.y
		player_ref.pitch = original_camera_pivot_rotation.x
		player_ref.can_move = true
	
	is_player_seated = false
	player_ref = null
	print("🚶 Debout !")
	_reset()

func _pull_lever():
	if is_spinning:
		return
	
	if game_manager and game_manager.cactus_count >= spin_cost:
		game_manager.add_cactus(-spin_cost)
		_spin()
	else:
		label.text = "Pas assez de cactus !"
		label.modulate = Color.RED
		await get_tree().create_timer(1.0).timeout
		label.text = "Regardez le levier\n[F] Se lever"
		label.modulate = Color.WHITE

func _spin():
	is_spinning = true
	label.text = "..."
	label.modulate = Color.WHITE
	
	# Animate lever
	var tween = create_tween()
	tween.tween_property(lever, "rotation_degrees:x", -45, 0.2)
	tween.tween_property(lever, "rotation_degrees:x", 0, 0.3)
	
	# Visual spin effect
	for i in range(10):
		var random_color = Color(randf(), randf(), randf())
		_set_screen_color(random_color)
		await get_tree().create_timer(0.1).timeout
	
	# Result
	var roll = randf()
	if roll > 0.95: # Jackpot
		_win(500, Color.GOLD, "JACKPOT !!")
	elif roll > 0.6: # Win
		_win(100, Color.GREEN, "GAGNÉ !")
	else: # Loss
		_set_screen_color(Color.RED)
		label.text = "PERDU..."
		await get_tree().create_timer(1.0).timeout
		is_spinning = false
		label.text = "Regardez le levier\n[F] Se lever"
		label.modulate = Color.WHITE

func _win(amount: int, color: Color, text: String):
	_set_screen_color(color)
	label.text = text + "\n+" + str(amount)
	if game_manager:
		game_manager.add_cactus(amount)
	
	if particles:
		particles.emitting = true
		
	await get_tree().create_timer(2.0).timeout
	is_spinning = false
	label.text = "Regardez le levier\n[F] Se lever"
	label.modulate = Color.WHITE

func _reset():
	is_spinning = false
	_set_screen_color(Color(0.2, 0.2, 0.2))
	label.text = "JOUER\n" + str(spin_cost) + " 🌵"
	label.modulate = Color.WHITE

func _set_screen_color(col: Color):
	var mat = screen_mesh.get_active_material(0)
	if mat:
		mat.albedo_color = col
		mat.emission = col
