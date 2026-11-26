shader_type spatial;
render_mode unshaded;

uniform sampler2D atlas : source_color, filter_nearest;
uniform vec4 stone : source_color = vec4(0.15, 0.19, 0.31, 1.0);
uniform vec4 glass : source_color = vec4(0.30, 0.68, 0.86, 1.0);

varying vec3 face;
varying vec3 local_point;

void vertex() {
	face = normalize(MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
	local_point = VERTEX;
}

void fragment() {
	vec3 paint = texture(atlas, UV).rgb;
	float value = dot(paint, vec3(0.2126, 0.7152, 0.0722));
	float window_mask = smoothstep(0.10, 0.27, paint.b - paint.r) * smoothstep(0.20, 0.48, paint.g);
	float light_face = 0.83 + 0.22 * max(0.0, face.z) + 0.12 * max(0.0, face.y);
	vec3 walls = stone.rgb * (0.49 + value * 0.96) * light_face;
	walls += vec3(0.035, 0.046, 0.071) * smoothstep(0.0, 0.46, 1.0 - local_point.y);
	float cell = fract(sin(dot(floor(local_point * 12.0), vec3(12.17, 5.62, 11.96))) * 173.77);
	vec3 windows = mix(glass.rgb * 0.46, glass.rgb * 1.09, smoothstep(0.30, 0.63, cell));
	ALBEDO = mix(walls, windows, window_mask * 0.81);
}
