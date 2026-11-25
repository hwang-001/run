shader_type canvas_item;

uniform bool title = true;
uniform bool portrait = false;

void fragment() {
	float edge = smoothstep(0.29, 0.74, length((UV - vec2(0.55, 0.44)) * vec2(0.99, 0.83)));
	float bottom = smoothstep(0.45, 1.0, UV.y);
	if (title) {
		float left = portrait ? smoothstep(0.2, 1.0, UV.y) : 1.0 - smoothstep(0.15, 0.78, UV.x);
		vec3 color = mix(vec3(0.05, 0.15, 0.23), vec3(0.09, 0.26, 0.32), UV.y);
		COLOR = vec4(color, 0.07 + left * 0.37 + bottom * 0.23 + edge * 0.11);
	} else {
		COLOR = vec4(0.025, 0.11, 0.18, 0.63 + edge * 0.15);
	}
}
