shader_type sky;

uniform sampler2D park_panorama : source_color, filter_linear, repeat_enable;
uniform sampler2D harbor_panorama : source_color, filter_linear, repeat_enable;
uniform float harbor = 0.0;

void sky() {
	vec2 city_uv = vec2(fract(SKY_COORDS.x + 0.13), SKY_COORDS.y);
	vec2 coast_uv = vec2(fract(SKY_COORDS.x + 0.44), SKY_COORDS.y);
	vec3 city = texture(park_panorama, city_uv).rgb;
	vec3 coast = texture(harbor_panorama, coast_uv).rgb;
	COLOR = mix(city, coast, harbor);
}
