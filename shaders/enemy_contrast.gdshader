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
    if (hero_palette) {
        // Recolor the red fabric smoothly, preserving facial tones and highlights.
        float red_cloth = smoothstep(0.05, 0.18, sample_color.r - sample_color.g)
            * smoothstep(0.025, 0.09, sample_color.r - sample_color.b)
            * (1.0 - smoothstep(0.41, 0.61, sample_color.g));
        vec3 petrol = vec3(0.09, 0.52, 0.48) * (0.35 + gray * 1.10);
        enhanced = mix(enhanced, petrol, red_cloth * 0.80);
    }
    // Outlines live outside the sprite. Keep all visible texels, even soft edges.
    float dark_alpha = inner * dark_edge.a;
    float rim_alpha = outer * light_edge.a;
    vec3 edge_rgb = mix(light_edge.rgb, dark_edge.rgb, inner);
    float edge_alpha = max(dark_alpha, rim_alpha) * (1.0 - sample_color.a);
    float alpha = sample_color.a + edge_alpha;
    vec3 rgb = (enhanced * sample_color.a + edge_rgb * edge_alpha) / max(alpha, 0.0001);
    COLOR = vec4(rgb, alpha) * tint;
}
