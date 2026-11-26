shader_type spatial;
render_mode unshaded, cull_disabled;

void fragment() {
	float diagonal = step(0.53, fract(UV.x * 6.0 - UV.y * 0.73));
	float margin = smoothstep(0.065, 0.075, min(UV.x, 1.0 - UV.x));
	vec3 bronze = vec3(0.98, 0.67, 0.28);
	vec3 slate = vec3(0.21, 0.16, 0.19);
	ALBEDO = mix(bronze, slate, diagonal * margin);
}
