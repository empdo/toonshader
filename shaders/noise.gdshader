shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;

// Grain
uniform float grain_amount : hint_range(0.0, 0.2) = 0.05;
uniform float grain_size : hint_range(0.1, 10.0) = 1.0;
uniform bool animate = true;

// Vignette - Optimized for High Contrast
uniform float vignette_radius : hint_range(0.0, 1.0) = 0.5; // How much of the center is clear
uniform float vignette_softness : hint_range(0.0, 1.0) = 0.5; // How blurry the edge is
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.8;
uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
    vec4 color = texture(screen_texture, SCREEN_UV);

    // 1. Grain
    float noise = (fract(sin(dot(UV * (animate ? TIME : 1.0), vec2(12.9898, 78.233))) * 43758.5453) - 0.5) * 2.0;
    color.rgb += noise * grain_amount * grain_size;

    // 2. High-Contrast Vignette
    // Distance from center
    float dist = distance(UV, vec2(0.5));
    
    /* CONTRAST MATH:
       We use smoothstep to create a hard floor for the center. 
       Anything inside 'vignette_radius' will be 0.0 (no vignette).
    */
    float v_step = smoothstep(vignette_radius, vignette_radius + vignette_softness, dist);
    
    // Squaring the result "hollows out" the middle further, increasing contrast
    float final_vignette = pow(v_step, 2.0);

    color.rgb = mix(color.rgb, vignette_color.rgb, final_vignette * vignette_opacity);

    COLOR = vec4(color.rgb, 1.0);
}