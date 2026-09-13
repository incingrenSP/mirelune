shader_type spatial;

render_mode unshaded, cull_disabled, blend_add;

uniform vec4 fire_color : source_color = vec4(1.0, 0.12, 0.01, 1.0);
uniform float emission_strength = 4.0;
uniform float distortion_strength = 0.15;
uniform float distortion_speed = 2.0;

void fragment() {
    vec2 uv = UV;

    float distortion = sin(
        uv.y * 20.0 +
        TIME * distortion_speed
    ) * distortion_strength;

    uv.x += distortion;

    float edge = 1.0 - abs(UV.y - 0.5) * 2.0;

    vec3 color = fire_color.rgb * (0.7 + edge * 0.6);

    ALBEDO = color;
    EMISSION = color * emission_strength;
}