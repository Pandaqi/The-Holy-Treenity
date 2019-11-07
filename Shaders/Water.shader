shader_type canvas_item;

uniform sampler2D noise_tex;

void vertex() {
	// if a vertex is exactly on the grid line, don't add waves
	// otherwise, us a simple sine waves to let water flow
	if( int(VERTEX.y) % 32 != 0) {
		VERTEX.y += sin(TIME + VERTEX.x * 2.0) * 1.0 - 1.0;
	}
}

void fragment() {
	// change alpha based on the noise texture
	// use screen uv, otherwise it applies the WHOLE texture to a single rectangle at a time
	// also make it scroll downwards (by adding TIME), to make waterfalls look very nice
	COLOR.a += texture(noise_tex, SCREEN_UV + vec2(0, TIME * 0.25)).r * 0.5 - 0.25;
}