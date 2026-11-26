shader_type canvas_item;

uniform bool title = true;
uniform bool portrait = false;

void fragment() {
	vec3 ink = vec3(0.025, 0.075, 0.12);
	if (title) {
		float shade = portrait
			? max((1.0 - smoothstep(0.03, 0.30, UV.y)) * 0.58, smoothstep(0.52, 0.85, UV.y) * 0.78)
			: (1.0 - smoothstep(0.14, 0.68, UV.x)) * 0.71;
		COLOR = vec4(ink, shade);
	} else {
		COLOR = vec4(ink, 0.69);
	}
}
