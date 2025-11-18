shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_add;

uniform vec4 main_color : source_color = vec4(0.4, 0.95, 0.6, 1.0);
uniform float inner_radius : hint_range(0.0, 20.0, 0.1) = 5.0;
uniform float outer_radius : hint_range(0.1, 25.0, 0.1) = 10.0;
uniform float height : hint_range(0.1, 10.0, 0.1) = 0.5;
uniform float softness : hint_range(0.25, 5.0, 0.05) = 1.5;
uniform float alpha_strength : hint_range(0.0, 1.0, 0.01) = 0.45;
uniform float emission_strength : hint_range(0.0, 5.0, 0.05) = 2.2;
uniform float pulse_speed : hint_range(0.0, 10.0, 0.05) = 1.6;
uniform float pulse_strength : hint_range(0.0, 1.0, 0.01) = 0.25;

varying vec3 local_pos;

void vertex() {
    local_pos = VERTEX;
}

void fragment() {
    float radial = length(local_pos.xz);
    float radial_range = max(0.001, outer_radius - inner_radius);
    float normalized = clamp((radial - inner_radius) / radial_range, 0.0, 1.0);
    float core = pow(1.0 - normalized, softness);

    float half_height = max(0.001, height * 0.5);
    float vertical = 1.0 - clamp(abs(local_pos.y) / half_height, 0.0, 1.0);

    float pulse = 0.5 + 0.5 * sin(TIME * pulse_speed);
    float glow = clamp(core * vertical + pulse * pulse_strength, 0.0, 1.0);

    ALBEDO = main_color.rgb;
    EMISSION = main_color.rgb * glow * emission_strength;
    ALPHA = glow * alpha_strength;
}
