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
uniform bool enable_outlines = true;
uniform float line_thickness : hint_range(0.0, 10.0) = 2.0;
uniform float normal_edge_sensitivity : hint_range(0.01, 2.0) = 0.3;
uniform float depth_edge_sensitivity : hint_range(0.0, 10000.0) = 5000.0;
uniform vec4 line_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform bool use_sobel_8_direction = true;

// Freestyle/Rim outline (silhuett-baserad)
uniform bool enable_rim_outline = true;
uniform float rim_threshold : hint_range(0.0, 1.0) = 0.3;
uniform float rim_smoothness : hint_range(0.0, 0.5) = 0.05;

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
    float depth_center = texture(depth_tex, uv).r;
    vec3 normal_center = texture(normal_tex, uv).rgb * 2.0 - 1.0;
    
    float edge_mask = 0.0;
    
    // --- RIM/FREESTYLE OUTLINE (Silhuett-baserad) ---
    float rim_outline = 0.0;
    if (enable_outlines && enable_rim_outline) {
        vec3 view_dir = normalize(CAMERA_POSITION_WORLD - v_world_pos);
        float rim = 1.0 - abs(dot(normalize(v_world_nrm), view_dir));
        rim_outline = smoothstep(rim_threshold - rim_smoothness, rim_threshold + rim_smoothness, rim);
    }
    
    if (enable_outlines && use_sobel_8_direction) {
        // 8-riktnings Sobel operator (3x3 kernel)
        // Sample alla 8 riktningar runt centrum
        vec3 n_tl = texture(normal_tex, uv + vec2(-offset.x, offset.y)).rgb * 2.0 - 1.0;  // top-left
        vec3 n_t  = texture(normal_tex, uv + vec2(0.0, offset.y)).rgb * 2.0 - 1.0;        // top
        vec3 n_tr = texture(normal_tex, uv + vec2(offset.x, offset.y)).rgb * 2.0 - 1.0;   // top-right
        vec3 n_l  = texture(normal_tex, uv + vec2(-offset.x, 0.0)).rgb * 2.0 - 1.0;       // left
        vec3 n_r  = texture(normal_tex, uv + vec2(offset.x, 0.0)).rgb * 2.0 - 1.0;        // right
        vec3 n_bl = texture(normal_tex, uv + vec2(-offset.x, -offset.y)).rgb * 2.0 - 1.0; // bottom-left
        vec3 n_b  = texture(normal_tex, uv + vec2(0.0, -offset.y)).rgb * 2.0 - 1.0;       // bottom
        vec3 n_br = texture(normal_tex, uv + vec2(offset.x, -offset.y)).rgb * 2.0 - 1.0;  // bottom-right
        
        float d_tl = texture(depth_tex, uv + vec2(-offset.x, offset.y)).r;
        float d_t  = texture(depth_tex, uv + vec2(0.0, offset.y)).r;
        float d_tr = texture(depth_tex, uv + vec2(offset.x, offset.y)).r;
        float d_l  = texture(depth_tex, uv + vec2(-offset.x, 0.0)).r;
        float d_r  = texture(depth_tex, uv + vec2(offset.x, 0.0)).r;
        float d_bl = texture(depth_tex, uv + vec2(-offset.x, -offset.y)).r;
        float d_b  = texture(depth_tex, uv + vec2(0.0, -offset.y)).r;
        float d_br = texture(depth_tex, uv + vec2(offset.x, -offset.y)).r;
        
        // Sobel kernel för X-riktning: [-1, 0, 1]
        //                               [-2, 0, 2]
        //                               [-1, 0, 1]
        vec3 sobel_n_x = -n_tl + n_tr - 2.0*n_l + 2.0*n_r - n_bl + n_br;
        float sobel_d_x = -d_tl + d_tr - 2.0*d_l + 2.0*d_r - d_bl + d_br;
        
        // Sobel kernel för Y-riktning: [-1, -2, -1]
        //                               [ 0,  0,  0]
        //                               [ 1,  2,  1]
        vec3 sobel_n_y = -n_tl - 2.0*n_t - n_tr + n_bl + 2.0*n_b + n_br;
        float sobel_d_y = -d_tl - 2.0*d_t - d_tr + d_bl + 2.0*d_b + d_br;
        
        // Beräkna gradient magnitude
        float normal_edge = length(sobel_n_x) + length(sobel_n_y);
        float depth_edge = (abs(sobel_d_x) + abs(sobel_d_y)) * depth_edge_sensitivity;
        
        edge_mask = step(normal_edge_sensitivity, normal_edge) + step(1.0, depth_edge);
        edge_mask = clamp(edge_mask, 0.0, 1.0);
    } else if (enable_outlines) {
        // 4-riktnings enkel edge detection (original)
        vec3 n_u = texture(normal_tex, uv + vec2(0.0, offset.y)).rgb * 2.0 - 1.0;
        vec3 n_d = texture(normal_tex, uv - vec2(0.0, offset.y)).rgb * 2.0 - 1.0;
        vec3 n_l = texture(normal_tex, uv - vec2(offset.x, 0.0)).rgb * 2.0 - 1.0;
        vec3 n_r = texture(normal_tex, uv + vec2(offset.x, 0.0)).rgb * 2.0 - 1.0;
        
        float d_u = texture(depth_tex, uv + vec2(0.0, offset.y)).r;
        float d_d = texture(depth_tex, uv - vec2(0.0, offset.y)).r;
        float d_l = texture(depth_tex, uv - vec2(offset.x, 0.0)).r;
        float d_r = texture(depth_tex, uv + vec2(offset.x, 0.0)).r;
        
        float n_diff = length(n_u - n_d) + length(n_l - n_r);
        float d_diff = (abs(depth_center - d_u) + abs(depth_center - d_d) + 
                        abs(depth_center - d_l) + abs(depth_center - d_r)) * depth_edge_sensitivity;
        edge_mask = step(normal_edge_sensitivity, n_diff + d_diff);
    }

    // --- 3. DEPTH MASKING ---
    // Compare the screen depth at the pixel to the depth of this specific object.
    // FRAGCOORD.z is the depth of the current object being drawn.
    // If the screen depth is significantly smaller than FRAGCOORD.z, 
    // it means there is an object IN FRONT of this one, so we kill the outline.
    if (enable_outlines && depth_center < FRAGCOORD.z - 0.00001) {
        edge_mask = 0.0;
        rim_outline = 0.0;
    }
    
    // --- KOMBINERA ALLA OUTLINE-METODER ---
    float final_outline = max(edge_mask, rim_outline);
    if (!enable_outlines) {
        final_outline = 0.0;
    }

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
    ALBEDO = mix(final_color, line_color.rgb, final_outline);
}