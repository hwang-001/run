shader_type canvas_item;

uniform bool title = true;
uniform bool portrait = false;

void fragment() {
	if (title) {
		float reveal = portrait
			? smoothstep(0.02, 0.83, abs(UV.y - 0.42))
			: smoothstep(0.23, 0.80, UV.x);
		float edge = smoothstep(0.55, 1.0, UV.y) * 0.19;
		vec3 paper = mix(vec3(1.0, 0.98, 0.92), vec3(0.86, 0.98, 0.94), UV.y);
		COLOR = vec4(paper, mix(0.98, 0.19, reveal) + edge);
	} else {
		COLOR = vec4(0.045, 0.17, 0.20, 0.54);
	}
}
