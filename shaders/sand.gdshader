shader_type spatial;

uniform vec3 sand_color : source_color = vec3(0.76, 0.69, 0.5);
uniform float grain_amount : hint_range(0.0, 1.0) = 0.1;
uniform float roughness : hint_range(0.0, 1.0) = 0.9;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float wave_scale = 10.0;
uniform float wave_height = 0.2;

// Simple noise function
float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

void fragment() {
    // Base color
    ALBEDO = sand_color;
    
    // Add grain
    float noise = random(UV * 100.0);
    ALBEDO *= (1.0 - grain_amount) + noise * grain_amount;
    
    // Roughness and Metallic
    ROUGHNESS = roughness;
    METALLIC = metallic;
    
    // Normal mapping for dunes (simple wave approximation)
    float wave = sin(UV.x * wave_scale + UV.y * wave_scale * 0.5);
    vec3 normal_map = normalize(vec3(wave * wave_height, 0.0, 1.0));
    NORMAL_MAP = normal_map;
}
