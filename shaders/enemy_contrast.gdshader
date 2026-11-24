shader_type canvas_item;
render_mode unshaded;
uniform float outline_width = 1.5;
uniform vec4 dark_edge : source_color = vec4(0.07, 0.025, 0.035, 0.96);
uniform vec4 light_edge : source_color = vec4(1.0, 0.74, 0.43, 0.72);
uniform bool hero_palette = false;
varying vec4 tint;
void vertex() {
    tint = COLOR;
}
void fragment() {
    vec4 sample_color = texture(TEXTURE, UV);
    vec2 pixel = TEXTURE_PIXEL_SIZE * outline_width;
    float inner = 0.0;
    float outer = 0.0;
    for (int i = 0; i < 8; i++) {
        float angle = float(i) * 0.78539816;
        vec2 axis = vec2(cos(angle), sin(angle));
        inner = max(inner, texture(TEXTURE, UV + axis * pixel).a);
        outer = max(outer, texture(TEXTURE, UV + axis * pixel * 1.8).a);
    }
    float gray = dot(sample_color.rgb, vec3(0.299,0.587,0.114));
    vec3 enhanced = mix(vec3(gray), sample_color.rgb, 1.24);
    enhanced = clamp((enhanced - 0.5) * 1.12 + 0.55, 0.0, 1.0);
    if (hero_palette && sample_color.r > sample_color.g * 1.23 && sample_color.g < 0.61) {
        enhanced = mix(enhanced, vec3(0.035, 0.52, 0.48) * (0.52 + 0.9 * gray), 0.86);
    }
    vec4 silhouette = light_edge * vec4(1.0,1.0,1.0,outer);
    silhouette = mix(silhouette, dark_edge, smoothstep(0.1,0.7,inner));
    COLOR = mix(silhouette, vec4(enhanced,sample_color.a), smoothstep(0.01,0.45,sample_color.a)) * tint;
}
