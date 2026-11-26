shader_type spatial;
render_mode unshaded, cull_back;

uniform vec4 accent : source_color = vec4(0.37, 0.82, 0.98, 1.0);
uniform float animation_strength = 1.0;

void fragment() {
	float line = smoothstep(0.97, 0.994, max(abs(UV.x - 0.5), abs(UV.y - 0.5)) * 2.0);
	float sweep = exp(-pow((fract(UV.x - TIME * 0.19 + UV.y * 0.31) - 0.5) * 10.0, 2.0));
	float micro = 0.022 * (0.5 + 0.5 * sin(UV.y * 575.0));
	ALBEDO = accent.rgb * (0.24 + line * 0.69 + sweep * 0.14 * animation_strength + micro);
}
