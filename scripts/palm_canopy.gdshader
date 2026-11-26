shader_type spatial;
render_mode cull_disabled;

uniform vec4 leaf : source_color;

void vertex() {
	vec3 tree = MODEL_MATRIX[3].xyz;
	float wind = sin(tree.x * 0.38 + tree.z * 0.21 + TIME * 1.12);
	VERTEX.x += wind * 0.015 * smoothstep(0.18, 0.66, VERTEX.y);
	VERTEX.z += cos(TIME + tree.x * 0.19) * 0.010 * smoothstep(0.18, 0.66, VERTEX.y);
}

void fragment() {
	ALBEDO = leaf.rgb;
	ROUGHNESS = 0.88;
}
