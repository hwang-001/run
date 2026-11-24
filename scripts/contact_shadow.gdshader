shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

void fragment() {
	float radius = length((UV - 0.5) * 2.0);
	ALBEDO = vec3(0.10, 0.15, 0.22);
	ALPHA = (1.0 - smoothstep(0.10, 0.96, radius)) * 0.33;
}
