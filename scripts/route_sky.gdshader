shader_type sky;

uniform sampler2D park_panorama : source_color, filter_linear, repeat_enable;
uniform sampler2D harbor_panorama : source_color, filter_linear, repeat_enable;
uniform sampler2D forest_panorama : source_color, filter_linear, repeat_enable;
uniform vec3 districts = vec3(1.0, 0.0, 0.0);

void sky() {
	vec2 city_uv = vec2(fract(SKY_COORDS.x + 0.13), SKY_COORDS.y);
	vec2 coast_uv = vec2(fract(SKY_COORDS.x + 0.44), SKY_COORDS.y);
	vec2 forest_uv = vec2(fract(SKY_COORDS.x + 0.31), SKY_COORDS.y);
	vec3 city = texture(park_panorama, city_uv).rgb;
	vec3 coast = texture(harbor_panorama, coast_uv).rgb;
	vec3 forest = texture(forest_panorama, forest_uv).rgb;
	COLOR = city * districts.x + coast * districts.y + forest * districts.z;
}
