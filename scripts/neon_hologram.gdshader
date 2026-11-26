shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

uniform float scan_speed = 1.0;
varying vec3 local_position;

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	float bands = 0.24 + 0.76 * smoothstep(-0.25, 0.32, sin(local_position.y * 115.0 - 8.0 * TIME * scan_speed));
	float edge = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 2.0);
	ALBEDO = mix(vec3(0.25, 0.73, 0.96), vec3(0.76, 0.89, 1.0), edge);
	ALPHA = 0.17 + bands * 0.30 + edge * 0.24;
}
