shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;
uniform float grain_amount : hint_range(0.0, 1.0) = 0.05;
uniform float grain_size : hint_range(0.1, 10.0) = 1.0;
uniform bool animate = true;

// Vignette Uniforms
uniform float vignette_intensity : hint_range(0.0, 3.0) = 0.4;
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.5;
uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	// 1. Sample the original screen texture
	vec4 original_color = texture(screen_texture, SCREEN_UV);

	// 2. Grain Logic
	float noise = 0.0;
	if (animate) {
		noise = (fract(sin(dot(UV * TIME, vec2(12.9898, 78.233))) * 43758.5453) - 0.5) * 2.0;
	} else {
		noise = (fract(sin(dot(UV, vec2(12.9898, 78.233))) * 43758.5453) - 0.5) * 2.0;
	}
	original_color.rgb += noise * grain_amount * grain_size;

	// 3. Vignette Logic
	// Calculate distance from center (0.5, 0.5)
	float d = distance(UV, vec2(0.5, 0.5));
	
	// Apply intensity and smooth out the transition
	float vignette = pow(d, vignette_intensity);
	
	// Mix the current color with the vignette color based on distance
	original_color.rgb = mix(original_color.rgb, vignette_color.rgb, vignette * vignette_opacity);

	// 4. Final Output
	COLOR = clamp(original_color, 0.0, 1.0);
}