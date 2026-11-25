shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, shadows_disabled, depth_draw_never;

void fragment() {
	float width = mix(0.18, 0.48, UV.y);
	float soft_edge = 1.0 - smoothstep(width * 0.12, width, abs(UV.x - 0.5));
	float fade = smoothstep(0.0, 0.19, UV.y) * (1.0 - smoothstep(0.34, 1.0, UV.y));
	ALBEDO = vec3(0.99, 0.88, 0.65);
	ALPHA = soft_edge * fade * 0.19;
}
