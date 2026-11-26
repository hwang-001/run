shader_type spatial;
render_mode unshaded;

uniform sampler2D asphalt : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float reflection_strength = 1.0;
varying float lateral;

void vertex() {
	lateral = (MODEL_MATRIX * vec4(VERTEX, 1.0)).x;
}

void fragment() {
	float dirt = texture(asphalt, UV * vec2(3.0, 4.4)).r;
	vec3 wet = mix(vec3(0.083, 0.105, 0.181), vec3(0.176, 0.208, 0.302), dirt);
	float edge = smoothstep(1.65, 4.8, abs(lateral));
	float stripe = exp(-pow((abs(lateral) - 3.84) * 1.16, 2.0));
	float lights = 0.4 + 0.6 * pow(0.5 + 0.5 * cos(UV.y * 7.1 - 0.7 + dirt * 0.72), 2.0);
	vec3 source = lateral < 0.0 ? vec3(0.31, 0.76, 0.97) : vec3(0.90, 0.34, 0.67);
	ALBEDO = wet + source * stripe * edge * lights * (0.32 + dirt * 0.12) * reflection_strength;
}
