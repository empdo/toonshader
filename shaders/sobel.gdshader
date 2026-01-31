shader_type spatial;
render_mode unshaded, depth_draw_always;

// --- HATCH PARAMETRAR ---
uniform vec4 base_color : source_color = vec4(1.0);
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic;
uniform bool use_albedo_tex = false;
uniform sampler2D hatch_tex : filter_nearest, repeat_enable;
uniform vec3 ink_color : source_color = vec3(0.0);
uniform float hatch_world_scale : hint_range(0.0, 10.0) = 0.1;
uniform float hatch_strength : hint_range(0.0, 4.0) = 2.0;

// --- ANTI-ALIASING FÖR HATCHING PÅ AVSTÅND ---
uniform float hatch_fade_start : hint_range(1.0, 200.0) = 10.0;
uniform float hatch_fade_end : hint_range(1.0, 400.0) = 20.0;
uniform bool use_distance_fade = true;
uniform vec3 distance_fade_color : source_color = vec3(0.15, 0.12, 0.1);

// --- DYNAMISK POSITION FÖR LJUS ---
uniform vec3 light_position_ws = vec3(0.0, 5.0, 0.0);
uniform float band1 = 0.6;
uniform float band2 = 0.4;
uniform float band3 = 0.2;
uniform float band_softness = 0.05;

// --- OUTLINE PARAMETRAR ---
uniform float line_thickness : hint_range(0.0, 10.0) = 2.0;
uniform float edge_sensitivity : hint_range(0.01, 1.0) = 0.2;
uniform vec4 line_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

uniform sampler2D depth_tex : hint_depth_texture;
uniform sampler2D normal_tex : hint_normal_roughness_texture, filter_nearest;

varying vec3 v_world_pos;
varying vec3 v_world_nrm;

// --- HJÄLPFUNKTIONER ---
mat2 rot(float a) {
    float s = sin(a); float c = cos(a);
    return mat2(vec2(c, s), vec2(-s, c));
}

float hatch_ink(vec2 uv) {
    return 1.0 - texture(hatch_tex, uv).r;
}

float hatch_triplanar(vec3 p, vec3 n, float a) {
    n = normalize(n);
    vec3 w = pow(abs(n), vec3(4.0));
    w /= (w.x + w.y + w.z) + 1e-6;
    mat2 R = rot(a);
    float sx = hatch_ink(R * p.yz * hatch_world_scale);
    float sy = hatch_ink(R * p.xz * hatch_world_scale);
    float sz = hatch_ink(R * p.xy * hatch_world_scale);
    return sx * w.x + sy * w.y + sz * w.z;
}

void vertex() {
    v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    v_world_nrm = normalize(mat3(transpose(inverse(MODEL_MATRIX))) * NORMAL);
}

void fragment() {
    vec2 uv = SCREEN_UV;
    vec2 pixel_size = 1.0 / VIEWPORT_SIZE;
    vec2 offset = line_thickness * pixel_size;

    // --- 1. SAMPLE DEPTH & NORMALS ---
    // Central depth of the current object fragment
    float depth_center = texture(depth_tex, uv).r;
    
    // Neighbor samples
    vec3 n_u = texture(normal_tex, uv + vec2(0.0, offset.y)).rgb * 2.0 - 1.0;
    vec3 n_d = texture(normal_tex, uv - vec2(0.0, offset.y)).rgb * 2.0 - 1.0;
    vec3 n_l = texture(normal_tex, uv - vec2(offset.x, 0.0)).rgb * 2.0 - 1.0;
    vec3 n_r = texture(normal_tex, uv + vec2(offset.x, 0.0)).rgb * 2.0 - 1.0;
    
    float d_u = texture(depth_tex, uv + vec2(0.0, offset.y)).r;
    float d_d = texture(depth_tex, uv - vec2(0.0, offset.y)).r;
    float d_l = texture(depth_tex, uv - vec2(offset.x, 0.0)).r;
    float d_r = texture(depth_tex, uv + vec2(offset.x, 0.0)).r;

    // --- 2. CALCULATE EDGES ---
    float n_diff = length(n_u - n_d) + length(n_l - n_r);
    float d_diff = (abs(d_u - d_d) + abs(d_l - d_r)) * 1000.0;
    float raw_edge = step(edge_sensitivity, n_diff + d_diff);

    // --- 3. THE FIX: DEPTH MASKING ---
    // Compare the screen depth at the pixel to the depth of this specific object.
    // FRAGCOORD.z is the depth of the current object being drawn.
    // If the screen depth is significantly smaller than FRAGCOORD.z, 
    // it means there is an object IN FRONT of this one, so we kill the outline.
    float depth_mask = 1.0;
    if (depth_center < FRAGCOORD.z - 0.0001) {
        depth_mask = 0.0;
    }
    float edge_mask = raw_edge * depth_mask;

    // --- 4. LIGHTING & HATCHING (Same as before) ---
    vec3 L = normalize(light_position_ws - v_world_pos);
    float NdotL = dot(normalize(v_world_nrm), L);
    float light_level = max(NdotL, 0.0);

    float g1 = smoothstep(band1 + band_softness, band1 - band_softness, light_level);
    float g2 = smoothstep(band2 + band_softness, band2 - band_softness, light_level);
    float g3 = smoothstep(band3 + band_softness, band3 - band_softness, light_level);

    float h1 = hatch_triplanar(v_world_pos, v_world_nrm, radians(45.0));
    float h2 = hatch_triplanar(v_world_pos, v_world_nrm, radians(-45.0));
    float h3 = hatch_triplanar(v_world_pos, v_world_nrm, radians(0.0));

    float combined_hatch = max(max(h1 * g1, h2 * g2), h3 * g3);
    
    // Tona ut på avstånd (beräknas per-pixel för korrekt resultat på stora ytor)
    float distance_fade = 1.0;
    float fog_factor = 0.0;
    if (use_distance_fade) {
        float cam_distance = length(v_world_pos - CAMERA_POSITION_WORLD);
        distance_fade = 1.0 - smoothstep(hatch_fade_start, hatch_fade_end, cam_distance);
        fog_factor = smoothstep(hatch_fade_start, hatch_fade_end, cam_distance);
    }
    
    float ink = clamp(combined_hatch * hatch_strength * distance_fade, 0.0, 1.0);

    vec3 final_color = base_color.rgb;
    if (use_albedo_tex) final_color *= texture(albedo_tex, UV).rgb;
    final_color = mix(final_color, ink_color, ink);
    
    // Blend towards dark fog color at distance
    final_color = mix(final_color, distance_fade_color, fog_factor);

    // --- 5. FINAL MIX ---
    ALBEDO = mix(final_color, line_color.rgb, edge_mask);
}