shader_type canvas_item;

uniform vec4 bg_color : source_color = vec4(0.12, 0.1, 0.08, 0.95);
uniform vec4 accent_color : source_color = vec4(0.85, 0.65, 0.25, 1.0);
uniform float border_width : hint_range(0.0, 0.05) = 0.008;
uniform float glow_intensity : hint_range(0.0, 2.0) = 0.6;
uniform float pattern_scale : hint_range(1.0, 20.0) = 8.0;

void fragment() {
	vec2 uv = UV;
	
	// Distance du bord
	vec2 dist = min(uv, 1.0 - uv);
	float edge_dist = min(dist.x, dist.y);
	
	// Bordure dorée brillante
	float border = smoothstep(border_width - 0.002, border_width, edge_dist);
	vec3 border_glow = accent_color.rgb * (1.0 - border) * glow_intensity;
	
	// Motif de sable subtil
	float pattern = fract(sin(dot(uv * pattern_scale, vec2(12.9898, 78.233))) * 43758.5453);
	pattern = pattern * 0.08 + 0.92;
	
	// Gradient radial depuis le centre
	vec2 center_uv = uv * 2.0 - 1.0;
	float radial = length(center_uv);
	float gradient = smoothstep(1.4, 0.2, radial) * 0.15;
	
	// Combinaison finale
	vec3 bg = bg_color.rgb * pattern + gradient;
	vec3 final_color = mix(accent_color.rgb, bg, border);
	final_color += border_glow;
	
	COLOR = vec4(final_color, bg_color.a);
}
