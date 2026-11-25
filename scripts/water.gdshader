shader_type spatial;
render_mode unshaded, cull_disabled;

varying vec3 water_world;

void vertex() {
	water_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = water_world.xz;
	float front = 0.5 + 0.5 * sin(p.y * 0.31 + p.x * 0.17 - TIME * 0.61);
	float ripple = sin(p.y * 1.72 + p.x * 1.11 + TIME * 2.3 + sin(p.x * 0.52 - p.y * 0.13) * 1.3);
	float lace = pow(0.5 + 0.5 * ripple, 12.0) * (0.15 + front * 0.50);
	float shoal = 1.0 - smoothstep(4.5, 35.0, abs(p.x));
	float foam = (1.0 - smoothstep(0.05, 0.65, abs(abs(p.x) - 5.1 + ripple * 0.23))) * 0.25;
	vec3 water = mix(vec3(0.095, 0.46, 0.60), vec3(0.18, 0.73, 0.68), shoal);
	ALBEDO = mix(water, vec3(0.88, 0.98, 0.87), lace * 0.33 + foam)
		+ vec3(0.025, 0.044, 0.03) * (front - 0.5);
}
