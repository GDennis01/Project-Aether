shader_type spatial;
// render_mode unshaded; // Uncomment this line if you want NO SHADING AT ALL, just the flat texture color

// Uniforms (parameters you can change in the Inspector)
uniform vec4 base_color : source_color = vec4(0.85, 0.7, 0.5, 1.0); // Base sphere color (light brownish)
uniform vec4 line_color : source_color = vec4(0.1, 0.1, 0.1, 1.0); // Line color (dark grey/black)
uniform float latitude_lines = 6.0; // Number of latitude divisions (e.g., 6 = lines every 30 degrees)
uniform float longitude_lines = 12.0; // Number of longitude divisions (e.g., 12 = lines every 30 degrees)
uniform float line_thickness : hint_range(0.0, 0.1) = 0.008; // Thickness of the lines in UV space

// Function for smooth grid lines (anti-aliased)
// Calculates distance to nearest grid line and applies smoothing
float grid_line(float value, float num_lines, float thickness) {
    float line_val = value * num_lines;
    // Calculate distance to the nearest integer value (center of the line)
    float distance_to_line = abs(fract(line_val - 0.5) - 0.5);
    // Use fwidth to get screen-space derivative for consistent thickness & anti-aliasing
    float fw = fwidth(line_val) * 0.5; // Use half width for smoothstep edges
    // Smoothstep creates a transition from 0 to 1 based on distance and thickness
    // Invert the result so lines are 1.0 and gaps are 0.0
    return 1.0 - smoothstep(thickness - fw, thickness + fw, distance_to_line);
}

void fragment() {
    // UV coordinates range from (0,0) to (1,1)
    vec2 uv = UV;

    // Calculate line intensity for latitude (horizontal lines based on V coordinate)
    // Note: UV.y often goes from top (0) to bottom (1) corresponding to North to South pole
    float lat_line_intensity = grid_line(uv.y, latitude_lines, line_thickness / 2.0);

    // Calculate line intensity for longitude (vertical lines based on U coordinate)
    float lon_line_intensity = grid_line(uv.x, longitude_lines, line_thickness / 2.0);

    // Combine the line intensities (take the maximum intensity if overlapping)
    float line_mask = max(lat_line_intensity, lon_line_intensity);

    // Mix the base color and line color based on the line mask
    vec3 final_color = mix(base_color.rgb, line_color.rgb, line_mask);

    // Output the final color
    ALBEDO = final_color;

    // Optional: Control other material properties if not using unshaded mode
    // METALLIC = 0.0;
    // ROUGHNESS = 0.8;
    // ALPHA = base_color.a; // Or mix alpha too if needed
}