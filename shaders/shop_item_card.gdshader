shader_type canvas_item;

uniform vec4 card_color : source_color = vec4(0.18, 0.16, 0.14, 0.92);
uniform vec4 highlight_color : source_color = vec4(0.75, 0.55, 0.25, 1.0);
uniform float hover_strength : hint_range(0.0, 1.0) = 0.0;
uniform float corner_radius : hint_range(0.0, 0.1) = 0.02;

float rounded_box(vec2 uv, vec2 size, float radius) {
	vec2 d = abs(uv - 0.5) * 2.0 - size + vec2(radius * 2.0);
	return length(max(d, 0.0)) - radius;
}

void fragment() {
	vec2 uv = UV;
	
	// Boîte arrondie
	float box = rounded_box(uv, vec2(0.98, 0.96), corner_radius);
	float mask = smoothstep(0.002, -0.001, box);
	
	// Effet de survol
	vec3 base_color = mix(card_color.rgb, highlight_color.rgb * 0.3, hover_strength * 0.25);
	
	// Bordure subtile
	float border = smoothstep(-0.001, -0.004, box);
	vec3 border_color = mix(base_color, highlight_color.rgb, border * 0.4);
	
	// Gradient léger de haut en bas
	float gradient = smoothstep(0.0, 0.8, uv.y) * 0.06;
	border_color += gradient;
	
	COLOR = vec4(border_color, mask * card_color.a);
}
