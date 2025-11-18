shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded;

uniform vec4 core_color : source_color = vec4(0.29, 0.93, 0.51, 1.0);
uniform vec4 edge_color : source_color = vec4(0.15, 0.75, 0.95, 1.0);
uniform float glow_intensity : hint_range(0.0, 5.0) = 2.5;
uniform float sparkle_speed : hint_range(0.0, 10.0) = 4.0;
uniform float pulse_frequency : hint_range(0.0, 5.0) = 2.0;
uniform float edge_softness : hint_range(0.0, 1.0) = 0.3;
uniform float distortion_strength : hint_range(0.0, 0.5) = 0.15;

varying float particle_lifetime;

void vertex() {
	// Billboard complet vers la caméra (particles mode)
	vec3 camera_right = normalize(INV_VIEW_MATRIX[0].xyz);
	vec3 camera_up = normalize(INV_VIEW_MATRIX[1].xyz);
	vec3 camera_forward = normalize(INV_VIEW_MATRIX[2].xyz);
	
	mat4 mat_world = mat4(
		vec4(camera_right, 0.0),
		vec4(camera_up, 0.0),
		vec4(camera_forward, 0.0),
		MODEL_MATRIX[3]
	);
	
	float scale_x = length(MODEL_MATRIX[0].xyz);
	float scale_y = length(MODEL_MATRIX[1].xyz);
	float scale_z = length(MODEL_MATRIX[2].xyz);
	
	mat_world = mat_world * mat4(
		vec4(scale_x, 0.0, 0.0, 0.0),
		vec4(0.0, scale_y, 0.0, 0.0),
		vec4(0.0, 0.0, scale_z, 0.0),
		vec4(0.0, 0.0, 0.0, 1.0)
	);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat_world;
	
	// Calculer durée de vie basée sur COLOR.a (vient du gradient)
	particle_lifetime = 1.0 - COLOR.a;
	
	// Légère ondulation pour donner du mouvement
	float wave = sin(TIME * 3.0 + VERTEX.x * 10.0) * distortion_strength;
	VERTEX.x += wave * particle_lifetime;
}

void fragment() {
	// Coordonnées centrées
	vec2 centered_uv = UV - 0.5;
	float dist = length(centered_uv) * 2.0;
	
	// Masque radial avec bord doux
	float radial_mask = 1.0 - smoothstep(1.0 - edge_softness, 1.0, dist);
	
	// Effet de scintillement rotatif
	float angle = atan(centered_uv.y, centered_uv.x);
	float sparkle = sin(angle * 6.0 + TIME * sparkle_speed) * 0.5 + 0.5;
	sparkle = pow(sparkle, 3.0) * 0.4 + 0.6;
	
	// Pulsation basée sur le temps
	float pulse = sin(TIME * pulse_frequency) * 0.15 + 0.85;
	
	// Gradient de couleur du centre vers les bords
	vec3 color = mix(core_color.rgb, edge_color.rgb, dist);
	
	// Anneau brillant au centre
	float center_ring = exp(-dist * 8.0) * 2.0;
	color += center_ring * core_color.rgb;
	
	// Appliquer les effets
	color *= sparkle * pulse;
	
	// Fade basé sur la durée de vie (COLOR.a vient du gradient de particules)
	float alpha = radial_mask * COLOR.a * (1.0 - particle_lifetime * 0.5);
	
	// Sortie finale
	ALBEDO = color;
	EMISSION = color * glow_intensity;
	ALPHA = alpha;
}
