shader_type spatial;

uniform vec3 cactus_color : source_color = vec3(0.2, 0.5, 0.2);
uniform vec3 thorn_color : source_color = vec3(0.8, 0.8, 0.6);
uniform float roughness : hint_range(0.0, 1.0) = 0.4;
uniform float rim_power : hint_range(0.0, 10.0) = 3.0;
uniform float rim_intensity : hint_range(0.0, 1.0) = 0.5;
uniform float noise_scale = 20.0;

// Simple noise function
float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

void fragment() {
    // Base color with some noise for texture
    float noise = random(UV * noise_scale);
    vec3 base_col = cactus_color * (0.9 + 0.2 * noise);
    
    ALBEDO = base_col;
    ROUGHNESS = roughness;
    
    // Rim lighting for "fleshy" look
    float rim = 1.0 - dot(VIEW, NORMAL);
    rim = pow(rim, rim_power);
    EMISSION = cactus_color * rim * rim_intensity;
}
