shader_type spatial;
// unshaded means it ignores light, cull_front draws the back-faces
render_mode unshaded, cull_front, depth_draw_always;

uniform vec4 line_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float line_thickness = 0.03; // Adjust this for branch thickness

void vertex() {
    // This expands the mesh outward along its normals
    // It creates a "shell" slightly larger than the tree
    VERTEX += NORMAL * line_thickness;
}

void fragment() {
    // Everything in this shell is painted the line color
    ALBEDO = line_color.rgb;
}