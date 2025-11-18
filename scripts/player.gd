extends CharacterBody3D

const MOVE_SPEED := 6.0
const ACCELERATION := 12.0
const AIR_CONTROL := 0.35
const GRAVITY := 22.0
const JUMP_SPEED := 10.0
var mouse_sensitivity: float = 0.005

const SPRINT_SPEED := 12.0

@onready var cam_pivot: Node3D = $CameraPivot

var yaw := 0.0
var pitch := 0.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	yaw = rotation.y
	pitch = cam_pivot.rotation.x
	cam_pivot.rotation = Vector3(pitch, 0.0, 0.0)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * mouse_sensitivity
		pitch = clamp(pitch - event.relative.y * mouse_sensitivity, -1.2, 1.2)
		rotation.y = yaw
		cam_pivot.rotation = Vector3(pitch, 0.0, 0.0)

func _physics_process(delta: float) -> void:
	var input_vector := _get_input_vector()
	var desired_velocity := _compute_desired_velocity(input_vector)
	var accel := ACCELERATION if is_on_floor() else ACCELERATION * AIR_CONTROL

	velocity.x = lerp(velocity.x, desired_velocity.x, accel * delta)
	velocity.z = lerp(velocity.z, desired_velocity.z, accel * delta)

	if is_on_floor():
		if Input.is_action_just_pressed("ui_accept"):
			velocity.y = JUMP_SPEED
		else:
			velocity.y = min(velocity.y, -0.1)
	else:
		velocity.y -= GRAVITY * delta

	move_and_slide()

func _get_input_vector() -> Vector2:
	var input_vector := Vector2.ZERO
	input_vector.x = Input.get_action_strength("aller_droite") - Input.get_action_strength("aller_gauche")
	input_vector.y = Input.get_action_strength("avancer") - Input.get_action_strength("reculer")
	return input_vector.normalized() if input_vector.length_squared() > 1.0 else input_vector

func _compute_desired_velocity(input_vector: Vector2) -> Vector3:
	if input_vector == Vector2.ZERO:
		return Vector3.ZERO

	var current_speed := MOVE_SPEED
	if Input.is_key_pressed(KEY_SHIFT):
		current_speed = SPRINT_SPEED

	var forward := -transform.basis.z
	var right := transform.basis.x
	var move_direction := (forward * input_vector.y + right * input_vector.x).normalized()
	return move_direction * current_speed
