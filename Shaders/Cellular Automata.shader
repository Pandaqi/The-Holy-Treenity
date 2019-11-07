shader_type canvas_item;

uniform sampler2D grid_tex;
uniform vec2 screen_size = vec2(1024.0, 768.0);

void fragment() {
	// convert UV coordinates to screen
	// this is in PIXELS
	vec2 uv_to_screen = vec2( UV.x * screen_size.y * (32.0/24.0), UV.y * screen_size.y);
	
	// now convert these back to tilemap coordinates
	// this is in INDICES
	vec2 screen_to_map = vec2( floor(uv_to_screen.x / 32.0), floor(uv_to_screen.y / 32.0) );
	
	// and convert this back to a UV => divide by total pixel size of texture
	// (add 0.5 to be in the center of the pixel we want; if we don't do this, we pick the value at the edge, which will lead to unpredictable resutls)
	vec2 pixel_size = 1.0 / vec2(textureSize(grid_tex, 0));
	vec2 map_to_uv = vec2( (screen_to_map.x + 0.5) * pixel_size.x, (screen_to_map.y + 0.5) * pixel_size.y);
	
	// set color based on cellular automaton texture
	COLOR = texture(grid_tex, map_to_uv).rgba;
}