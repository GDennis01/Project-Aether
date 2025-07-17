shader_type spatial;

// --- UNIFORMS ---
// The texture for the comet's surface
uniform sampler2D comet_texture: source_color;
// Number of lines
uniform float latitude_lines = 6.0;
uniform float longitude_lines = 12.0;
// Total thickness of the line (white part + one side of the border)
uniform float line_thickness : hint_range(0.0, 0.1) = 0.01;
// Thickness of the black border itself
uniform float border_thickness : hint_range(0.0, 0.1) = 0.002;


// --- FUNCTIONS ---
// This helper function remains the same. It's a great anti-aliased line generator.
float grid_line(float value, float num_lines, float thickness, out float index) {
    float line_val = value * num_lines;
    index = floor(line_val);
    float distance_to_line = abs(fract(line_val - 0.5) - 0.5);
    float fw = fwidth(line_val) * 0.5;
    return 1.0 - smoothstep(thickness - fw, thickness + fw, distance_to_line);
}


// --- FRAGMENT SHADER ---
void fragment() {
    // Define our line colors
    vec3 black_color = vec3(0.0);
    vec3 white_color = vec3(1.0);

    // Sample the base texture
    vec3 mixed_color = texture(comet_texture, UV).rgb;

    // --- LINE CALCULATIONS ---
    // Calculate the thickness of the inner white part of the line.
    // Use max() to prevent it from becoming negative if border is too thick.
    float inner_thickness = max(0.0, line_thickness - border_thickness);

    // -- Latitude Lines --
    float lat_idx;
    // Outer mask (for the black border) uses the full line_thickness
    float lat_outer_mask = grid_line(UV.y, latitude_lines, line_thickness / 2.0, lat_idx);
    // Inner mask (for the white line) uses the reduced inner_thickness
    float lat_inner_mask = grid_line(UV.y, latitude_lines, inner_thickness / 2.0, lat_idx);

    // -- Longitude Lines --
    float lon_idx;
    // Outer mask for longitude
    float lon_outer_mask = grid_line(UV.x, longitude_lines, line_thickness / 2.0, lon_idx);
    // Inner mask for longitude
    float lon_inner_mask = grid_line(UV.x, longitude_lines, inner_thickness / 2.0, lon_idx);


    // --- COLOR MIXING ---
    // Layer the colors. The last mix is drawn on top.

    // 1. Start with the texture.
    // 2. Draw the thick black lines.
    // 3. Draw the thinner white lines on top.

    // Apply latitude lines (black border then white fill)
    mixed_color = mix(mixed_color, black_color, lat_outer_mask);
    mixed_color = mix(mixed_color, white_color, lat_inner_mask);

    // Apply longitude lines (black border then white fill)
    mixed_color = mix(mixed_color, black_color, lon_outer_mask);
    mixed_color = mix(mixed_color, white_color, lon_inner_mask);

    ALBEDO = mixed_color;
}