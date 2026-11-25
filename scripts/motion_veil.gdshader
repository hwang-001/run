shader_type spatial;
render_mode unshaded, shadows_disabled, cull_disabled, depth_draw_never;

uniform vec4 tint : source_color = vec4(0.72, 0.91, 1.0, 0.4);
uniform bool band = true;

void fragment() {
	float cover = 1.0;
	if (band) {
		float center = (1.0 - smoothstep(0.08, 0.48, abs(UV.x - 0.5)));
		cover = center * sin(UV.y * 3.14159265);
	}
	ALBEDO = tint.rgb;
	ALPHA = tint.a * cover;
}
