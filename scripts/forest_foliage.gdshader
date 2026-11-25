shader_type spatial;
render_mode cull_disabled;

uniform vec4 fir : source_color = vec4(0.23, 0.43, 0.29, 1.0);

void vertex() {
	float edge = clamp(abs(VERTEX.y) + length(VERTEX.xz) * 1.15, 0.16, 1.2);
	float breeze = sin(TIME * 1.48 + MODEL_MATRIX[3].x * 0.23 + MODEL_MATRIX[3].z * 0.045);
	VERTEX.x += breeze * edge * 0.014;
	VERTEX.z += cos(TIME * 1.17 + MODEL_MATRIX[3].z * 0.038) * edge * 0.009;
}

void fragment() {
	ALBEDO = fir.rgb;
	ROUGHNESS = 0.86;
}
