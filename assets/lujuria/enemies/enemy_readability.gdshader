shader_type canvas_item;

uniform vec4 edge_color : source_color = vec4(0.45, 0.19, 0.45, 0.65);
uniform vec4 body_tint : source_color = vec4(1.0);

void fragment() {
	vec4 body = COLOR * body_tint;
	vec2 step_uv = TEXTURE_PIXEL_SIZE * 3.0;
	float neighbor = 0.0;
	neighbor = max(neighbor, texture(TEXTURE, UV + vec2(step_uv.x, 0.0)).a);
	neighbor = max(neighbor, texture(TEXTURE, UV - vec2(step_uv.x, 0.0)).a);
	neighbor = max(neighbor, texture(TEXTURE, UV + vec2(0.0, step_uv.y)).a);
	neighbor = max(neighbor, texture(TEXTURE, UV - vec2(0.0, step_uv.y)).a);
	float edge = max(0.0, neighbor - body.a) * edge_color.a;
	COLOR = vec4(body.rgb * body.a + edge_color.rgb * edge, max(body.a, edge));
	if (COLOR.a > 0.001) {
		COLOR.rgb /= COLOR.a;
	}
}
