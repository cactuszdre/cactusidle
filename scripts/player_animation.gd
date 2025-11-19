extends Node3D

@onready var shoulder_left: Node3D = $ShoulderLeft
@onready var shoulder_right: Node3D = $ShoulderRight
@onready var elbow_left: Node3D = $ShoulderLeft/ElbowLeft
@onready var elbow_right: Node3D = $ShoulderRight/ElbowRight
@onready var hip_left: Node3D = $HipLeft
@onready var hip_right: Node3D = $HipRight
@onready var knee_left: Node3D = $HipLeft/KneeLeft
@onready var knee_right: Node3D = $HipRight/KneeRight
@onready var head: MeshInstance3D = $Head
@onready var torso: MeshInstance3D = $Torso
@onready var player: CharacterBody3D = get_parent()

var walk_time: float = 0.0
var idle_time: float = 0.0
const WALK_SPEED: float = 6.0
const SWING_AMPLITUDE: float = 0.7

var override_right_arm: bool = false

func _process(delta: float) -> void:
	# Détecter le mouvement
	var velocity_2d := Vector2(player.velocity.x, player.velocity.z)
	var speed := velocity_2d.length()
	var is_on_floor := player.is_on_floor()
	var planar_velocity := Vector3(player.velocity.x, 0.0, player.velocity.z)
	
	if speed > 0.1 and is_on_floor:
		# Le joueur marche
		walk_time += delta * WALK_SPEED * (speed / 5.0)
		idle_time = 0.0
		
		# Balancement des bras avec articulation
		var arm_swing := sin(walk_time) * SWING_AMPLITUDE
		shoulder_left.rotation.x = arm_swing
		elbow_left.rotation.x = max(0, -arm_swing * 0.5)
		
		if not override_right_arm:
			shoulder_right.rotation.x = -arm_swing
			elbow_right.rotation.x = max(0, arm_swing * 0.5)
		
		# Balancement des jambes avec articulation
		var leg_swing := sin(walk_time) * 0.6
		hip_left.rotation.x = -leg_swing
		knee_left.rotation.x = max(0, leg_swing * 0.8)
		
		hip_right.rotation.x = leg_swing
		knee_right.rotation.x = max(0, -leg_swing * 0.8)
		
		# Head bob
		var head_bob := sin(walk_time * 2.0) * 0.05
		head.position.y = 1.8 + head_bob
		
		# Corps penché légèrement en avant
		rotation.x = lerp(rotation.x, -0.1, delta * 3.0)
		
	elif not is_on_floor:
		# Animation de saut/chute
		# Bras vers le haut
		shoulder_left.rotation.x = lerp(shoulder_left.rotation.x, -1.5, delta * 10.0)
		elbow_left.rotation.x = lerp(elbow_left.rotation.x, 0.3, delta * 10.0)
		
		if not override_right_arm:
			shoulder_right.rotation.x = lerp(shoulder_right.rotation.x, -1.5, delta * 10.0)
			elbow_right.rotation.x = lerp(elbow_right.rotation.x, 0.3, delta * 10.0)
		
		# Jambes ensemble
		hip_left.rotation.x = lerp(hip_left.rotation.x, 0.3, delta * 10.0)
		knee_left.rotation.x = lerp(knee_left.rotation.x, 0.0, delta * 10.0)
		
		hip_right.rotation.x = lerp(hip_right.rotation.x, 0.3, delta * 10.0)
		knee_right.rotation.x = lerp(knee_right.rotation.x, 0.0, delta * 10.0)
		
		rotation.x = lerp(rotation.x, 0.0, delta * 3.0)
		
	else:
		# Le joueur est immobile - animation de respiration
		idle_time += delta
		
		var breathe := sin(idle_time * 2.0) * 0.02
		torso.scale.y = 1.0 + breathe
		head.position.y = 1.8 + breathe * 0.5
		
		# Retour progressif à la position neutre
		shoulder_left.rotation.x = lerp(shoulder_left.rotation.x, 0.2, delta * 5.0)
		elbow_left.rotation.x = lerp(elbow_left.rotation.x, 0.0, delta * 5.0)
		
		if not override_right_arm:
			shoulder_right.rotation.x = lerp(shoulder_right.rotation.x, 0.2, delta * 5.0)
			elbow_right.rotation.x = lerp(elbow_right.rotation.x, 0.0, delta * 5.0)
		
		hip_left.rotation.x = lerp(hip_left.rotation.x, 0.0, delta * 5.0)
		knee_left.rotation.x = lerp(knee_left.rotation.x, 0.0, delta * 5.0)
		
		hip_right.rotation.x = lerp(hip_right.rotation.x, 0.0, delta * 5.0)
		knee_right.rotation.x = lerp(knee_right.rotation.x, 0.0, delta * 5.0)
		
		rotation.x = lerp(rotation.x, 0.0, delta * 3.0)
		walk_time = 0.0
	
	# Légère inclinaison latérale basée sur la vitesse actuelle
	var forward := (-player.transform.basis.z).normalized()
	var side := forward.cross(Vector3.UP)
	if side.length() > 0.001:
		side = side.normalized()
	else:
		side = Vector3.RIGHT
	var lean := 0.0
	if planar_velocity.length() > 0.2:
		lean = clamp(side.dot(planar_velocity.normalized()), -1.0, 1.0) * 0.25
	rotation.z = lerp(rotation.z, lean, delta * 4.0)

	# Note: La rotation Y est gérée par player.gd maintenant
