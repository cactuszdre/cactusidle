extends CharacterBody3D

const SPEED = 5.0
const GRAVITY = 20.0
const JUMP_SPEED = 10.0

@onready var cam_pivot = $CameraPivot
@onready var cam = $CameraPivot/SpringArm3D/Camera3D  # ou $CameraPivot/SpringArm3D/Camera3D si vous avez un SpringArm

var mouse_sensitivity = 0.005
var rotation_x = 0.0
var rotation_y = 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	# Échapper pour libérer la souris
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Rotation de la caméra avec la souris
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation_y -= event.relative.x * mouse_sensitivity
		rotation_x -= event.relative.y * mouse_sensitivity
		rotation_x = clamp(rotation_x, -1.2, 1.2)
		cam_pivot.rotation.x = rotation_x
		rotation.y = rotation_y

func _physics_process(delta):
	var input_dir = Vector3.ZERO
	
	# Utiliser VOS actions personnalisées (ZQSD)
	if Input.is_action_pressed("avancer"):
		input_dir.z -= 1
	if Input.is_action_pressed("reculer"):
		input_dir.z += 1
	if Input.is_action_pressed("aller_gauche"):
		input_dir.x -= 1
	if Input.is_action_pressed("aller_droite"):
		input_dir.x += 1
	
	# Calcul de la direction basée sur la caméra
	if input_dir != Vector3.ZERO:
		var cam_transform = cam_pivot.global_transform
		var cam_forward = -cam_transform.basis.z
		var cam_right = cam_transform.basis.x
		
		# Ignorer la composante verticale
		cam_forward.y = 0
		cam_right.y = 0
		cam_forward = cam_forward.normalized()
		cam_right = cam_right.normalized()
		
		# Direction mondiale
		var direction = (cam_forward * -input_dir.z + cam_right * input_dir.x).normalized()
		
		# Appliquer la vitesse
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		# Ralentissement
		velocity.x = lerp(velocity.x, 0.0, 0.2)
		velocity.z = lerp(velocity.z, 0.0, 0.2)
	
	# Gravité et saut
	if is_on_floor():
		if Input.is_action_just_pressed("ui_accept"):
			velocity.y = JUMP_SPEED
	else:
		velocity.y -= GRAVITY * delta
	
	move_and_slide()
