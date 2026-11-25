shader_type spatial;
render_mode unshaded, cull_disabled;

uniform bool waterfall = false;
varying vec3 world;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = waterfall ? UV * vec2(4.5, 11.0) : world.xz * vec2(0.75, 0.48);
	float t = TIME * (waterfall ? 3.6 : 1.0);
	float chains = sin(p.x * 5.6 + sin(p.y * 2.3 - t) * 0.58);
	float currents = pow(0.5 + 0.5 * chains, 4.0) * (0.45 + 0.55 * pow(0.5 + 0.5 * sin(p.y * 3.1 - t * 1.7 + p.x * 0.71), 3.0));
	float whitewater = waterfall ? 0.22 + 0.38 * currents + 0.27 * smoothstep(0.78, 1.0, UV.y) : 0.14 * currents;
	vec3 jade = waterfall ? vec3(0.26, 0.66, 0.68) : vec3(0.11, 0.46, 0.51);
	ALBEDO = mix(jade, vec3(0.89, 0.99, 0.93), whitewater);
}
