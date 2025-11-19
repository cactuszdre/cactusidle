shader_type spatial;
render_mode cull_disabled;

uniform vec3 sand_color : source_color = vec3(0.88, 0.75, 0.59);
uniform float dune_height = 15.0;
uniform float dune_scale = 0.05;
uniform float noise_scale = 50.0;

// Simple noise
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), f.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
    // Displace vertex Y based on world position to create rolling dunes
    float height = noise(VERTEX.xz * dune_scale) * dune_height;
    // Add some detail
    height += noise(VERTEX.xz * dune_scale * 4.0) * (dune_height * 0.2);
    
    // Taper edges to avoid floating mesh
    // UVs are 0..1. We want to pin edges to 0 height (relative to mesh origin)
    float edge_dist = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
    // Smooth taper over 10% of the mesh
    float taper = smoothstep(0.0, 0.2, edge_dist);
    
    VERTEX.y += height * taper;
}

void fragment() {
    ALBEDO = sand_color;
    
    // Grain
    float grain = hash(UV * noise_scale);
    ALBEDO *= 0.9 + 0.2 * grain;
    
    ROUGHNESS = 0.9;
    METALLIC = 0.0;
    
    // Simple normal recalculation based on derivatives (automatic in Godot usually, but we can enhance)
}
