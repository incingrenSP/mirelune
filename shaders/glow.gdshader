shader_type spatial;

render_mode unshaded, cull_disabled, blend_add, depth_draw_never;

uniform vec4 glow_color : source_color = vec4(1.0, 0.1, 0.01, 1.0);
uniform float intensity = 2.0;

void fragment() {
    float edge = 1.0 - length(UV - vec2(0.5)) * 2.0;

    edge = clamp(edge, 0.0, 1.0);

    ALBEDO = glow_color.rgb;
    EMISSION = glow_color.rgb * intensity;
    ALPHA = edge * 0.5;
}