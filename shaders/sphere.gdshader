shader_type spatial;

uniform vec4 base_color : source_color = vec4(0.85, 0.7, 0.5, 1.0);
uniform float latitude_lines = 6.0;
uniform float longitude_lines = 12.0;
uniform float line_thickness : hint_range(0.0, 0.1) = 0.008;

float grid_line(float value, float num_lines, float thickness, out float index) {
    float line_val = value * num_lines;
    index = floor(line_val); // output index
    float distance_to_line = abs(fract(line_val - 0.5) - 0.5);
    float fw = fwidth(line_val) * 0.5;
    return 1.0 - smoothstep(thickness - fw, thickness + fw, distance_to_line);
}

// Convert HSV to RGB (for varied colors)
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// Generates a rainbow-like color from index and count
vec3 line_color(float index, float count) {
    float hue = mod(index / count, 1.0); // 0 to 1
    //return hsv2rgb(vec3(hue, 0.8, 0.9));
	return vec3(0,0,0);
}



void fragment() {
    vec2 uv = UV;

    float lat_idx;
    float lat_mask = grid_line(uv.y, latitude_lines, line_thickness / 2.0, lat_idx);
    vec3 lat_color = line_color(lat_idx, latitude_lines);

    float lon_idx;
    float lon_mask = grid_line(uv.x, longitude_lines, line_thickness / 2.0, lon_idx);
    vec3 lon_color = line_color(lon_idx, longitude_lines);

    vec3 mixed_color = base_color.rgb;

    // Apply latitude line color
    mixed_color = mix(mixed_color, lat_color, lat_mask);
    // Apply longitude line color
    mixed_color = mix(mixed_color, lon_color, lon_mask * (1.0 - lat_mask)); // prevent over-blending overlap

    ALBEDO = mixed_color;
}
