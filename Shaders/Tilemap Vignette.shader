shader_type canvas_item;

uniform vec2 screen_size = vec2(1024.0, 768);

void fragment() {
	// convert coordinates to tilemap
	vec2 uv_to_screen = vec2( SCREEN_UV.x * screen_size.x, SCREEN_UV.y * screen_size.y);
	vec2 screen_to_map = vec2( floor(uv_to_screen.x / 32.0), floor(uv_to_screen.y / 32.0) );
	
	// calculate distance (in tiles) between current pixel and map center
	float dist_to_map_center = length( screen_to_map - vec2(16, 12) );
	
	// invert it, so that tiles near the edge get darker and darker
	float val = 1.0 - dist_to_map_center / 16.0;
	
	// finally, apply the original texture, but multiply by the vignette we just created
	COLOR = texture(TEXTURE, UV) * vec4(val, val, val, 1.0);
}