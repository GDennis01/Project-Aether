shader_type spatial;

// Enable the grid
uniform bool grid_enabled = true;
// The texture for the comet's surface
uniform sampler2D comet_texture: source_color;
// Number of lines
uniform float latitude_lines = 6.0;
uniform float longitude_lines = 12.0;
// Total thickness of the lat/long line
uniform float line_thickness : hint_range(0.0, 0.1) = 0.01;
// Thickness of outline of the lat/long line
uniform float border_thickness : hint_range(0.0, 0.1) = 0.002;


float grid_line(float value, float num_lines, float thickness, out float index) {
    float line_val = value * num_lines;
    index = floor(line_val + 0.5);
    float distance_to_line = abs(fract(line_val - 0.5) - 0.5);
    float fw = fwidth(line_val) * 0.5;
    return 1.0 - smoothstep(thickness - fw, thickness + fw, distance_to_line);
}



void fragment() {
    vec3 black_color = vec3(0.0);
    vec3 white_color = vec3(1.0);
    vec3 red_color = vec3(1.0, 0.0, 0.0);

    vec3 mixed_color = texture(comet_texture, UV).rgb;
	if (grid_enabled){
	    // Calculate the thickness of the inner white part of the line.
	    // max() to prevent it from becoming negative if border is too thick.
	    float inner_thickness = max(0.0, line_thickness - border_thickness);

	    float lat_idx;
	    // Outer mask (for the black outline) uses the full line_thickness
	    float lat_outer_mask = grid_line(UV.y, latitude_lines, line_thickness / 2.0, lat_idx);
	    // Inner mask (for the white line) uses the reduced inner_thickness
	    float lat_inner_mask = grid_line(UV.y, latitude_lines, inner_thickness / 2.0, lat_idx);

	    float lon_idx;
	    // Outer mask for longitude
	    float lon_outer_mask = grid_line(UV.x, longitude_lines, line_thickness / 2.0, lon_idx);
	    // Inner mask for longitude
	    float lon_inner_mask = grid_line(UV.x, longitude_lines, inner_thickness / 2.0, lon_idx);

	    // coloring the equator in red
	    float equator_index = floor((latitude_lines / 2.0) + 0.5);
	    vec3 lat_line_color = (lat_idx == equator_index) ? red_color : white_color;

	    // Layering the colors
	    // 1. texture color
	    // 2. black outline
	    // 3. white line on top of the black outline

	    // Apply latitude lines (black outline then white fill)
	    mixed_color = mix(mixed_color, black_color, lat_outer_mask);
	    mixed_color = mix(mixed_color, lat_line_color, lat_inner_mask);

	    // Apply longitude lines (black outline then white fill)
	    mixed_color = mix(mixed_color, black_color, lon_outer_mask);
	    mixed_color = mix(mixed_color, white_color, lon_inner_mask);
	}
    ALBEDO = mixed_color;
}