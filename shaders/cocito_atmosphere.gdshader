shader_type canvas_item;

// Las sombras se desplazan sobre la ilustración sin mover el suelo transitable.
void fragment() {
    vec2 p = UV;
    float band = sin(p.x * 15.0 + p.y * 8.0 + sin(p.y * 13.0 - TIME * 0.12) * 1.8 + TIME * 0.31);
    float mist = smoothstep(0.2, 0.97, band) * 0.18;
    float halo = exp(-distance(p, vec2(0.5, 0.33)) * 6.7);
    float pulse = 0.80 + sin(TIME * 1.28) * 0.13;
    float shadow = smoothstep(0.12, 0.70, abs(p.x - 0.5) + abs(p.y - 0.48) * 0.56);
    vec3 ice = vec3(0.65, 0.81, 0.83) * (0.67 + halo * pulse * 0.6);
    COLOR = vec4(mix(ice, vec3(0.08, 0.13, 0.17), shadow * 0.67), mist + shadow * 0.16 + halo * 0.08);
}
